extends RefCounted
class_name AmbientFieldRenderer

# Renders the ambient field as a wavy grid blanket — a stylized "space-time
# grid" warped by the ambient flow and by shallow gravity-like wells around
# each cell. There are no streamlines anywhere in this renderer; the grid IS
# the reveal.
#
# The grid is two stacks of polylines:
#   - constant-Y lines (horizontal scans across the dish, stepping in X)
#   - constant-X lines (vertical scans, stepping in Y)
# Each grid vertex is displaced by:
#   ambient_displacement  = ambient_dir * ambient_strength_norm * GAIN
#   well_displacement     = sum_per_cell( -gauss(d, sigma) * radial )
# So cells punch shallow inward dimples in the grid and the ambient flow drags
# everything sideways in slow waves. Visible only when ambient reveal is on.

# --- Master tuning dials (visuals only) ---
# Pass: grid is the MEDIUM, not the creature. It must read but stay secondary
# to the cell polarity lobes. Alphas, line widths, well depth, and dipole
# coupling were all reduced from the previous pass so the cell fields read
# as the dominant visual.
const GRID_SPACING: float = 28.0          # px between grid lines along both axes — slightly sparser to reduce density
const GRID_LINE_STEPS: int = 30            # samples per line; lower = faster, blockier
const GRID_AMBIENT_DISPLACEMENT: float = 22.0  # px at ambient_strength_norm=1; reduced so waves do not overpower
const GRID_WELL_DEPTH: float = 0.85        # shallower dimple — wells visible but not dominant
const GRID_WELL_SIGMA_MULT: float = 4.2    # broader gaussian — wells reach further
const GRID_GLOW_WIDTH: float = 2.4
const GRID_CORE_WIDTH: float = 0.9
const GRID_GLOW_ALPHA: float = 0.18
const GRID_CORE_ALPHA: float = 0.40
const GRID_HOT_TINT: Color = Color(0.45, 0.78, 1.00, 1.0)   # cool plasma core
const GRID_GLOW_TINT: Color = Color(0.18, 0.52, 0.95, 1.0)  # cool plasma halo
const GRID_PULSE_SPEED: float = 0.40
const GRID_PULSE_GAIN: float = 0.12
const GRID_CULL_MARGIN_PX: float = 64.0
const GRID_DARKEN_AT_DISH_EDGE: float = 0.55  # alpha multiplier at rim
# Dipole-field flow constants. The grid samples the SAME 2D dipole field that
# `PolarityArcRenderer` traces, so saddles between two cells (and bridges
# between bonded cells) emerge in the grid for the same physical reason they
# emerge in the arcs.
const GRID_DIPOLE_GAIN: float = 0.09           # px of displacement per unit |B| (saturated) — reduced so saddles are subtle
const GRID_DIPOLE_MAX_DISP: float = 14.0       # cap on dipole-flow displacement (px); pair saddles read but stay subordinate
const GRID_DIPOLE_EPSILON: float = 4.0         # softening on 1/r² near the cell center
const GRID_DIPOLE_REACH_MULT: float = 5.0      # only sum dipoles within radius × this

var dish                         # PetriDish (untyped to dodge load-order)
var ambient                      # AmbientField (untyped to dodge load-order)
var primitive_count: int = 0


func _init(p_dish, p_ambient) -> void:
	dish = p_dish
	ambient = p_ambient


# 2D magnetic dipole field at offset r from a dipole with moment vector m.
# Mirrors `PolarityArcRenderer._dipole_contribution` so the grid distortion
# tracks exactly the same field topology the arc renderer traces.
static func _dipole_contribution(r: Vector2, m: Vector2, eps2: float) -> Vector2:
	var r2: float = r.length_squared() + eps2
	if r2 < 0.0001:
		return Vector2.ZERO
	var rl: float = sqrt(r2)
	var rhat: Vector2 = r / rl
	var dot_mr: float = m.dot(rhat)
	return (rhat * (2.0 * dot_mr) - m) / r2


# Computes the world-space displacement caused by every nearby cell.
#
# Two components, summed:
#   1. A radial well dimple — pulls the grid vertex toward the cell center
#      with Gaussian falloff. Produces the "shallow gravity-like dip"
#      around each cell.
#   2. A dipole-flow term — sample of the cell's actual 2D magnetic dipole
#      field, saturated to a max displacement so it stays visually bounded.
#      Two cells' contributions ADD as vectors, so a saddle naturally appears
#      between them (cancellation along the inter-cell axis, reinforcement
#      perpendicular to it). Bonded compatible cells produce a continuous
#      flow channel that visibly bridges them.
func _accumulate_well_displacement(local_pos: Vector2, cells: Array) -> Vector2:
	var radial_total: Vector2 = Vector2.ZERO
	var dipole_total: Vector2 = Vector2.ZERO
	var eps2: float = GRID_DIPOLE_EPSILON * GRID_DIPOLE_EPSILON
	for cell in cells:
		if cell == null:
			continue
		var cb: CellBody = cell
		var diff: Vector2 = cb.position - local_pos
		var sigma: float = maxf(cb.radius * GRID_WELL_SIGMA_MULT, 1.0)
		var d2: float = diff.length_squared()
		var two_sigma2: float = 2.0 * sigma * sigma
		if d2 < two_sigma2 * 4.5:  # ≈ 3σ cutoff for the radial well
			var w: float = exp(-d2 / two_sigma2)
			# Pull vertex toward the cell center; scaled so the deepest dimple
			# (at d=0) is roughly cb.radius * GRID_WELL_DEPTH px.
			radial_total += diff.normalized() * (w * cb.radius * GRID_WELL_DEPTH)
		# Dipole-flow contribution. Reach is generous so saddles between
		# distant cells still register.
		var reach: float = cb.radius * GRID_DIPOLE_REACH_MULT
		if d2 < reach * reach:
			var axis: Vector2 = cb.polarity_axis()
			var axis_len_sq: float = axis.length_squared()
			if axis_len_sq > 0.0001:
				var axis_n: Vector2 = axis / sqrt(axis_len_sq)
				var moment_mag: float = cb.field_strength * cb.radius * cb.radius * cb.field_reach
				var moment: Vector2 = axis_n * moment_mag
				dipole_total += _dipole_contribution(local_pos - cb.position, moment, eps2)
	# Saturate the dipole-flow component so close-to-cell points don't shoot
	# off the screen. tanh-like soft clamp: |out| → max as |in| → ∞.
	var dl_sq: float = dipole_total.length_squared()
	var max_disp: float = GRID_DIPOLE_MAX_DISP
	var dipole_disp: Vector2 = Vector2.ZERO
	if dl_sq > 0.0000001:
		var dl: float = sqrt(dl_sq) * GRID_DIPOLE_GAIN
		dipole_disp = dipole_total * (GRID_DIPOLE_GAIN * (max_disp / sqrt(dl * dl + max_disp * max_disp)))
	return radial_total + dipole_disp


# Build one polyline along the X (or Y) axis at a fixed cross coordinate.
# `axis` 0 = horizontal scan (vary x), 1 = vertical scan (vary y).
func _build_line(
	axis: int,
	fixed_coord: float,
	span_min: float,
	span_max: float,
	sim_time: float,
	dish_radius: float,
	cells: Array,
	pulse: float
) -> Array:
	var n: int = maxi(GRID_LINE_STEPS, 4)
	var pts: PackedVector2Array = PackedVector2Array()
	pts.resize(n + 1)
	var glow_colors: PackedColorArray = PackedColorArray()
	var core_colors: PackedColorArray = PackedColorArray()
	glow_colors.resize(n + 1)
	core_colors.resize(n + 1)
	# Mirror AmbientField.STRENGTH default (kept in sync manually).
	var inv_strength: float = 1.0 / 18.0
	for i in n + 1:
		var t: float = float(i) / float(n)
		var local_x: float
		var local_y: float
		if axis == 0:
			local_x = lerpf(span_min, span_max, t)
			local_y = fixed_coord
		else:
			local_x = fixed_coord
			local_y = lerpf(span_min, span_max, t)
		var local_pos: Vector2 = Vector2(local_x, local_y)
		var ambient_vec: Vector2 = ambient.sample_local(local_pos, sim_time, dish_radius)
		var ambient_strength_norm: float = clampf(ambient_vec.length() * inv_strength, 0.0, 1.0)
		var ambient_dir: Vector2 = Vector2.ZERO
		if ambient_vec.length_squared() > 0.000001:
			ambient_dir = ambient_vec / ambient_vec.length()
		var ambient_displacement: Vector2 = ambient_dir * (ambient_strength_norm * GRID_AMBIENT_DISPLACEMENT)
		var well_displacement: Vector2 = _accumulate_well_displacement(local_pos, cells)
		var displaced: Vector2 = local_pos + ambient_displacement + well_displacement
		# Edge fade: lines near the dish rim soften so the grid doesn't slam into the glass.
		var rim_t: float = clampf(local_pos.length() / maxf(dish_radius, 0.001), 0.0, 1.0)
		var edge_alpha: float = lerpf(1.0, GRID_DARKEN_AT_DISH_EDGE, rim_t * rim_t)
		# Energy-driven brightness: hotter where ambient is strong or near a cell.
		var well_intensity: float = clampf(well_displacement.length() / 12.0, 0.0, 1.0)
		var energy: float = clampf(ambient_strength_norm + well_intensity * 0.7, 0.0, 1.0)
		var alpha_factor: float = (0.55 + 0.55 * energy) * pulse * edge_alpha
		pts[i] = displaced
		glow_colors[i] = Color(GRID_GLOW_TINT.r, GRID_GLOW_TINT.g, GRID_GLOW_TINT.b, GRID_GLOW_ALPHA * alpha_factor)
		core_colors[i] = Color(GRID_HOT_TINT.r, GRID_HOT_TINT.g, GRID_HOT_TINT.b, GRID_CORE_ALPHA * alpha_factor)
	return [pts, glow_colors, core_colors]


func draw_on(target: CanvasItem, sim_time: float, dish_radius: float, cells: Array, reveal_active: bool) -> void:
	primitive_count = 0
	if not reveal_active:
		return
	# Compute a slight global pulse so the whole grid breathes together.
	var pulse: float = 1.0 + GRID_PULSE_GAIN * sin(sim_time * GRID_PULSE_SPEED * TAU)
	# Span: cover the visible inner dish + a little beyond, snapped to grid.
	var inner: float = dish_radius * 0.92
	var span_min: float = -inner
	var span_max: float = inner
	# Number of lines in each axis; symmetric around 0.
	var spacing: float = maxf(GRID_SPACING, 4.0)
	var lines_per_axis: int = maxi(int(floor((inner * 2.0) / spacing)), 4)
	var start: float = -float(lines_per_axis) * 0.5 * spacing
	# Horizontal scans (constant Y, vary X)
	for j in lines_per_axis + 1:
		var y: float = start + float(j) * spacing
		if absf(y) > inner + GRID_CULL_MARGIN_PX:
			continue
		var line_data: Array = _build_line(0, y, span_min, span_max, sim_time, dish_radius, cells, pulse)
		var pts: PackedVector2Array = line_data[0]
		var glow_colors: PackedColorArray = line_data[1]
		var core_colors: PackedColorArray = line_data[2]
		target.draw_polyline_colors(pts, glow_colors, GRID_GLOW_WIDTH, true)
		target.draw_polyline_colors(pts, core_colors, GRID_CORE_WIDTH, true)
		primitive_count += 2
	# Vertical scans (constant X, vary Y)
	for i in lines_per_axis + 1:
		var x: float = start + float(i) * spacing
		if absf(x) > inner + GRID_CULL_MARGIN_PX:
			continue
		var line_data2: Array = _build_line(1, x, span_min, span_max, sim_time, dish_radius, cells, pulse)
		var pts2: PackedVector2Array = line_data2[0]
		var glow_colors2: PackedColorArray = line_data2[1]
		var core_colors2: PackedColorArray = line_data2[2]
		target.draw_polyline_colors(pts2, glow_colors2, GRID_GLOW_WIDTH, true)
		target.draw_polyline_colors(pts2, core_colors2, GRID_CORE_WIDTH, true)
		primitive_count += 2
