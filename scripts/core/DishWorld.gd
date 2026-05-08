extends Node2D
class_name DishWorld

const DishFieldType = preload("res://scripts/field/DishField.gd")
const DishFieldRendererType = preload("res://scripts/rendering/DishFieldRenderer.gd")
const FieldWellType = preload("res://scripts/field/FieldWell.gd")
const CoilCellType = preload("res://scripts/cells/CoilCell.gd")
const MAX_SHADER_TORSIONS: int = 16

enum PlacementTool {
	NONE,
	COIL
}

@export_range(120.0, 4096.0, 1.0, "or_greater") var dish_radius: float = 1140.0
@export_range(0.01, 4.0, 0.01, "or_greater") var base_pulse_speed: float = 0.35
@export_range(0.0, 24.0, 0.1, "or_greater") var base_pulse_strength: float = 3.2
@export_range(8.0, 96.0, 1.0, "or_greater") var mesh_spacing: float = 28.0

var breath_frequency_a: Vector2 = Vector2(0.010, 0.013)
var breath_frequency_b: Vector2 = Vector2(-0.007, 0.009)
var hum_frequency_a: Vector2 = Vector2(0.039, -0.035)
var hum_frequency_b: Vector2 = Vector2(-0.054, 0.046)
var hum_envelope_frequency: Vector2 = Vector2(0.006, -0.005)
var breath_wave_weights: Vector2 = Vector2(0.6, 0.4)
var hum_wave_weights: Vector2 = Vector2(0.55, 0.45)
var hum_envelope_shape: Vector2 = Vector2(0.66, 0.34)
var hum_height_scale: float = 0.24
var hum_charge_scale: float = 0.045
var hum_turbulence_scale: float = 0.04
var breath_gradient_scale: float = 4.2
var flow_strength_scale: float = 0.16
var flow_hum_scale: float = 0.62
var flow_vorticity_scale: float = 0.42
var wall_wave_reach_ratio: float = 0.62
var wall_wave_frequency: float = 0.036
var wall_wave_speed: float = 1.26
var wall_wave_sharpness: float = 1.6
var wall_wave_height_strength: float = 1.05
var wall_wave_push_strength: float = 0.96
var wall_wave_swirl_strength: float = 0.12
var wall_wave_swirl_speed: float = 0.34

@onready var field_renderer: DishFieldRendererType = $DishFieldRenderer
@onready var camera: Camera2D = $Camera2D

var field: DishFieldType
var primordial_well: FieldWellType
var selected_tool: int = PlacementTool.NONE
var spawned_coils: Array[CoilCellType] = []
var _is_panning: bool = false
var _last_dish_radius: float = -1.0
var _last_base_pulse_speed: float = -1.0
var _last_base_pulse_strength: float = -1.0
var _last_mesh_spacing: float = -1.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _coil_torsion_a: PackedVector4Array = PackedVector4Array()
var _coil_torsion_b: PackedVector4Array = PackedVector4Array()
var _coil_torsion_c: PackedVector4Array = PackedVector4Array()


func _ready() -> void:
	_rng.randomize()
	_initialize_torsion_buffers()
	_rebuild_field()
	_sync_runtime_configuration(true)
	_sync_coil_torsion_uniforms()
	field_renderer.refresh_field_state()
	field_renderer.queue_redraw()


func _process(delta: float) -> void:
	if field == null:
		return

	_sync_runtime_configuration()
	field.advance(delta)
	_sync_coil_torsion_uniforms()

	field_renderer.refresh_field_state()
	field_renderer.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			selected_tool = PlacementTool.COIL
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(0.9)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(1.1)
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_try_spawn_selected_cell(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = event.pressed
	elif event is InputEventMouseMotion and _is_panning:
		camera.position -= event.relative * camera.zoom.x


func register_field_well(well: FieldWellType) -> void:
	if field == null:
		return

	# Future sphere cells can register their own wells through this same path.
	well.position = field.clamp_to_dish(well.position)
	register_field_contributor(well)


func register_field_contributor(contributor: Object) -> void:
	if field == null:
		return

	field.add_contributor(contributor)


func _try_spawn_selected_cell(world_position: Vector2) -> void:
	if selected_tool != PlacementTool.COIL or field == null:
		return

	if not field.is_inside_dish(world_position):
		return

	_spawn_coil(world_position)


func _spawn_coil(world_position: Vector2) -> void:
	var coil: CoilCellType = CoilCellType.new()
	var spawn_heading: float = _resolve_spawn_heading(world_position)

	coil.position = world_position
	coil.configure(field, spawn_heading)
	add_child(coil)
	spawned_coils.append(coil)
	_sync_coil_torsion_uniforms()


func _resolve_spawn_heading(world_position: Vector2) -> float:
	var sample := field.sample(world_position)
	if sample.flow.length_squared() > 0.0001:
		return sample.flow.angle() + _rng.randf_range(-0.28, 0.28)
	if sample.gradient.length_squared() > 0.0001:
		return sample.gradient.angle() + _rng.randf_range(-0.35, 0.35)

	return _rng.randf_range(0.0, TAU)


func _initialize_torsion_buffers() -> void:
	_coil_torsion_a.resize(MAX_SHADER_TORSIONS)
	_coil_torsion_b.resize(MAX_SHADER_TORSIONS)
	_coil_torsion_c.resize(MAX_SHADER_TORSIONS)

	for torsion_index in MAX_SHADER_TORSIONS:
		_coil_torsion_a[torsion_index] = Vector4.ZERO
		_coil_torsion_b[torsion_index] = Vector4.ZERO
		_coil_torsion_c[torsion_index] = Vector4.ZERO


func _sync_coil_torsion_uniforms() -> void:
	var write_index: int = 0
	var active_coils: Array[CoilCellType] = []

	for coil in spawned_coils:
		if not is_instance_valid(coil):
			continue

		active_coils.append(coil)
		if write_index >= MAX_SHADER_TORSIONS:
			continue

		coil.write_shader_torsion_uniforms(_coil_torsion_a, _coil_torsion_b, _coil_torsion_c, write_index)
		write_index += 1

	spawned_coils = active_coils

	for clear_index in range(write_index, MAX_SHADER_TORSIONS):
		_coil_torsion_a[clear_index] = Vector4.ZERO
		_coil_torsion_b[clear_index] = Vector4.ZERO
		_coil_torsion_c[clear_index] = Vector4.ZERO

	field_renderer.set_coil_torsions(write_index, _coil_torsion_a, _coil_torsion_b, _coil_torsion_c)


func _rebuild_field() -> void:
	field = DishFieldType.new(dish_radius, base_pulse_speed, base_pulse_strength)

	primordial_well = FieldWellType.new(
		Vector2(62.0, -38.0),
		dish_radius * 0.28,
		44.0,
		0.12
	)
	register_field_well(primordial_well)

	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE


func _sync_runtime_configuration(force: bool = false) -> void:
	var geometry_dirty: bool = false

	if force or not is_equal_approx(_last_dish_radius, dish_radius):
		field.dish_radius = dish_radius
		_last_dish_radius = dish_radius
		geometry_dirty = true

		if primordial_well != null:
			primordial_well.position = field.clamp_to_dish(primordial_well.position)
			primordial_well.radius = dish_radius * 0.28

	if force or not is_equal_approx(_last_base_pulse_speed, base_pulse_speed):
		field.base_pulse_speed = base_pulse_speed
		_last_base_pulse_speed = base_pulse_speed

	if force or not is_equal_approx(_last_base_pulse_strength, base_pulse_strength):
		field.base_pulse_strength = base_pulse_strength
		_last_base_pulse_strength = base_pulse_strength

	field.breath_frequency_a = breath_frequency_a
	field.breath_frequency_b = breath_frequency_b
	field.hum_frequency_a = hum_frequency_a
	field.hum_frequency_b = hum_frequency_b
	field.hum_envelope_frequency = hum_envelope_frequency
	field.breath_wave_weights = breath_wave_weights
	field.hum_wave_weights = hum_wave_weights
	field.hum_envelope_shape = hum_envelope_shape
	field.hum_height_scale = hum_height_scale
	field.hum_charge_scale = hum_charge_scale
	field.hum_turbulence_scale = hum_turbulence_scale
	field.breath_gradient_scale = breath_gradient_scale
	field.flow_strength_scale = flow_strength_scale
	field.flow_hum_scale = flow_hum_scale
	field.flow_vorticity_scale = flow_vorticity_scale
	field.wall_wave_reach_ratio = wall_wave_reach_ratio
	field.wall_wave_frequency = wall_wave_frequency
	field.wall_wave_speed = wall_wave_speed
	field.wall_wave_sharpness = wall_wave_sharpness
	field.wall_wave_height_strength = wall_wave_height_strength
	field.wall_wave_push_strength = wall_wave_push_strength
	field.wall_wave_swirl_strength = wall_wave_swirl_strength
	field.wall_wave_swirl_speed = wall_wave_swirl_speed

	if force or not is_equal_approx(_last_mesh_spacing, mesh_spacing):
		_last_mesh_spacing = mesh_spacing
		geometry_dirty = true

	if force or geometry_dirty:
		field_renderer.configure(field, dish_radius, mesh_spacing)


func _apply_zoom(multiplier: float) -> void:
	var next_zoom := clampf(camera.zoom.x * multiplier, 0.55, 2.8)
	camera.zoom = Vector2.ONE * next_zoom
