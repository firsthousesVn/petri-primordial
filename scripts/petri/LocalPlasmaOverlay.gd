extends Node2D
class_name LocalPlasmaOverlay

# LEGACY FILE NAME: this overlay renders the shader-driven plasma-sheath
# support layer plus bond-throat bridge support, not the main cell-field arcs.
#
# Lives as a child of PetriDish so its local coordinates ARE dish-local
# coordinates — the shader reads VERTEX as world position directly. Drawn
# above cells via z_index so the additive plasma blends over their bodies as
# a plasma sheath / field glow rather than being occluded by the cell sprites.

const MAX_SOURCES: int = 24
const MAX_BONDS: int = 32

var _shader_material: ShaderMaterial = null
var _rect_extent: float = 1024.0
# Tight rasterization rect set per frame from the source/bond AABB. The
# shader fragment cost scales with this rect's area — covering the whole
# dish (2048x2048) wastes millions of fragment evaluations on empty pixels
# that just discard. set_bounds() is the active path; _rect_extent is a
# fallback used until the first set_bounds() arrives.
var _bounds_rect: Rect2 = Rect2(-1024.0, -1024.0, 2048.0, 2048.0)
var _bounds_active: bool = false

# Cached arrays so we do not allocate every frame. Sized to MAX_SOURCES /
# MAX_BONDS, with unused slots zeroed; the shader only reads the first
# source_count / bond_count entries.
var _sources_buf: Array = []
var _phase_buf: PackedFloat32Array = PackedFloat32Array()
var _field_buf: Array = []
var _style_buf: Array = []
var _bond_segments_buf: Array = []
var _bond_params_buf: Array = []


func _ready() -> void:
	z_as_relative = false
	# Cells default to z_index 0; the legacy/debug field overlay sits at 100.
	# Slot below that debug layer so inspection visuals still read on top, but
	# above cells so the additive plasma adds light over their bodies.
	z_index = 50
	_sources_buf.resize(MAX_SOURCES)
	for i in MAX_SOURCES:
		_sources_buf[i] = Vector4.ZERO
	_phase_buf.resize(MAX_SOURCES)
	_field_buf.resize(MAX_SOURCES)
	for i in MAX_SOURCES:
		_field_buf[i] = Vector4.ZERO
	_style_buf.resize(MAX_SOURCES)
	for i in MAX_SOURCES:
		_style_buf[i] = Vector4.ZERO
	_bond_segments_buf.resize(MAX_BONDS)
	_bond_params_buf.resize(MAX_BONDS)
	for j in MAX_BONDS:
		_bond_segments_buf[j] = Vector4.ZERO
		_bond_params_buf[j] = Vector4.ZERO


func set_shader_material(mat: ShaderMaterial) -> void:
	_shader_material = mat
	material = mat


func set_extent(e: float) -> void:
	_rect_extent = maxf(e, 64.0)
	queue_redraw()


# Tight per-frame bounds in dish-local coordinates. The shader runs at
# every pixel inside this rect, so PetriDish should pass the AABB of all
# plasma sources expanded by their effective reach (+ bond endpoints).
# Pass an empty rect (size == Vector2.ZERO) to suppress drawing entirely
# when there are no sources.
func set_bounds(rect: Rect2) -> void:
	_bounds_rect = rect
	_bounds_active = rect.size.x > 0.0 and rect.size.y > 0.0
	queue_redraw()


# Push current source data + monotonic time to the shader uniforms. Source
# data is provided as parallel arrays so callers can build it in-place.
#   positions[i]  : Vector2 world position of source
#   radii[i]      : float
#   intensities[i]: float (0..1)
#   phases[i]     : float per-source seed in [0, TAU); MUST be persistent
#   fields[i]     : Vector4(bias_dir.x, bias_dir.y, attraction, shared)
#   styles[i]     : Vector4(body_axis.x, body_axis.y, style_mode, arc_mult)
func push_sources(
	positions: Array,
	radii: Array,
	intensities: Array,
	phases: Array,
	fields: Array,
	styles: Array,
	count: int,
	plasma_time_value: float,
) -> void:
	if _shader_material == null:
		return
	var n: int = mini(count, MAX_SOURCES)
	for i in n:
		var pos: Vector2 = positions[i]
		var r: float = float(radii[i])
		var inten: float = float(intensities[i])
		_sources_buf[i] = Vector4(pos.x, pos.y, r, inten)
		_phase_buf[i] = float(phases[i])
		_field_buf[i] = fields[i]
		_style_buf[i] = styles[i]
	# Zero out the tail so stale data from the previous frame cannot bleed
	# in if the cell count drops.
	for j in range(n, MAX_SOURCES):
		_sources_buf[j] = Vector4.ZERO
		_phase_buf[j] = 0.0
		_field_buf[j] = Vector4.ZERO
		_style_buf[j] = Vector4.ZERO
	_shader_material.set_shader_parameter("sources", _sources_buf)
	_shader_material.set_shader_parameter("source_phase", _phase_buf)
	_shader_material.set_shader_parameter("source_field", _field_buf)
	_shader_material.set_shader_parameter("source_style", _style_buf)
	_shader_material.set_shader_parameter("source_count", n)
	_shader_material.set_shader_parameter("plasma_time", plasma_time_value)
	queue_redraw()


# Push the per-bond capsule data that the shader uses to merge bonded
# spheres into a single shared field.
#   segments[i] : Vector4 (A.x, A.y, B.x, B.y) world-space endpoints
#   params[i]   : Vector4 (capsule_radius, merge_factor, strain, phase)
func push_bonds(segments: Array, params: Array, count: int) -> void:
	if _shader_material == null:
		return
	var n: int = mini(count, MAX_BONDS)
	for i in n:
		_bond_segments_buf[i] = segments[i]
		_bond_params_buf[i] = params[i]
	for j in range(n, MAX_BONDS):
		_bond_segments_buf[j] = Vector4.ZERO
		_bond_params_buf[j] = Vector4.ZERO
	_shader_material.set_shader_parameter("bond_segments", _bond_segments_buf)
	_shader_material.set_shader_parameter("bond_params", _bond_params_buf)
	_shader_material.set_shader_parameter("bond_count", n)


func _draw() -> void:
	if _shader_material == null:
		return
	if _bounds_active:
		# Draw only the tight AABB. Empty space outside the AABB skips the
		# fragment program entirely.
		draw_rect(_bounds_rect, Color(1.0, 1.0, 1.0, 1.0))
		return
	# Fallback: full-extent rect (used only before PetriDish has pushed
	# bounds, e.g. on the very first frame).
	var e: float = _rect_extent
	draw_rect(Rect2(-e, -e, e * 2.0, e * 2.0), Color(1.0, 1.0, 1.0, 1.0))
