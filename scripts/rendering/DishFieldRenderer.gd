extends Node2D
class_name DishFieldRenderer

const DishFieldType = preload("res://scripts/field/DishField.gd")
const GRID_SHADER = preload("res://shaders/DishFieldGrid.gdshader")

const DRAW_MARGIN: float = 48.0
const MAX_COIL_TORSIONS: int = 16

@export_range(0.75, 2.50, 0.05) var visual_intensity: float = 1.35

var field: DishFieldType
var dish_radius: float = 1140.0
var mesh_spacing: float = 28.0

var _shader_material: ShaderMaterial
var _coil_torsion_count: int = 0
var _coil_torsion_a: PackedVector4Array = PackedVector4Array()
var _coil_torsion_b: PackedVector4Array = PackedVector4Array()
var _coil_torsion_c: PackedVector4Array = PackedVector4Array()


func _ready() -> void:
	_ensure_torsion_buffers()
	_ensure_material()
	_update_shader_uniforms()


func configure(new_field: DishFieldType, new_dish_radius: float, new_mesh_spacing: float) -> void:
	field = new_field
	dish_radius = new_dish_radius
	mesh_spacing = maxf(new_mesh_spacing, 6.0)
	_ensure_material()
	_update_shader_uniforms()


func refresh_field_state() -> void:
	if field == null:
		return

	_ensure_material()
	_update_shader_uniforms()


func set_coil_torsions(
	count: int,
	data_a: PackedVector4Array,
	data_b: PackedVector4Array,
	data_c: PackedVector4Array
) -> void:
	_ensure_torsion_buffers()
	_coil_torsion_count = clampi(count, 0, MAX_COIL_TORSIONS)
	_coil_torsion_a = data_a
	_coil_torsion_b = data_b
	_coil_torsion_c = data_c


func _draw() -> void:
	_ensure_material()

	var draw_radius: float = dish_radius + DRAW_MARGIN
	draw_rect(
		Rect2(
			Vector2(-draw_radius, -draw_radius),
			Vector2.ONE * draw_radius * 2.0
		),
		Color.WHITE
	)


func _ensure_material() -> void:
	if _shader_material != null:
		return

	_shader_material = ShaderMaterial.new()
	_shader_material.shader = GRID_SHADER
	material = _shader_material


func _ensure_torsion_buffers() -> void:
	if _coil_torsion_a.size() == MAX_COIL_TORSIONS:
		return

	_coil_torsion_a.resize(MAX_COIL_TORSIONS)
	_coil_torsion_b.resize(MAX_COIL_TORSIONS)
	_coil_torsion_c.resize(MAX_COIL_TORSIONS)

	for torsion_index in MAX_COIL_TORSIONS:
		_coil_torsion_a[torsion_index] = Vector4.ZERO
		_coil_torsion_b[torsion_index] = Vector4.ZERO
		_coil_torsion_c[torsion_index] = Vector4.ZERO


func _update_shader_uniforms() -> void:
	if _shader_material == null:
		return

	_ensure_torsion_buffers()

	var camera: Camera2D = get_viewport().get_camera_2d()
	var camera_zoom: float = 1.0
	var camera_position: Vector2 = Vector2.ZERO
	if camera != null:
		camera_zoom = maxf(camera.zoom.x, camera.zoom.y)
		camera_position = camera.global_position

	var transform: Transform2D = global_transform

	var well_position: Vector2 = Vector2.ZERO
	var well_radius: float = 0.001
	var well_strength: float = 0.0
	var well_charge_bias: float = 0.0

	if field != null and not field.contributors.is_empty():
		var contributor: Variant = field.contributors[0]
		if contributor != null:
			well_position = contributor.position
			well_radius = maxf(contributor.radius, 0.001)
			well_strength = contributor.strength
			well_charge_bias = contributor.charge_bias

	_shader_material.set_shader_parameter("field_time", field.time if field != null else 0.0)
	_shader_material.set_shader_parameter("dish_radius", dish_radius)
	_shader_material.set_shader_parameter("mesh_spacing", mesh_spacing)
	_shader_material.set_shader_parameter("camera_zoom", camera_zoom)
	_shader_material.set_shader_parameter("camera_position", camera_position)
	_shader_material.set_shader_parameter("visual_intensity", visual_intensity)
	_shader_material.set_shader_parameter("world_origin", transform.origin)
	_shader_material.set_shader_parameter("world_x_axis", transform.x)
	_shader_material.set_shader_parameter("world_y_axis", transform.y)
	_shader_material.set_shader_parameter("well_position", well_position)
	_shader_material.set_shader_parameter("well_radius", well_radius)
	_shader_material.set_shader_parameter("well_strength", well_strength)
	_shader_material.set_shader_parameter("well_charge_bias", well_charge_bias)
	_shader_material.set_shader_parameter("base_pulse_speed", field.base_pulse_speed if field != null else 0.35)
	_shader_material.set_shader_parameter("base_pulse_strength", field.base_pulse_strength if field != null else 3.2)
	_shader_material.set_shader_parameter("breath_frequency_a", field.breath_frequency_a if field != null else Vector2(0.010, 0.013))
	_shader_material.set_shader_parameter("breath_frequency_b", field.breath_frequency_b if field != null else Vector2(-0.007, 0.009))
	_shader_material.set_shader_parameter("hum_frequency_a", field.hum_frequency_a if field != null else Vector2(0.039, -0.035))
	_shader_material.set_shader_parameter("hum_frequency_b", field.hum_frequency_b if field != null else Vector2(-0.054, 0.046))
	_shader_material.set_shader_parameter("hum_envelope_frequency", field.hum_envelope_frequency if field != null else Vector2(0.006, -0.005))
	_shader_material.set_shader_parameter("breath_wave_weights", field.breath_wave_weights if field != null else Vector2(0.6, 0.4))
	_shader_material.set_shader_parameter("hum_wave_weights", field.hum_wave_weights if field != null else Vector2(0.55, 0.45))
	_shader_material.set_shader_parameter("hum_envelope_shape", field.hum_envelope_shape if field != null else Vector2(0.66, 0.34))
	_shader_material.set_shader_parameter("hum_height_scale", field.hum_height_scale if field != null else 0.24)
	_shader_material.set_shader_parameter("hum_charge_scale", field.hum_charge_scale if field != null else 0.045)
	_shader_material.set_shader_parameter("hum_turbulence_scale", field.hum_turbulence_scale if field != null else 0.04)
	_shader_material.set_shader_parameter("breath_gradient_scale", field.breath_gradient_scale if field != null else 4.2)
	_shader_material.set_shader_parameter("flow_strength_scale", field.flow_strength_scale if field != null else 0.085)
	_shader_material.set_shader_parameter("flow_hum_scale", field.flow_hum_scale if field != null else 0.62)
	_shader_material.set_shader_parameter("flow_vorticity_scale", field.flow_vorticity_scale if field != null else 0.42)
	_shader_material.set_shader_parameter("wall_wave_reach_ratio", field.wall_wave_reach_ratio if field != null else 0.34)
	_shader_material.set_shader_parameter("wall_wave_frequency", field.wall_wave_frequency if field != null else 0.036)
	_shader_material.set_shader_parameter("wall_wave_speed", field.wall_wave_speed if field != null else 1.26)
	_shader_material.set_shader_parameter("wall_wave_sharpness", field.wall_wave_sharpness if field != null else 2.7)
	_shader_material.set_shader_parameter("wall_wave_height_strength", field.wall_wave_height_strength if field != null else 1.05)
	_shader_material.set_shader_parameter("wall_wave_push_strength", field.wall_wave_push_strength if field != null else 0.64)
	_shader_material.set_shader_parameter("wall_wave_swirl_strength", field.wall_wave_swirl_strength if field != null else 0.12)
	_shader_material.set_shader_parameter("wall_wave_swirl_speed", field.wall_wave_swirl_speed if field != null else 0.34)
	_shader_material.set_shader_parameter("coil_torsion_count", _coil_torsion_count)
	_shader_material.set_shader_parameter("coil_torsion_a", _coil_torsion_a)
	_shader_material.set_shader_parameter("coil_torsion_b", _coil_torsion_b)
	_shader_material.set_shader_parameter("coil_torsion_c", _coil_torsion_c)
