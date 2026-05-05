extends RefCounted
class_name PolarityArcRenderer

# Analytic magnetic-dipole loop renderer.
#
# Each cell is rendered as a small set of compact polarity lobes built directly
# from the analytic dipole loop r(theta) = L * sin(theta)^2. No streamline
# tracing, no iso-contour bisection, no metaballs, no wrappers, no scalar
# contour extraction. The dipole topology IS the starting state: an isolated
# cell renders the canonical lobes from frame zero.
#
# For each cell x shell x side in {+1, -1}:
#   axis  = cell.polarity_axis()
#   perp  = axis.orthogonal()
#   for theta in [theta_min, PI - theta_min]:
#       r     = L * sin(theta)^2
#       local = axis * (r * cos(theta)) + perp * side * (r * sin(theta))
#       point = cell.position + local + _deform_dipole_point(...)
#
# Two passes per loop: a wider soft glow polyline and a thin bright core. No
# ambient field tracing here; the wavy grid blanket is the only ambient visual
# and lives in AmbientFieldRenderer.

# --- Tuning dials (the public set requested by the visual contract) ---
# Pass 2 (isolated-sphere fix): the lobes are now BROAD plasma bands, not
# thin classroom-diagram loops. Three stacked polyline passes per lobe:
#   1. HAZE   — wide, very soft outer plasma cloud (presence in the medium)
#   2. GLOW   — mid plasma body
#   3. CORE   — bright filament that gives the lobe its readable axis
# Compactness was bumped so the field reads as larger than the cell. Theta_min
# was reduced so each lobe opens wider and feels like a crescent plasma band
# rather than a closed loop.
const DIPOLE_THETA_MIN: float = 0.22               # rad. Smaller pinch → broader, more open crescent lobes.
const DIPOLE_POINT_COUNT: int = 64                 # smoother broad lobe bulge.
const DIPOLE_VISIBLE_LOBES: int = 1                # ONE shell only — kills the concentric oval stack.
const DIPOLE_COMPACTNESS: float = 3.40             # L = COMPACTNESS * cell.radius; field reads larger than the body.
const DIPOLE_HAZE_WIDTH: float = 36.0              # wide soft plasma cloud — gives presence in the medium.
const DIPOLE_HAZE_ALPHA: float = 0.18              # very soft; the haze must not overwrite the grid.
const DIPOLE_GLOW_WIDTH: float = 18.0              # mid plasma body.
const DIPOLE_GLOW_ALPHA: float = 0.46              # readable but still translucent.
const DIPOLE_CORE_WIDTH: float = 3.6               # bright filament inside the haze.
const DIPOLE_ALPHA: float = 0.95                   # base alpha for the bright core pass.
const DIPOLE_BREATH_GAIN: float = 0.10             # subtle alpha breath; shape stays compact.
const DIPOLE_DEFORM_GAIN: float = 0.95             # bending kicks in only when overlap > 0; isolated cells stay clean.
const DIPOLE_NEAR_SIDE_BIAS: float = 1.85          # extra bend multiplier on the lobe vertices facing the neighbor.
const DIPOLE_NEAR_SIDE_GLOW_BOOST: float = 0.55    # alpha boost (additive) on near-side vertices when overlap is active.
const DIPOLE_NEAR_SIDE_CORE_BOOST: float = 0.35    # core alpha boost on near-side vertices.
# Bonded coupling: when bond_pressure on this cell is high, the lobe whose
# tip points at the partner (the "inward" lobe) fades in independence so the
# pair reads as a coupled field unit. The outward lobe stays sharp. The
# brightening of the shared zone comes for free from `near-side energy boost`
# already added on the inward-facing vertices of the outward lobe + the
# inward-facing vertices of the inward lobe (those that survive the fade).
const DIPOLE_COUPLING_PRESSURE_SCALE: float = 0.45 # how quickly bond_pressure → coupling fade ramps in
const DIPOLE_COUPLING_INWARD_FADE: float = 0.42    # final alpha multiplier on the fully-coupled inward lobe (1.0 = no fade)
const DIPOLE_COUPLING_SHARED_BOOST: float = 0.45   # extra glow boost on the inward lobe's near-side vertices when coupled

# --- Internal supporting dials ---
const DIPOLE_LOOP_INNER_FRAC: float = 0.55             # innermost L = COMPACTNESS * R * INNER_FRAC (used if DIPOLE_VISIBLE_LOBES > 1).
const DIPOLE_LOOP_GLOW_ALPHA: float = 0.46             # legacy alias retained for any out-of-renderer reads.
const DIPOLE_LOOP_BREATH_SPEED: float = 1.10
const DIPOLE_LOOP_COMPRESSION_BOOST: float = 0.45
const DIPOLE_LOOP_OVERLAP_BOOST: float = 0.65
const DIPOLE_LOOP_BOND_PRESSURE_BOOST: float = 0.55
const DIPOLE_LOOP_SHELL_ALPHA_FALLOFF: float = 0.78
const DIPOLE_LOOP_TINT_BLEND: float = 0.30

const PLASMA_BLUE: Color = Color(0.38, 0.76, 1.00, 1.0)

# Untyped to dodge class_name load-order issues.
var dish
var ambient
var primitive_count: int = 0


func _init(p_dish, p_ambient) -> void:
	dish = p_dish
	ambient = p_ambient


# Lobe bending toward overlapping neighbors. Driven entirely by cached
# interaction state (`field_neighbor_dir`, `field_overlap_energy`,
# `field_bond_pressure`) populated by PetriDish._compute_field_overlap_pass.
# An ISOLATED cell has zero neighbor_dir and zero overlap energy, so this
# returns Vector2.ZERO and the canonical analytic dipole shape is preserved.
# Once cells overlap, the lobes lean toward the neighbor with magnitude
# proportional to overlap strength, scaled by lobe radius from the cell.
const _DEFORM_REACH_PX: float = 38.0              # peak displacement (px) at full overlap energy
const _DEFORM_PRESSURE_GAIN: float = 22.0         # extra bend from bond pressure
# `facing` ∈ [0, 1] is how strongly this point lies on the side of the cell
# pointing at the neighbor. Returned alongside the displacement so the
# renderer can also brighten the near-side vertex (interaction zone glow).
func _deform_dipole_point_full(
	cell,
	base_point: Vector2,
	_side: float,
	_shell_index: int,
	t: float
) -> Array:
	var nd: Vector2 = cell.field_neighbor_dir
	if nd.length_squared() < 0.000001:
		return [Vector2.ZERO, 0.0]
	var overlap_term: float = clampf(cell.field_overlap_energy * 0.10, 0.0, 1.0)
	var pressure_term: float = clampf(cell.field_bond_pressure * 0.45, 0.0, 1.0)
	if overlap_term + pressure_term <= 0.0001:
		return [Vector2.ZERO, 0.0]
	var bulge: float = sin(t * PI)
	var radial: Vector2 = base_point - cell.position
	var radial_len: float = radial.length()
	var radial_norm: float = clampf(radial_len / maxf(cell.radius * 2.0, 1.0), 0.0, 1.6)
	# Facing factor: dot(unit_radial, nd). 1.0 = lobe tip points right at the
	# neighbor, 0.0 or negative = far side. Smoothstep so the bend ramps in.
	var facing: float = 0.0
	if radial_len > 0.001:
		facing = clampf(radial.dot(nd) / radial_len, 0.0, 1.0)
	var facing_smooth: float = facing * facing * (3.0 - 2.0 * facing)
	# Near-side gets the strong bend; far-side stays close to the analytic shape.
	var bias: float = lerpf(1.0, DIPOLE_NEAR_SIDE_BIAS, facing_smooth)
	var amplitude: float = bulge * radial_norm * bias * (
		overlap_term * _DEFORM_REACH_PX +
		pressure_term * _DEFORM_PRESSURE_GAIN
	)
	return [nd * amplitude, facing_smooth * (overlap_term + pressure_term * 0.6)]


func _shell_extent(cell, shell_index: int, n_shells: int) -> float:
	# Innermost shell hugs the surface; outer shell reaches COMPACTNESS * R.
	var t: float
	if n_shells <= 1:
		t = 1.0
	else:
		t = float(shell_index) / float(n_shells - 1)
	var frac: float = lerpf(DIPOLE_LOOP_INNER_FRAC, 1.0, t)
	return cell.radius * DIPOLE_COMPACTNESS * frac


func _build_lobe(cell, L: float, side: float, shell_index: int) -> Array:
	# Returns [PackedVector2Array points, PackedFloat32Array near_side_energy].
	# The near-side energy is per-vertex so the renderer can brighten the
	# interaction zone where the lobe faces an overlapping neighbor.
	var pts: PackedVector2Array = PackedVector2Array()
	var energy: PackedFloat32Array = PackedFloat32Array()
	if L <= 0.001:
		return [pts, energy]
	var axis: Vector2 = cell.polarity_axis()
	if axis.length_squared() < 0.000001:
		return [pts, energy]
	var perp: Vector2 = axis.orthogonal()
	var theta_min: float = DIPOLE_THETA_MIN
	var theta_max: float = PI - theta_min
	var n: int = maxi(DIPOLE_POINT_COUNT, 6)
	pts.resize(n)
	energy.resize(n)
	for i in n:
		var u: float = float(i) / float(n - 1)
		var theta: float = lerpf(theta_min, theta_max, u)
		var s: float = sin(theta)
		var r: float = L * s * s
		var local: Vector2 = axis * (r * cos(theta)) + perp * (side * r * s)
		var p: Vector2 = cell.position + local
		var ne: float = 0.0
		if DIPOLE_DEFORM_GAIN > 0.0:
			var packed: Array = _deform_dipole_point_full(cell, p, side, shell_index, u)
			p += (packed[0] as Vector2) * DIPOLE_DEFORM_GAIN
			ne = float(packed[1])
		pts[i] = p
		energy[i] = ne
	return [pts, energy]


static func _vertex_alpha_curve(u: float) -> float:
	# Slightly dimmer at the lobe ends (where it pinches), brighter in the bulge.
	return clampf(0.55 + 0.45 * sin(u * PI), 0.4, 1.0)


func _draw_lobe_polyline(
	target: CanvasItem,
	pts: PackedVector2Array,
	near_energy: PackedFloat32Array,
	base_haze: Color,
	base_glow: Color,
	base_core: Color
) -> int:
	var n: int = pts.size()
	if n < 2:
		return 0
	var haze_colors: PackedColorArray = PackedColorArray()
	var glow_colors: PackedColorArray = PackedColorArray()
	var core_colors: PackedColorArray = PackedColorArray()
	haze_colors.resize(n)
	glow_colors.resize(n)
	core_colors.resize(n)
	var has_energy: bool = near_energy.size() == n
	for i in n:
		var u: float = float(i) / float(n - 1)
		var w: float = _vertex_alpha_curve(u)
		var ne: float = near_energy[i] if has_energy else 0.0
		var glow_boost: float = clampf(ne * DIPOLE_NEAR_SIDE_GLOW_BOOST, 0.0, 1.0)
		var core_boost: float = clampf(ne * DIPOLE_NEAR_SIDE_CORE_BOOST, 0.0, 1.0)
		haze_colors[i] = Color(base_haze.r, base_haze.g, base_haze.b, clampf(base_haze.a * w + glow_boost * 0.5, 0.0, 1.0))
		glow_colors[i] = Color(base_glow.r, base_glow.g, base_glow.b, clampf(base_glow.a * w + glow_boost, 0.0, 1.0))
		core_colors[i] = Color(base_core.r, base_core.g, base_core.b, clampf(base_core.a * w + core_boost, 0.0, 1.0))
	# Outer-to-inner: wide soft plasma cloud, then mid body, then bright core.
	target.draw_polyline_colors(pts, haze_colors, DIPOLE_HAZE_WIDTH, true)
	target.draw_polyline_colors(pts, glow_colors, DIPOLE_GLOW_WIDTH, true)
	target.draw_polyline_colors(pts, core_colors, DIPOLE_CORE_WIDTH, true)
	return 3


func draw_on(
	target: CanvasItem,
	sim_time: float,
	_dish_radius: float,
	cells_arr: Array,
	visible: bool
) -> void:
	primitive_count = 0
	if not visible:
		return
	var breath_phase: float = sim_time * DIPOLE_LOOP_BREATH_SPEED
	var n_shells: int = clampi(DIPOLE_VISIBLE_LOBES, 1, 6)
	for source in cells_arr:
		if source == null or source.signature == null or not source.field_enabled:
			continue
		if source.polarity_axis().length_squared() < 0.0001:
			continue
		var breath: float = 1.0 + sin(breath_phase + source.field_seed) * DIPOLE_BREATH_GAIN
		var overlap_term: float = clampf(source.field_overlap_energy * 0.06, 0.0, 1.0) * DIPOLE_LOOP_OVERLAP_BOOST
		var pressure_term: float = clampf(source.field_bond_pressure * 0.35, 0.0, 1.0) * DIPOLE_LOOP_BOND_PRESSURE_BOOST
		var compression_alpha: float = 1.0 + clampf(source.field_compression, 0.0, 1.0) * DIPOLE_LOOP_COMPRESSION_BOOST
		var alpha_mul: float = breath * compression_alpha * (1.0 + overlap_term + pressure_term)
		var tint: Color = source.glow_color().lerp(PLASMA_BLUE, DIPOLE_LOOP_TINT_BLEND)
		# Coupling fade: bond_pressure → 0..1 ramp. Fades the lobe whose tip
		# points at the partner (the "inward" lobe). Outward lobe stays bright.
		var coupling_t: float = clampf(source.field_bond_pressure * DIPOLE_COUPLING_PRESSURE_SCALE, 0.0, 1.0)
		var axis_n: Vector2 = source.polarity_axis()
		var perp_n: Vector2 = axis_n.orthogonal()
		var nd: Vector2 = source.field_neighbor_dir
		for shell_idx in n_shells:
			var L: float = _shell_extent(source, shell_idx, n_shells)
			var shell_alpha: float = pow(DIPOLE_LOOP_SHELL_ALPHA_FALLOFF, float(shell_idx))
			for side_v in [1.0, -1.0]:
				var lobe: Array = _build_lobe(source, L, float(side_v), shell_idx)
				var pts: PackedVector2Array = lobe[0]
				var near_energy: PackedFloat32Array = lobe[1]
				if pts.size() < 3:
					continue
				var amul: float = alpha_mul * shell_alpha
				# Inward-factor: how strongly this lobe's tip (perp * side_v) points
				# at the neighbor. ∈ [0, 1]. Zero when no neighbor.
				var inward_factor: float = 0.0
				if nd.length_squared() > 0.000001 and coupling_t > 0.0:
					inward_factor = clampf((perp_n * float(side_v)).dot(nd), 0.0, 1.0)
				var lobe_fade: float = lerpf(1.0, DIPOLE_COUPLING_INWARD_FADE, coupling_t * inward_factor)
				var amul_lobe: float = amul * lobe_fade
				# Boost the brightness of inward-lobe near-side vertices so the
				# shared zone *thickens* even as the lobe alpha fades — energy
				# array is per-vertex, so we additively bump it for this lobe only.
				if inward_factor > 0.0 and coupling_t > 0.0:
					var n_e: int = near_energy.size()
					var bump: float = inward_factor * coupling_t * DIPOLE_COUPLING_SHARED_BOOST
					if bump > 0.0001 and n_e > 0:
						for ei in n_e:
							near_energy[ei] = clampf(near_energy[ei] + bump, 0.0, 1.5)
				var haze: Color = Color(tint.r, tint.g, tint.b, DIPOLE_HAZE_ALPHA * amul_lobe)
				var glow: Color = Color(tint.r, tint.g, tint.b, DIPOLE_GLOW_ALPHA * amul_lobe)
				var core: Color = Color(
					minf(1.0, tint.r * 0.92 + 0.08),
					minf(1.0, tint.g * 0.96 + 0.04),
					1.0,
					DIPOLE_ALPHA * amul_lobe
				)
				primitive_count += _draw_lobe_polyline(target, pts, near_energy, haze, glow, core)
