extends Node2D
class_name CellBody

@export var signature: CellSignature
@export var radius: float = 14.0
@export var selected: bool = false

var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var field: MediumField
var ports: Array[CellPort] = []
var dash_pulse: float = 0.0
var bonded_count: int = 0
var mass: float = 1.0
var linear_damping: float = 1.0
var angular_damping: float = 1.0
var max_speed: float = 68.0
var max_angular_speed: float = 1.15
var field_response: float = 1.0
var torque_response: float = 1.0
var seek_strength: float = 0.0
var capture_strength: float = 0.0
var snap_flash: float = 0.0
var clash_flash: float = 0.0
# Smoothed spin-direction state for coil/spiral cells. Initialized lazily on
# first field interaction so it doesn't flip due to numerical noise.
var _coil_dir_state: float = 0.0

static var debug_ports: bool = false
const DASH_PULSE_DECAY: float = 3.0

var _flicker: float = 0.0
var _baseline_noise: float = 0.0

# --- Base cell-field model (shared across every CellBody) ---
# Every cell projects a field of effect with the same data model. The values
# below are tuned per geometry in _apply_cell_field_defaults(), but the system
# is universal — no cell type bypasses it. PetriDish reads these to scale each
# cell's contribution to the dish-level field sampler and to drive the visible
# polarity-arc renderer.
var field_enabled: bool = true
var field_strength: float = 1.0      # multiplier on this cell's source contribution
var field_reach: float = 1.0         # reach multiplier for arc length / falloff feel
var field_arc_count: int = 1         # families per polarity side (1..2)
var polarity_phase: float = 0.0      # persistent phase offset for breathing/flicker
var field_seed: float = 0.0          # persistent per-cell visual seed

# Persistent per-cell plasma state. Assigned once on _ready so the local plasma
# field has temporal continuity instead of restarting each frame from per-frame
# random sources. _plasma_time advances monotonically; _plasma_seed offsets the
# phase per cell so neighbors do not pulse in unison. The two smoothed values
# low-pass the directional bias and interaction strength so transient changes
# (a neighbor entering reach radius, a bond capturing) deform the sheath
# gradually instead of snapping the visual to a new state.
var _plasma_time: float = 0.0
var _plasma_seed: float = 0.0
var _last_process_delta: float = 1.0 / 60.0
var _plasma_bias_smooth: Vector2 = Vector2.ZERO
var _plasma_interaction_smooth: float = 0.0
const PLASMA_BIAS_LERP_RATE: float = 3.5
const PLASMA_INTERACTION_LERP_RATE: float = 4.5

const TRAIL_MAX: int = 7
const TRAIL_INTERVAL: float = 0.07
var _trail: PackedVector2Array = PackedVector2Array()
var _trail_accum: float = 0.0
var _ambient_debug_vector: Vector2 = Vector2.ZERO
var _ambient_debug_strength: float = 0.0
var _ambient_debug_mode: String = "idle"

const ZONE_COLORS: Dictionary = {
	"surface": Color(0.85, 0.92, 1.00),
	"tip_sharp": Color(1.00, 0.55, 0.30),
	"flat": Color(0.55, 0.90, 0.65),
	"end": Color(1.00, 0.90, 0.50),
	"side": Color(0.70, 0.75, 0.95),
	"inner_curve": Color(0.95, 0.55, 0.85),
	"outer_curve": Color(0.50, 0.55, 0.70),
	"tip_hook": Color(1.00, 0.70, 0.40),
}

const NOISE_MAX: float = 4.0

# --- motion ---
const DAMPING: float = 8.8
const BROWNIAN_BASE: float = 9.0
const BOUNDARY_MARGIN: float = 28.0
const BOUNDARY_PUSH: float = 14.0
const MAX_LINEAR_SPEED: float = 68.0
const MAX_LINEAR_ACCEL: float = 165.0
const MAX_ANGULAR_SPEED: float = 1.15
const MAX_ANGULAR_ACCEL: float = 3.6
const VELOCITY_DEAD_ZONE: float = 1.2
const ANGULAR_DEAD_ZONE: float = 0.02
const EXTERNAL_DAMP_SCALE: float = 0.55
const BONDED_BROWNIAN_SUPPRESS: float = 0.6   # per bond: brownian *= max(0, 1 - n*this)
const BONDED_FLICKER_SUPPRESS: float = 0.5
const SEEK_DRIFT_SUPPRESS: float = 0.72
const CAPTURE_DRIFT_SUPPRESS: float = 0.92
const BASE_ANGULAR_DAMP: float = 3.0
const LINE_ANGULAR_DAMP: float = 2.8
const SEEK_ANGULAR_DAMP: float = 2.6
const CAPTURE_ANGULAR_DAMP: float = 6.5
const SEEK_STATE_DECAY: float = 8.0
const CAPTURE_STATE_DECAY: float = 10.0
const SNAP_FLASH_DECAY: float = 9.0
const CLASH_FLASH_DECAY: float = 12.0

# --- round homeostasis ---
const ROUND_DEPLETED_RATIO: float = 0.28
const ROUND_HEALTHY_MIN_RATIO: float = 0.46
const ROUND_HEALTHY_MAX_RATIO: float = 0.72
const ROUND_OVERCHARGED_RATIO: float = 0.88
const ROUND_GRADIENT_SAMPLES: int = 8
const ROUND_GRADIENT_RADIUS: float = 30.0
const ROUND_GRADIENT_GAIN: float = 22.0
const ROUND_GRADIENT_REPEL: float = 20.0
const ROUND_ORBIT_GAIN: float = 4.2
const ROUND_HEALTHY_ORBIT_GAIN: float = 1.2
const ROUND_OVERCHARGED_ORBIT_GAIN: float = 1.8
const ROUND_MAGNETIC_GRADIENT_WEIGHT: float = 1.0
const ROUND_CHARGE_GRADIENT_WEIGHT: float = 0.38
const ROUND_NOISE_AVOID_GAIN: float = 9.0
const ROUND_GRADIENT_MIN: float = 0.018
const ROUND_REST_BRAKE: float = 7.6
const ROUND_SPIN_BRAKE: float = 6.4
const ROUND_HEALTHY_DRAG: float = 7.2
const ROUND_OVERCHARGED_DRAG: float = 5.8
const ROUND_DEPLETED_DRAG: float = 1.8
const ROUND_HEALTHY_ABSORB: float = 0.35
const ROUND_OVERCHARGED_ABSORB: float = 0.04
const ROUND_DEPLETED_ABSORB: float = 1.25
const ROUND_BROWNIAN_DEPLETED: float = 0.012
const ROUND_BROWNIAN_HEALTHY: float = 0.0015
const ROUND_BROWNIAN_OVERCHARGED: float = 0.003
const ROUND_NOISE_AVOID_MIN: float = 0.10
const SPHERE_AMBIENT_DRIFT_GAIN: float = 4.8
const SPHERE_AMBIENT_CALM_PREFERENCE: float = 5.4
const SPHERE_AMBIENT_ALIGN_GAIN: float = 0.10

# --- coil (spiral) field-induced spin ---
# Continuous-time rotor model. The coil receives an angular acceleration
# proportional to local normalized cell-field strength, multiplied by a
# smoothed direction state so the sign cannot flip frame-to-frame. An always-on
# damping term gives the spin a finite settling time and ensures the coil
# slows down when it leaves a strong field. Steady-state ω near a steady field
# is roughly (TORQUE_GAIN / SPIN_DAMPING) * strength, capped at MAX_ANGULAR_SPEED.
const COIL_FIELD_TORQUE_GAIN: float = 1.80    # rad/s² per unit normalized field strength
const COIL_MAX_ANGULAR_SPEED: float = 2.20    # cap on rotor angular velocity (rad/s)
const COIL_SPIN_DAMPING: float = 0.85         # per-second exponential damping when away from field
const COIL_DIRECTION_MEMORY: float = 1.40     # rate (1/s) at which smoothed direction relaxes to preferred
const COIL_AMBIENT_ALIGN_GAIN: float = 1.35
const COIL_AMBIENT_SPIN_GAIN: float = 0.95
const COIL_AMBIENT_DRIFT_GAIN: float = 8.5
const COIL_AMBIENT_VORTEX_GAIN: float = 0.42

# --- ambient field coupling ---
const TRIANGLE_AMBIENT_DRIFT_GAIN: float = 2.6
const TRIANGLE_AMBIENT_ALIGN_GAIN: float = 0.24
const CRESCENT_AMBIENT_SHAPE_GAIN: float = 4.0
const CRESCENT_AMBIENT_ALIGN_GAIN: float = 0.40
const AMBIENT_SAMPLE_RADIUS: float = 28.0
const AMBIENT_GRADIENT_MIN: float = 0.010
const LOCAL_PLASMA_ENABLED: bool = true
const LOCAL_PLASMA_CORE_WIDTH: float = 1.45
const LOCAL_PLASMA_GLOW_WIDTH: float = 4.2
const LOCAL_PLASMA_CORE_ALPHA: float = 0.26
const LOCAL_PLASMA_GLOW_ALPHA: float = 0.10
const LOCAL_PLASMA_BRIGHTNESS_GAIN: float = 1.20
const LOCAL_PLASMA_THICKNESS_GAIN: float = 1.08
const LOCAL_PLASMA_DISTORTION_GAIN: float = 0.20
const LOCAL_PLASMA_INTERACTION_GAIN: float = 0.60
const LOCAL_PLASMA_PULSE_GAIN: float = 0.15
const LOCAL_PLASMA_PULSE_SPEED: float = 1.65
const CELL_PLASMA_CORE_BRIGHTNESS: float = 1.26
const CELL_PLASMA_SHEATH_WIDTH: float = 0.16
const CELL_PLASMA_SHEATH_BRIGHTNESS: float = 0.78
const CELL_PLASMA_FLOW_SPEED: float = 0.62
const CELL_PLASMA_WARP_STRENGTH: float = 0.20
const CELL_PLASMA_FILAMENT_ALPHA: float = 0.18
const CELL_PLASMA_FILAMENT_COUNT: int = 4
const CELL_PLASMA_FILAMENT_WIDTH: float = 0.90
const CELL_PLASMA_FILAMENT_GLOW_WIDTH: float = 2.35

# --- wedge impulse ---
const WEDGE_IMPULSE_THRESHOLD: float = 0.40
const WEDGE_IMPULSE_RATE: float = 0.6
const WEDGE_IMPULSE_FORCE: float = 110.0
const WEDGE_IMPULSE_COST: float = 0.20

# --- charge economy ---
const ABSORB_RATE: float = 0.55
const MAINTENANCE_COST: float = 0.020
const MOVEMENT_COST: float = 0.0009
const SPIRAL_PULSE_COST: float = 0.035

# --- low-charge degradation ---
const LOW_CHARGE_THRESHOLD: float = 0.20
const LOW_CHARGE_DAMPING_BOOST: float = 1.8
const LOW_CHARGE_STABILITY_PENALTY: float = 0.55

# --- noise dynamics ---
const AMBIENT_NOISE_INTAKE: float = 0.7
const INTERNAL_NOISE_DECAY: float = 0.4
const ERRATIC_MULTIPLIER: float = 2.5
const FIELD_STIR_RATE: float = 0.5

# --- overload ---
const OVERLOAD_THRESHOLD: float = 0.85
const OVERLOAD_VENT_RATE: float = 1.4
const OVERLOAD_NOISE_FRACTION: float = 0.8
const OVERLOAD_SELF_NOISE: float = 0.3


func _ready() -> void:
	if signature == null:
		signature = CellSignature.new()
	_baseline_noise = signature.noise
	if ports.is_empty():
		_generate_ports()
	_sync_physical_tuning()
	_apply_cell_field_defaults()
	_init_motion()
	_plasma_seed = randf() * TAU
	field_seed = randf() * TAU
	polarity_phase = randf() * TAU


func set_signature(sig: CellSignature) -> void:
	signature = sig.duplicate() as CellSignature
	_baseline_noise = signature.noise
	_generate_ports()
	_sync_physical_tuning()
	_apply_cell_field_defaults()


func _generate_ports() -> void:
	ports.clear()
	var geom: String = signature.geometry_type
	if geom == "wedge":
		geom = "triangle"
		signature.geometry_type = "triangle"
	match geom:
		"round":
			for i in 8:
				var ang: float = (float(i) / 8.0) * TAU
				var n: Vector2 = Vector2.RIGHT.rotated(ang)
				ports.append(CellPort.new(n * radius, n, "surface", 1.0))
		"triangle":
			# Body drawn with tip up at -Y, base from (-r*0.95, r*0.85) to (r*0.95, r*0.85)
			var tip: Vector2 = Vector2(0.0, -radius * 1.20)
			var base_l: Vector2 = Vector2(-radius * 0.95, radius * 0.85)
			var base_r: Vector2 = Vector2(radius * 0.95, radius * 0.85)
			ports.append(CellPort.new(tip, Vector2(0.0, -1.0), "tip_sharp", 1.2))
			# Left flank: midpoint, normal perpendicular pointing outward-left
			var ml: Vector2 = (tip + base_l) * 0.5
			var el: Vector2 = base_l - tip
			var nl: Vector2 = Vector2(-el.y, el.x).normalized()  # rotate +90 to get outward-left
			ports.append(CellPort.new(ml, nl, "flat", 1.0))
			# Right flank
			var mr: Vector2 = (tip + base_r) * 0.5
			var er: Vector2 = base_r - tip
			var nr: Vector2 = Vector2(er.y, -er.x).normalized()  # rotate -90 to get outward-right
			ports.append(CellPort.new(mr, nr, "flat", 1.0))
			# Base
			var mb: Vector2 = (base_l + base_r) * 0.5
			ports.append(CellPort.new(mb, Vector2(0.0, 1.0), "flat", 1.0))
		"line":
			# LEGACY_LINE_CELL_PATH: preserved until plasma bridge replacement exists.
			# Drawn from (0, -r*1.2) to (0, r*1.2)
			ports.append(CellPort.new(Vector2(0.0, -radius * 1.20), Vector2(0.0, -1.0), "end", 1.1))
			ports.append(CellPort.new(Vector2(0.0,  radius * 1.20), Vector2(0.0,  1.0), "end", 1.1))
			ports.append(CellPort.new(Vector2(-radius * 0.30, 0.0), Vector2(-1.0, 0.0), "side", 0.8))
			ports.append(CellPort.new(Vector2( radius * 0.30, 0.0), Vector2( 1.0, 0.0), "side", 0.8))
		"crescent":
			# Body arc spans -PI*0.85 .. +PI*0.85 on the +X side; the concave inner curve faces -X.
			# Inner curve sits at radius r*0.72; its outward normal (toward concave/-X side) is -(cos,sin).
			var inner_r: float = radius * 0.72
			var inner_angles: Array[float] = [-PI * 0.40, 0.0, PI * 0.40]
			for ang in inner_angles:
				var p: Vector2 = Vector2(cos(ang), sin(ang)) * inner_r
				var n: Vector2 = -Vector2(cos(ang), sin(ang))
				ports.append(CellPort.new(p, n, "inner_curve", 1.0))
			# Tips at ±PI*0.85 on outer arc
			var tip_angles: Array[float] = [-PI * 0.85, PI * 0.85]
			for ang in tip_angles:
				var p: Vector2 = Vector2(cos(ang), sin(ang)) * radius
				# Tangent direction along the curve, pointing away from the body interior
				var tan_dir: Vector2 = Vector2(-sin(ang), cos(ang))
				if tan_dir.x > 0.0:
					tan_dir = -tan_dir  # tips reach toward -X (away from body)
				ports.append(CellPort.new(p, tan_dir.normalized(), "tip_hook", 0.9))
			# Outer curve weak anchors
			var outer_angles: Array[float] = [-PI * 0.30, PI * 0.30]
			for ang in outer_angles:
				var p: Vector2 = Vector2(cos(ang), sin(ang)) * (radius * 1.05)
				var n: Vector2 = Vector2(cos(ang), sin(ang))
				ports.append(CellPort.new(p, n, "outer_curve", 0.5))
		_:
			ports.append(CellPort.new(Vector2(radius, 0.0), Vector2.RIGHT, "surface", 1.0))


func get_world_ports() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in ports:
		var world_normal: Vector2 = p.local_normal.rotated(rotation)
		var world_pos: Vector2 = position + p.local_position.rotated(rotation)
		out.append({
			"position": world_pos,
			"direction": world_normal,
			"zone": p.zone_type,
			"strength": p.strength,
		})
	return out


func _init_motion() -> void:
	var geom: String = signature.geometry_type
	if geom == "wedge":
		geom = "triangle"
	match geom:
		"spiral":
			angular_velocity = signature.rhythm_frequency * randf_range(0.4, 0.7) * (1 if randf() < 0.5 else -1)
		"triangle":
			angular_velocity = randf_range(-0.18, 0.18)
		"line":
			angular_velocity = randf_range(-0.04, 0.04)
		"crescent":
			angular_velocity = randf_range(-0.06, 0.06)
		"round":
			angular_velocity = randf_range(-0.015, 0.015)
	angular_velocity = clampf(angular_velocity, -max_angular_speed, max_angular_speed)


func _sync_physical_tuning() -> void:
	match _canonical_geom():
		"triangle":
			mass = 1.65
			linear_damping = 1.40
			angular_damping = 1.45
			max_speed = 46.0
			max_angular_speed = 0.62
			field_response = 0.38
			torque_response = 0.55
		"line":
			# LEGACY_LINE_CELL_PATH: preserved until plasma bridge replacement exists.
			mass = 0.90
			linear_damping = 1.00
			angular_damping = 1.00
			max_speed = 74.0
			max_angular_speed = 0.95
			field_response = 0.68
			torque_response = 0.88
		"crescent":
			mass = 1.05
			linear_damping = 0.98
			angular_damping = 0.94
			max_speed = 68.0
			max_angular_speed = 1.00
			field_response = 0.72
			torque_response = 0.96
		"spiral":
			mass = 0.82
			linear_damping = 0.90
			angular_damping = 0.68
			max_speed = 78.0
			max_angular_speed = 1.85
			field_response = 0.90
			torque_response = 1.55
		_:
			mass = 1.08
			linear_damping = 1.68
			angular_damping = 1.52
			max_speed = 44.0
			max_angular_speed = 0.42
			field_response = 0.74
			torque_response = 0.70


func _apply_cell_field_defaults() -> void:
	# Per-type expression of the same base cell-field. Spheres are the strongest
	# broad projectors; coils torsion the lobes; crescents narrow and focus
	# their throat; triangles are weak edge-pinned emitters. Every type has
	# the field — the multipliers shape, not gate, the expression.
	field_enabled = true
	match _canonical_geom():
		"round":
			field_strength = 1.00
			field_reach = 1.40
			field_arc_count = 2
		"spiral":
			field_strength = 0.65
			field_reach = 1.05
			field_arc_count = 2
		"crescent":
			field_strength = 0.55
			field_reach = 0.95
			field_arc_count = 1
		"triangle":
			field_strength = 0.42
			field_reach = 0.78
			field_arc_count = 1
		"line":
			field_strength = 0.30
			field_reach = 0.70
			field_arc_count = 1
		_:
			field_strength = 0.50
			field_reach = 0.85
			field_arc_count = 1


func polarity_axis() -> Vector2:
	# Stable two-lobe field axis. Rotation-locked so the polarity tracks the
	# cell's orientation; crescents project through their aperture instead of
	# along the body up-axis.
	var axis: Vector2
	if _canonical_geom() == "crescent":
		axis = Vector2.LEFT.rotated(rotation)
	else:
		axis = Vector2.UP.rotated(rotation)
	if axis.length_squared() <= 0.000001:
		return Vector2.UP
	return axis.normalized()


func _process(delta: float) -> void:
	if signature == null:
		return
	delta = minf(delta, 1.0 / 30.0)
	signature.rhythm_phase = fposmod(
		signature.rhythm_phase + signature.rhythm_frequency * TAU * delta, TAU
	)
	_interact_with_field(delta)
	_apply_coil_field_spin(delta)
	_spend_maintenance(delta)
	_flicker = randf_range(-1.0, 1.0) * signature.noise
	_plasma_time += delta
	_last_process_delta = delta
	_step_motion(delta)
	_decay_internal_noise(delta)
	seek_strength = maxf(0.0, seek_strength - SEEK_STATE_DECAY * delta)
	capture_strength = maxf(0.0, capture_strength - CAPTURE_STATE_DECAY * delta)
	snap_flash = maxf(0.0, snap_flash - SNAP_FLASH_DECAY * delta)
	clash_flash = maxf(0.0, clash_flash - CLASH_FLASH_DECAY * delta)
	rotation += angular_velocity * delta
	if dash_pulse > 0.0:
		dash_pulse = maxf(0.0, dash_pulse - DASH_PULSE_DECAY * delta)
	_sample_trail(delta)
	queue_redraw()


func _sample_trail(delta: float) -> void:
	_trail_accum += delta
	if _trail_accum < TRAIL_INTERVAL:
		return
	_trail_accum = 0.0
	_trail.append(position)
	while _trail.size() > TRAIL_MAX:
		_trail.remove_at(0)


# --- field interaction ---

func _interact_with_field(delta: float) -> void:
	if field == null:
		return

	var local_light: float = field.sample_light(position)
	var charge_ratio: float = charge_ratio_value()
	var headroom: float = signature.charge_capacity - signature.charge
	if headroom > 0.0 and local_light > 0.0:
		var absorb_gate: float = 1.0
		if _canonical_geom() == "round":
			if is_round_depleted():
				absorb_gate = ROUND_DEPLETED_ABSORB
			elif is_round_overcharged():
				absorb_gate = ROUND_OVERCHARGED_ABSORB
			elif charge_ratio >= ROUND_HEALTHY_MIN_RATIO:
				absorb_gate = ROUND_HEALTHY_ABSORB
		var want: float = signature.storage_bias * local_light * ABSORB_RATE * absorb_gate * delta
		if want > headroom:
			want = headroom
		var got: float = field.consume_charge(position, want)
		signature.charge += got

	var ambient: float = field.sample_noise(position)
	if ambient > 0.0:
		var intake: float = ambient * AMBIENT_NOISE_INTAKE * delta
		signature.noise = clampf(signature.noise + intake, 0.0, NOISE_MAX)

	if signature.noise > 0.0:
		field.add_noise(position, signature.noise * FIELD_STIR_RATE * delta)

	var safe: float = signature.charge_capacity * OVERLOAD_THRESHOLD
	if signature.charge > safe:
		var excess: float = signature.charge - safe
		var vent: float = minf(excess, OVERLOAD_VENT_RATE * delta)
		signature.charge -= vent
		field.add_noise(position, vent * OVERLOAD_NOISE_FRACTION)
		signature.noise = clampf(signature.noise + vent * OVERLOAD_SELF_NOISE, 0.0, NOISE_MAX)


# --- charge spending ---

func _spend_charge(amount: float) -> void:
	signature.charge = maxf(0.0, signature.charge - amount)


func _spend_maintenance(delta: float) -> void:
	_spend_charge(MAINTENANCE_COST * delta)
	var g: String = signature.geometry_type
	if g == "spiral" or g == "crescent":
		_spend_charge(SPIRAL_PULSE_COST * delta)


func _decay_internal_noise(delta: float) -> void:
	var diff: float = signature.noise - _baseline_noise
	if diff <= 0.0:
		return
	signature.noise = maxf(_baseline_noise, signature.noise - diff * INTERNAL_NOISE_DECAY * delta)


func begin_interaction_frame() -> void:
	seek_strength = 0.0
	capture_strength = 0.0


func apply_velocity_delta(delta_v: Vector2) -> void:
	velocity += delta_v / maxf(mass, 0.001)


func apply_field_velocity_delta(delta_v: Vector2) -> void:
	apply_velocity_delta(delta_v * field_response)


func apply_angular_delta(delta_w: float) -> void:
	var inertia_scale: float = torque_response / sqrt(maxf(mass, 0.001))
	angular_velocity += delta_w * inertia_scale


func charge_ratio_value() -> float:
	return clampf(signature.charge / maxf(signature.charge_capacity, 0.0001), 0.0, 1.0)


func round_depletion_factor() -> float:
	if _canonical_geom() != "round":
		return 0.0
	var ratio: float = charge_ratio_value()
	if ratio >= ROUND_DEPLETED_RATIO:
		return 0.0
	return clampf(1.0 - ratio / maxf(ROUND_DEPLETED_RATIO, 0.001), 0.0, 1.0)


func round_healthy_factor() -> float:
	if _canonical_geom() != "round":
		return 0.0
	var ratio: float = charge_ratio_value()
	if ratio < ROUND_HEALTHY_MIN_RATIO or ratio > ROUND_HEALTHY_MAX_RATIO:
		return 0.0
	var mid: float = (ROUND_HEALTHY_MIN_RATIO + ROUND_HEALTHY_MAX_RATIO) * 0.5
	var half_span: float = maxf((ROUND_HEALTHY_MAX_RATIO - ROUND_HEALTHY_MIN_RATIO) * 0.5, 0.001)
	return clampf(1.0 - absf(ratio - mid) / half_span, 0.0, 1.0)


func round_overcharge_factor() -> float:
	if _canonical_geom() != "round":
		return 0.0
	var ratio: float = charge_ratio_value()
	if ratio <= ROUND_OVERCHARGED_RATIO:
		return 0.0
	return clampf((ratio - ROUND_OVERCHARGED_RATIO) / maxf(1.0 - ROUND_OVERCHARGED_RATIO, 0.001), 0.0, 1.0)


func round_noise_excess() -> float:
	if _canonical_geom() != "round":
		return 0.0
	return maxf(0.0, signature.noise - _baseline_noise)


func is_round_depleted() -> bool:
	return round_depletion_factor() > 0.0


func is_round_healthy() -> bool:
	return round_healthy_factor() > 0.0


func is_round_overcharged() -> bool:
	return round_overcharge_factor() > 0.0


func note_seek(strength: float) -> void:
	seek_strength = maxf(seek_strength, clampf(strength, 0.0, 1.0))


func note_capture(strength: float) -> void:
	capture_strength = maxf(capture_strength, clampf(strength, 0.0, 1.0))


func trigger_snap_flash(strength: float = 1.0) -> void:
	snap_flash = maxf(snap_flash, clampf(strength, 0.0, 1.0))


func trigger_clash_flash(strength: float = 1.0) -> void:
	clash_flash = maxf(clash_flash, clampf(strength, 0.0, 1.0))


func brownian_scale() -> float:
	var bond_calm: float = maxf(0.0, 1.0 - float(bonded_count) * BONDED_BROWNIAN_SUPPRESS)
	var seek_calm: float = 1.0 - seek_strength * SEEK_DRIFT_SUPPRESS
	var capture_calm: float = 1.0 - capture_strength * CAPTURE_DRIFT_SUPPRESS
	var base: float = 1.0
	if _canonical_geom() == "round":
		base = ROUND_BROWNIAN_HEALTHY
		if is_round_depleted():
			base = lerpf(ROUND_BROWNIAN_HEALTHY, ROUND_BROWNIAN_DEPLETED, round_depletion_factor())
		elif is_round_overcharged():
			base = lerpf(ROUND_BROWNIAN_HEALTHY, ROUND_BROWNIAN_OVERCHARGED, round_overcharge_factor())
	return clampf(base * bond_calm * seek_calm * capture_calm, 0.0, 1.0)


# --- motion ---

func _step_motion(delta: float) -> void:
	var prev_velocity: Vector2 = velocity
	var prev_angular_velocity: float = angular_velocity
	var charge_ratio: float = charge_ratio_value()
	var starve: float = 0.0
	if charge_ratio < LOW_CHARGE_THRESHOLD:
		starve = 1.0 - (charge_ratio / LOW_CHARGE_THRESHOLD)

	var eff_stability: float = signature.stability * (1.0 - starve * LOW_CHARGE_STABILITY_PENALTY)
	var calmness: float = clampf(1.0 - eff_stability * 0.6, 0.2, 1.4)

	var excess_noise: float = maxf(0.0, signature.noise - _baseline_noise)
	var erratic: float = 1.0 + excess_noise * ERRATIC_MULTIPLIER

	# Brownian is now owned by PetriDish (cluster-aware). CellBody only handles
	# integration + damping + boundary + dash here.
	var _unused_calmness: float = calmness
	var _unused_erratic: float = erratic

	if signature.geometry_type == "triangle" or signature.geometry_type == "wedge":
		_maybe_wedge_impulse(delta)
	if _canonical_geom() == "round":
		_apply_round_homeostasis(delta)
	var dish: PetriDish = _dish_parent()
	if dish != null and dish.perf_monitors_enabled():
		var ambient_start_us: int = Time.get_ticks_usec()
		_apply_ambient_field_response(delta, dish)
		dish.perf_note_cell_ambient_time(Time.get_ticks_usec() - ambient_start_us)
	else:
		_apply_ambient_field_response(delta, dish)

	_apply_boundary_force(delta)
	_limit_motion_change(prev_velocity, prev_angular_velocity, delta)
	_apply_motion_damping(delta, starve, 1.0)
	_clamp_motion_state()

	var prev_pos: Vector2 = position
	position += velocity * delta

	var max_dist: float = PetriDish.DISH_RADIUS - radius
	var d: float = position.length()
	if d > max_dist and d > 0.0:
		position = position * (max_dist / d)
		var inward: Vector2 = -position.normalized()
		var outward_speed: float = -velocity.dot(inward)
		if outward_speed > 0.0:
			velocity += inward * outward_speed
	_clamp_motion_state()

	var moved: float = (position - prev_pos).length()
	if moved > 0.0:
		_spend_charge(moved * MOVEMENT_COST)


func stabilize_external_motion(prev_velocity: Vector2, prev_angular_velocity: float, delta: float) -> void:
	_limit_motion_change(prev_velocity, prev_angular_velocity, delta)
	var charge_ratio: float = charge_ratio_value()
	var starve: float = 0.0
	if charge_ratio < LOW_CHARGE_THRESHOLD:
		starve = 1.0 - (charge_ratio / LOW_CHARGE_THRESHOLD)
	_apply_motion_damping(delta, starve, EXTERNAL_DAMP_SCALE)
	_clamp_motion_state()


func _limit_motion_change(prev_velocity: Vector2, prev_angular_velocity: float, delta: float) -> void:
	if delta <= 0.0:
		return
	var dv: Vector2 = velocity - prev_velocity
	var max_dv: float = MAX_LINEAR_ACCEL * delta
	if dv.length() > max_dv:
		velocity = prev_velocity + dv.normalized() * max_dv
	var dw: float = angular_velocity - prev_angular_velocity
	var max_dw: float = MAX_ANGULAR_ACCEL * delta
	angular_velocity = prev_angular_velocity + clampf(dw, -max_dw, max_dw)


func _apply_motion_damping(delta: float, starve: float, scale: float) -> void:
	var eff_damping: float = _linear_damping_value(starve)
	velocity *= exp(-eff_damping * scale * delta)
	var ang_damp: float = _angular_damping_value()
	angular_velocity *= exp(-ang_damp * scale * delta)


func _linear_damping_value(starve: float) -> float:
	var eff_damping: float = DAMPING * linear_damping * (1.0 + starve * (LOW_CHARGE_DAMPING_BOOST - 1.0) + capture_strength * 1.4)
	if _canonical_geom() == "round":
		eff_damping += ROUND_DEPLETED_DRAG * round_depletion_factor()
		eff_damping += ROUND_HEALTHY_DRAG * round_healthy_factor()
		eff_damping += ROUND_OVERCHARGED_DRAG * round_overcharge_factor()
	return eff_damping


func _angular_damping_value() -> float:
	var ang_damp: float = BASE_ANGULAR_DAMP + seek_strength * SEEK_ANGULAR_DAMP + capture_strength * CAPTURE_ANGULAR_DAMP
	if signature.geometry_type == "line":
		ang_damp += LINE_ANGULAR_DAMP
	return ang_damp * angular_damping


func _clamp_motion_state() -> void:
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	angular_velocity = clampf(angular_velocity, -max_angular_speed, max_angular_speed)
	if velocity.length() < VELOCITY_DEAD_ZONE:
		velocity = Vector2.ZERO
	if absf(angular_velocity) < ANGULAR_DEAD_ZONE:
		angular_velocity = 0.0


func _dish_parent() -> PetriDish:
	return get_parent() as PetriDish


func _sample_ambient_field(dish: PetriDish, local_pos: Vector2) -> Vector2:
	if dish == null:
		return Vector2.ZERO
	dish.perf_note_ambient_field_samples()
	return dish.sample_ambient_field(dish.to_global(local_pos))


func _sample_ambient_calm(dish: PetriDish, local_pos: Vector2) -> float:
	if dish == null:
		return 1.0
	dish.perf_note_ambient_calm_samples()
	return dish.sample_ambient_field_calm_metric(dish.to_global(local_pos))


func _sample_ambient_curl(dish: PetriDish, local_pos: Vector2) -> float:
	if dish == null:
		return 0.0
	dish.perf_note_ambient_curl_samples()
	dish.perf_note_ambient_field_samples(4)
	return dish.sample_ambient_field_curl_hint(dish.to_global(local_pos))


func _sample_ambient_gradient(dish: PetriDish, local_pos: Vector2) -> Vector2:
	if dish == null:
		return Vector2.ZERO
	var center_strength: float = _sample_ambient_field(dish, local_pos).length()
	var gradient: Vector2 = Vector2.ZERO
	for i in 6:
		var ang: float = (float(i) / 6.0) * TAU
		var dir: Vector2 = Vector2.RIGHT.rotated(ang)
		var sample_strength: float = _sample_ambient_field(dish, local_pos + dir * (radius + AMBIENT_SAMPLE_RADIUS)).length()
		gradient += dir * (sample_strength - center_strength)
	return gradient / 6.0


func _sample_ambient_calm_gradient(dish: PetriDish, local_pos: Vector2) -> Vector2:
	if dish == null:
		return Vector2.ZERO
	var center_calm: float = _sample_ambient_calm(dish, local_pos)
	var gradient: Vector2 = Vector2.ZERO
	for i in 6:
		var ang: float = (float(i) / 6.0) * TAU
		var dir: Vector2 = Vector2.RIGHT.rotated(ang)
		var sample_calm: float = _sample_ambient_calm(dish, local_pos + dir * (radius + AMBIENT_SAMPLE_RADIUS))
		gradient += dir * (sample_calm - center_calm)
	return gradient / 6.0


func _forward_axis() -> Vector2:
	return Vector2(0.0, -1.0).rotated(rotation)


func _signed_axis_error(target_dir: Vector2, axis: Vector2) -> float:
	if target_dir.length_squared() <= 0.000001 or axis.length_squared() <= 0.000001:
		return 0.0
	var a: Vector2 = axis.normalized()
	var t: Vector2 = target_dir.normalized()
	return a.x * t.y - a.y * t.x


func _apply_axis_alignment(target_dir: Vector2, gain: float, strength: float, delta: float) -> void:
	if strength <= 0.0 or target_dir.length_squared() <= 0.000001:
		return
	apply_angular_delta(_signed_axis_error(target_dir, _forward_axis()) * gain * strength * delta)


func _apply_ambient_field_response(delta: float, dish: PetriDish) -> void:
	var ambient_vec: Vector2 = _sample_ambient_field(dish, position)
	_ambient_debug_vector = ambient_vec
	_ambient_debug_strength = ambient_vec.length()
	_ambient_debug_mode = "idle"
	if dish == null:
		return
	var ambient_strength_ratio: float = _ambient_debug_strength / maxf(PetriDish.AMBIENT_FIELD_STRENGTH, 0.001)
	if ambient_strength_ratio <= 0.0001:
		return
	var ambient_dir: Vector2 = ambient_vec / maxf(_ambient_debug_strength, 0.0001)
	match _canonical_geom():
		"round":
			var ambient_grad: Vector2 = _sample_ambient_gradient(dish, position)
			var ambient_calm: float = _sample_ambient_calm(dish, position)
			var calm_grad: Vector2 = _sample_ambient_calm_gradient(dish, position)
			_apply_round_ambient_response(delta, ambient_dir, ambient_strength_ratio, ambient_grad, ambient_calm, calm_grad)
		"spiral":
			_apply_coil_ambient_response(delta, dish, ambient_dir, ambient_strength_ratio, ambient_vec)
		"triangle":
			_apply_triangle_ambient_response(delta, ambient_dir, ambient_strength_ratio)
		"crescent":
			var crescent_calm_grad: Vector2 = _sample_ambient_calm_gradient(dish, position)
			_apply_crescent_ambient_response(delta, ambient_dir, ambient_strength_ratio, crescent_calm_grad)
		_:
			apply_field_velocity_delta(ambient_dir * ambient_strength_ratio * 1.2 * delta)
			_ambient_debug_mode = "ambient_drift"


func _apply_round_ambient_response(delta: float, ambient_dir: Vector2, ambient_strength_ratio: float, ambient_grad: Vector2, ambient_calm: float, calm_grad: Vector2) -> void:
	var healthy: float = round_healthy_factor()
	var depleted: float = round_depletion_factor()
	var over: float = round_overcharge_factor()
	var ambient_drive: float = ambient_strength_ratio * (0.18 + depleted * 0.46 + over * 0.18 + healthy * 0.10)
	if ambient_drive > 0.001:
		apply_field_velocity_delta(ambient_dir * SPHERE_AMBIENT_DRIFT_GAIN * ambient_drive * delta)
	if ambient_grad.length() > AMBIENT_GRADIENT_MIN and depleted > 0.0:
		apply_field_velocity_delta(ambient_grad.normalized() * SPHERE_AMBIENT_DRIFT_GAIN * 0.45 * ambient_drive * delta)
	var calm_grad_strength: float = calm_grad.length()
	if calm_grad_strength > AMBIENT_GRADIENT_MIN:
		var calm_dir: Vector2 = calm_grad / calm_grad_strength
		var calm_bias: float = clampf(ambient_strength_ratio * (0.30 + healthy * 0.40 + over * 0.32) * (1.0 - ambient_calm * 0.25), 0.0, 1.0)
		apply_field_velocity_delta(calm_dir * SPHERE_AMBIENT_CALM_PREFERENCE * calm_bias * delta)
	if ambient_drive > 0.001:
		apply_angular_delta(_signed_axis_error(ambient_dir, Vector2.UP.rotated(rotation)) * SPHERE_AMBIENT_ALIGN_GAIN * ambient_drive * delta)
	_ambient_debug_mode = "sphere_calm_seek" if calm_grad_strength > AMBIENT_GRADIENT_MIN else "sphere_drift"


func _apply_coil_ambient_response(delta: float, dish: PetriDish, ambient_dir: Vector2, ambient_strength_ratio: float, ambient_vec: Vector2) -> void:
	var align_strength: float = clampf(ambient_strength_ratio * 1.15, 0.0, 1.0)
	_apply_axis_alignment(ambient_dir, COIL_AMBIENT_ALIGN_GAIN, align_strength, delta)
	apply_field_velocity_delta(ambient_dir * COIL_AMBIENT_DRIFT_GAIN * ambient_strength_ratio * delta)
	var ambient_curl: float = _sample_ambient_curl(dish, position)
	var flow_spin: float = _forward_axis().x * ambient_vec.y - _forward_axis().y * ambient_vec.x
	var spin_drive: float = ambient_curl * COIL_AMBIENT_VORTEX_GAIN + flow_spin * COIL_AMBIENT_SPIN_GAIN
	apply_angular_delta(spin_drive * ambient_strength_ratio * delta)
	_ambient_debug_mode = "coil_align_spin"


func _apply_triangle_ambient_response(delta: float, ambient_dir: Vector2, ambient_strength_ratio: float) -> void:
	var lane_drive: float = clampf(ambient_strength_ratio * 0.55, 0.0, 1.0)
	apply_field_velocity_delta(ambient_dir * TRIANGLE_AMBIENT_DRIFT_GAIN * lane_drive * delta)
	_apply_axis_alignment(ambient_dir, TRIANGLE_AMBIENT_ALIGN_GAIN, lane_drive, delta)
	_ambient_debug_mode = "triangle_lane_drift"


func _apply_crescent_ambient_response(delta: float, ambient_dir: Vector2, ambient_strength_ratio: float, calm_grad: Vector2) -> void:
	var aperture_dir: Vector2 = Vector2.LEFT.rotated(rotation)
	var shell_dir: Vector2 = -aperture_dir
	var shelter_bias: float = clampf(shell_dir.dot(ambient_dir), -1.0, 1.0)
	var slip_sign: float = signf(aperture_dir.dot(ambient_dir))
	var slip_dir: Vector2 = ambient_dir.orthogonal() * slip_sign
	var shape_drive: float = ambient_strength_ratio * (0.24 + 0.30 * absf(shelter_bias))
	if shape_drive > 0.001:
		apply_field_velocity_delta(ambient_dir * CRESCENT_AMBIENT_SHAPE_GAIN * 0.45 * shape_drive * delta)
		if slip_dir.length_squared() > 0.000001:
			apply_field_velocity_delta(slip_dir.normalized() * CRESCENT_AMBIENT_SHAPE_GAIN * 0.25 * shape_drive * delta)
		apply_angular_delta(_signed_axis_error(-ambient_dir, aperture_dir) * CRESCENT_AMBIENT_ALIGN_GAIN * shape_drive * delta)
	if calm_grad.length_squared() > 0.000001:
		apply_field_velocity_delta(calm_grad.normalized() * CRESCENT_AMBIENT_SHAPE_GAIN * 0.22 * ambient_strength_ratio * delta)
	_ambient_debug_mode = "crescent_shape_bias"


func ambient_debug_snapshot() -> Dictionary:
	return {
		"vector": _ambient_debug_vector,
		"strength": _ambient_debug_strength,
		"mode": _ambient_debug_mode,
	}


func _round_orbit_sign(tangent: Vector2, flow: Vector2) -> float:
	var orbit_sign: float = sign(flow.dot(tangent))
	if is_zero_approx(orbit_sign):
		orbit_sign = 1.0 if (get_instance_id() & 1) == 0 else -1.0
	return orbit_sign


func _sample_round_magnetic_strength(dish: PetriDish, local_pos: Vector2) -> float:
	if dish == null:
		return 0.0
	# LEGACY NAME: this helper samples the cell-field superposition at the round
	# cell location via PetriDish's compatibility wrapper.
	return dish.sample_cell_field(dish.to_global(local_pos)).length() / maxf(PetriDish.MAG_FIELD_MAX_STRENGTH, 0.001)


func _apply_coil_field_spin(delta: float) -> void:
	# Coil/spiral rotor model. Continuous-time torque proportional to local
	# normalized cell-field strength, with a smoothed direction state so
	# the sign cannot flip on noise, plus an always-on damping so the rotor
	# slows down once it leaves the field instead of coasting forever.
	# No bond/grab logic — this is purely an angular force.
	if signature == null:
		return
	if _canonical_geom() != "spiral":
		return
	var dish: PetriDish = _dish_parent()
	if dish == null:
		angular_velocity *= exp(-COIL_SPIN_DAMPING * delta)
		return
	var strength_ratio: float = _sample_round_magnetic_strength(dish, position)
	# Preferred spin direction is fixed per cell (id parity) so two coils that
	# meet in the same field will counter-rotate. Memory smoothing prevents
	# any frame-to-frame sign flip and gives a graceful ramp on first entry
	# into a field.
	var preferred: float = 1.0 if (get_instance_id() & 1) == 0 else -1.0
	var dir_alpha: float = clampf(COIL_DIRECTION_MEMORY * delta, 0.0, 1.0)
	_coil_dir_state = lerpf(_coil_dir_state, preferred, dir_alpha)
	# Torque proportional to field strength and smoothed direction.
	var torque: float = COIL_FIELD_TORQUE_GAIN * strength_ratio * _coil_dir_state
	angular_velocity += torque * delta
	# Always-on damping so spin has a finite time-constant. Combined with the
	# torque above this gives steady-state ω ≈ (TORQUE_GAIN / SPIN_DAMPING) *
	# strength when the coil sits in a steady field.
	angular_velocity *= exp(-COIL_SPIN_DAMPING * delta)
	angular_velocity = clampf(angular_velocity, -COIL_MAX_ANGULAR_SPEED, COIL_MAX_ANGULAR_SPEED)


func _apply_round_homeostasis(delta: float) -> void:
	if field == null:
		return
	var dish: PetriDish = _dish_parent()
	var depleted: float = round_depletion_factor()
	var healthy: float = round_healthy_factor()
	var over: float = round_overcharge_factor()
	var local_charge: float = field.sample_charge(position)
	var local_noise: float = field.sample_noise(position)
	var local_magnetic: float = _sample_round_magnetic_strength(dish, position)
	var charge_grad: Vector2 = Vector2.ZERO
	var magnetic_grad: Vector2 = Vector2.ZERO
	var noise_push: Vector2 = Vector2.ZERO
	var sample_radius: float = radius + ROUND_GRADIENT_RADIUS
	for i in ROUND_GRADIENT_SAMPLES:
		var ang: float = (float(i) / float(ROUND_GRADIENT_SAMPLES)) * TAU
		var dir: Vector2 = Vector2.RIGHT.rotated(ang)
		var sample_pos: Vector2 = position + dir * sample_radius
		var sample_charge: float = field.sample_charge(sample_pos)
		var sample_noise: float = field.sample_noise(sample_pos)
		var sample_magnetic: float = _sample_round_magnetic_strength(dish, sample_pos)
		charge_grad += dir * (sample_charge - local_charge)
		magnetic_grad += dir * (sample_magnetic - local_magnetic)
		noise_push += dir * maxf(sample_noise - local_noise, 0.0)
	var combined_grad: Vector2 = magnetic_grad * ROUND_MAGNETIC_GRADIENT_WEIGHT + charge_grad * ROUND_CHARGE_GRADIENT_WEIGHT
	var grad_strength: float = combined_grad.length()
	var flow: Vector2 = field.sample_flow(position)
	if depleted > 0.0 and grad_strength > ROUND_GRADIENT_MIN:
		var grad_dir: Vector2 = combined_grad / grad_strength
		var pull: float = ROUND_GRADIENT_GAIN * depleted * clampf(grad_strength * 1.4, 0.0, 1.0)
		apply_field_velocity_delta(grad_dir * pull * delta)
		var tangent: Vector2 = grad_dir.orthogonal()
		var orbit_sign: float = _round_orbit_sign(tangent, flow)
		apply_field_velocity_delta(tangent * orbit_sign * ROUND_ORBIT_GAIN * depleted * clampf(grad_strength * 0.9, 0.0, 1.0) * delta)
		note_seek(0.20 + 0.52 * depleted)
	elif over > 0.0 and grad_strength > ROUND_GRADIENT_MIN * 0.5:
		var repel_dir: Vector2 = combined_grad / grad_strength
		var repel: float = ROUND_GRADIENT_REPEL * over * clampf(grad_strength * 1.2, 0.0, 1.0)
		apply_field_velocity_delta(-repel_dir * repel * delta)
		var tangent: Vector2 = repel_dir.orthogonal()
		apply_field_velocity_delta(tangent * _round_orbit_sign(tangent, flow) * ROUND_OVERCHARGED_ORBIT_GAIN * over * clampf(grad_strength * 0.6, 0.0, 1.0) * delta)
		note_seek(0.14 + 0.28 * over)
	elif healthy > 0.0 and grad_strength > ROUND_GRADIENT_MIN * 1.1:
		var grad_dir: Vector2 = combined_grad / grad_strength
		var tangent: Vector2 = grad_dir.orthogonal()
		apply_field_velocity_delta(tangent * _round_orbit_sign(tangent, flow) * ROUND_HEALTHY_ORBIT_GAIN * healthy * clampf(grad_strength * 0.30, 0.0, 0.35) * delta)
	if healthy > 0.0 and noise_push.length() > ROUND_NOISE_AVOID_MIN:
		apply_field_velocity_delta(-noise_push.normalized() * ROUND_NOISE_AVOID_GAIN * healthy * clampf(noise_push.length() * 0.35, 0.0, 0.45) * delta)
	var brake_mult: float = 0.60 + healthy * 1.05 + over * 0.60
	if depleted > 0.0 and grad_strength > ROUND_GRADIENT_MIN:
		brake_mult = 0.18 + 0.12 * (1.0 - depleted)
	elif over > 0.0 and grad_strength > ROUND_GRADIENT_MIN * 0.5:
		brake_mult = 0.38 + 0.32 * over
	elif grad_strength < ROUND_GRADIENT_MIN:
		brake_mult += 0.35 + depleted * 0.22
	velocity = velocity.lerp(Vector2.ZERO, clampf(ROUND_REST_BRAKE * delta * brake_mult, 0.0, 0.90))
	var spin_mult: float = 0.52 + healthy * 1.00 + over * 0.75
	if depleted > 0.0 and grad_strength > ROUND_GRADIENT_MIN:
		spin_mult = 0.30 + 0.18 * (1.0 - depleted)
	elif grad_strength < ROUND_GRADIENT_MIN:
		spin_mult += 0.20
	angular_velocity = lerpf(angular_velocity, 0.0, clampf(ROUND_SPIN_BRAKE * delta * spin_mult, 0.0, 0.88))


func _canonical_geom() -> String:
	# Internal naming debt: round=Sphere, triangle/wedge=Triangle,
	# spiral=Coil, line=legacy Line, crescent=Crescent.
	if signature.geometry_type == "wedge":
		return "triangle"
	return signature.geometry_type


func _apply_boundary_force(delta: float) -> void:
	var d: float = position.length()
	var soft_edge: float = PetriDish.DISH_RADIUS - radius - BOUNDARY_MARGIN
	if d <= soft_edge or d <= 0.0:
		return
	var penetration: float = d - soft_edge
	var inward: Vector2 = -position / d
	apply_velocity_delta(inward * BOUNDARY_PUSH * penetration * delta)


func _maybe_wedge_impulse(delta: float) -> void:
	if capture_strength > 0.20:
		return
	if signature.charge < signature.charge_capacity * WEDGE_IMPULSE_THRESHOLD:
		return
	var solo: bool = bonded_count == 0
	var guided: float = clampf(seek_strength, 0.0, 1.0)
	var rate_mult: float = 0.35 if solo else 1.0
	var force_mult: float = 0.40 if solo else 1.0
	rate_mult *= 1.0 - guided * 0.35
	force_mult *= 1.0 - guided * 0.20
	var rate: float = WEDGE_IMPULSE_RATE * (0.3 + signature.impulse_bias) * rate_mult
	if randf() >= rate * delta:
		return
	var forward: Vector2 = Vector2(0.0, -1.0).rotated(rotation)
	apply_velocity_delta(forward * WEDGE_IMPULSE_FORCE * (0.5 + signature.impulse_bias) * force_mult)
	signature.charge = maxf(0.0, signature.charge - signature.charge_capacity * WEDGE_IMPULSE_COST)
	dash_pulse = 1.0
	if solo:
		# Solo dash is wasted effort: pay the charge but stir noise instead of finding a target.
		signature.noise = clampf(signature.noise + 0.18, 0.0, NOISE_MAX)


# --- drawing ---

func glow_color() -> Color:
	if signature == null:
		return Color(0.7, 0.8, 1.0, 1.0)
	var charge_ratio: float = charge_ratio_value()
	return _body_color(lerpf(0.55, 1.0, charge_ratio), 1.0)


func _draw() -> void:
	if signature == null:
		return

	var charge_ratio: float = charge_ratio_value()
	var brightness: float = lerpf(0.30, 1.0, charge_ratio)
	var alpha: float = lerpf(0.55, 1.0, charge_ratio)
	if _canonical_geom() == "round":
		if is_round_healthy():
			brightness = maxf(brightness, 0.72 + 0.10 * round_healthy_factor())
			alpha = maxf(alpha, 0.82)
		elif is_round_overcharged():
			brightness = minf(1.08, brightness + 0.10 + 0.10 * round_overcharge_factor())
			alpha = minf(1.0, alpha + 0.06)

	var pulse: float = 1.0 + 0.10 * sin(signature.rhythm_phase) * (0.4 + signature.rhythm_bias)
	var excess_noise: float = maxf(0.0, signature.noise - _baseline_noise)
	var flicker_calm: float = maxf(0.10, 1.0 - float(bonded_count) * BONDED_FLICKER_SUPPRESS)
	if _canonical_geom() == "round" and is_round_healthy():
		flicker_calm *= 0.35
	var jitter: Vector2 = Vector2(_flicker, _flicker * 0.6) * (1.0 + 2.5 * excess_noise) * flicker_calm

	var r: float = radius * pulse

	# Chromatic instability: a faint cyan/magenta double on the same shape
	var chroma: float = clampf(signature.noise * 0.35, 0.0, 0.8)

	var geom: String = signature.geometry_type
	if geom == "wedge":
		geom = "triangle"
	var round_field_ctx: Dictionary = {}
	if geom == "round":
		round_field_ctx = _round_body_field_context()
	match geom:
		"round":
			_draw_round(jitter, r, brightness, alpha, chroma, round_field_ctx)
		"triangle":
			_draw_wedge(jitter, r, brightness, alpha, chroma)
		"spiral":
			_draw_spiral_coil(jitter, r, brightness, alpha, chroma)
		"line":
			_draw_line(jitter, r, brightness, alpha, chroma)
		"crescent":
			_draw_crescent(jitter, r, brightness, alpha, chroma)
		_:
			_draw_round(jitter, r, brightness, alpha, chroma, round_field_ctx)
	# Per-cell polyline plasma halo. Produced a studded / serrated look
	# (evenly spaced sample points with traveling pulse-packet envelopes).
	# Replaced by the dish-level shader-driven LocalPlasmaOverlay; this path
	# is retained as a legacy fallback only.
	if PetriDish.LOCAL_PLASMA_LEGACY_DRAW:
		_draw_local_plasma(jitter, r, charge_ratio, excess_noise, _last_process_delta)

	var cue_axis: Vector2 = Vector2.UP
	if geom == "round" and not round_field_ctx.is_empty():
		cue_axis = (round_field_ctx.get("axis", Vector2.UP) as Vector2).normalized()
		if cue_axis.length_squared() <= 0.000001:
			cue_axis = Vector2.UP
	var cue_perp: Vector2 = Vector2(-cue_axis.y, cue_axis.x)

	# State cues remain, but avoid hard outline rings that fight the cell-field.
	var instability: float = clampf(excess_noise * 1.5, 0.0, 1.0)
	if instability > 0.05:
		draw_circle(Vector2.ZERO, radius * 1.46, Color(1.0, 0.30, 0.45, instability * 0.07))
		draw_circle(cue_axis * radius * 0.12, radius * 1.16, Color(1.0, 0.34, 0.48, instability * 0.05))
	var seek_glow: float = maxf(maxf(seek_strength * 0.35, capture_strength * 0.42), snap_flash * 0.45)
	if seek_glow > 0.03:
		draw_circle(cue_axis * radius * 0.10, radius * 1.12, Color(0.95, 0.98, 1.0, seek_glow * 0.07))
		draw_circle(-cue_axis * radius * 0.08 + cue_perp * radius * 0.05, radius * 0.96, Color(0.88, 0.95, 1.0, seek_glow * 0.04))
	var clash_glow: float = maxf(clash_flash, excess_noise * 0.15)
	if clash_glow > 0.04:
		draw_circle(Vector2.ZERO, radius * 1.28, Color(1.0, 0.48, 0.35, clash_glow * 0.08))
		draw_circle(cue_perp * radius * 0.08, radius * 1.06, Color(1.0, 0.58, 0.40, clash_glow * 0.05))

	# Speckle from noise (tiny dim points around the cell)
	if signature.noise > 0.10:
		var n_speckle: int = int(clampf(signature.noise * 6.0, 1.0, 10.0))
		for _i in n_speckle:
			var ang: float = randf() * TAU
			var rr: float = radius * (0.85 + randf() * 0.5)
			var p: Vector2 = Vector2(cos(ang), sin(ang)) * rr
			draw_circle(p, 0.7, Color(1.0, 0.85, 0.95, 0.30 + randf() * 0.30))

	# Starvation: very dim, dark cool ring
	if charge_ratio < LOW_CHARGE_THRESHOLD:
		var starve: float = 1.0 - (charge_ratio / LOW_CHARGE_THRESHOLD)
		draw_circle(Vector2.ZERO, radius * 1.04, Color(0.10, 0.15, 0.25, starve * 0.08))
		draw_circle(Vector2.ZERO, radius * 0.82, Color(0.03, 0.05, 0.09, starve * 0.12))

	# Overload: warm yellow corona
	if charge_ratio > OVERLOAD_THRESHOLD:
		var over: float = (charge_ratio - OVERLOAD_THRESHOLD) / (1.0 - OVERLOAD_THRESHOLD)
		draw_circle(Vector2.ZERO, radius * 1.22, Color(1.0, 0.85, 0.45, over * 0.10))
		draw_circle(cue_axis * radius * 0.08, radius * 1.05, Color(1.0, 0.78, 0.34, over * 0.08))

	if selected:
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 32, Color(1.0, 0.55, 0.25, 0.85), 1.4, true)

	if debug_ports:
		_draw_ports()


func _draw_ports() -> void:
	for p in ports:
		var anchor: Vector2 = p.local_position
		var tip: Vector2 = anchor + p.local_normal * (3.5 + 3.5 * p.strength)
		var col: Color = ZONE_COLORS.get(p.zone_type, Color(1, 1, 1)) as Color
		col.a = clampf(0.45 + p.strength * 0.4, 0.45, 0.95)
		draw_line(anchor, tip, col, 1.2, true)
		draw_circle(anchor, 2.0, col)


func _body_color(brightness: float, alpha: float) -> Color:
	# Material tints chosen to glow against near-black dish.
	match signature.material_type:
		"pearl":
			return Color(0.78 * brightness, 0.90 * brightness, 1.05 * brightness, alpha)
		"glass":
			return Color(0.55 * brightness, 0.85 * brightness, 1.10 * brightness, alpha * 0.90)
		"soft":
			return Color(1.05 * brightness, 0.70 * brightness, 0.90 * brightness, alpha)
		_:
			return Color(brightness, brightness, brightness, alpha)


func _chroma_pair(base: Color, chroma: float) -> Array:
	# Returns [cyan_offset_color, magenta_offset_color] for chromatic-aberration glow
	var cy: Color = Color(base.r * (1.0 - chroma), base.g, base.b, base.a * 0.55)
	var mg: Color = Color(base.r, base.g * (1.0 - chroma * 0.6), base.b, base.a * 0.55)
	return [cy, mg]


func _local_plasma_context(charge_ratio: float, excess_noise: float, delta: float) -> Dictionary:
	var dish: PetriDish = _dish_parent()
	var total_vec: Vector2 = Vector2.ZERO
	var nearby_bias: Vector2 = Vector2.ZERO
	var nearby_strength: float = 0.0
	var bond_bias: Vector2 = Vector2.ZERO
	var bond_strength: float = 0.0
	if dish != null:
		total_vec = dish.sample_total_field(dish.to_global(position))
		for other in dish.cells:
			if other == self or other == null or other.signature == null:
				continue
			var offset: Vector2 = other.position - position
			var dist: float = offset.length()
			var reach: float = radius + other.radius + 72.0
			if dist <= 0.001 or dist >= reach:
				continue
			var proximity: float = 1.0 - clampf(dist / reach, 0.0, 1.0)
			var weight: float = proximity * (0.30 + 0.70 * other.charge_ratio_value())
			nearby_bias += (offset / dist) * weight
			nearby_strength = maxf(nearby_strength, weight)
		for bond in dish.bonds:
			if bond == null:
				continue
			if bond.a != self and bond.b != self:
				continue
			var bridge_offset: Vector2 = bond.midpoint() - position
			var bridge_dist: float = bridge_offset.length()
			if bridge_dist <= 0.001:
				continue
			var stable: float = clampf((bond.age / 0.8) * (1.0 - clampf(bond.strain, 0.0, 1.0) * 0.6), 0.0, 1.0)
			var weight_bridge: float = (0.35 + bond.strength * 0.50) * (0.45 + stable * 0.55)
			bond_bias += (bridge_offset / bridge_dist) * weight_bridge
			bond_strength = maxf(bond_strength, weight_bridge)
	var total_strength: float = total_vec.length() / maxf(PetriDish.TOTAL_FIELD_MAX_STRENGTH, 0.001)
	var total_dir: Vector2 = Vector2.ZERO if total_vec.length_squared() <= 0.000001 else total_vec.normalized()
	var raw_bias: Vector2 = total_dir * 0.40 + nearby_bias * 0.85 + bond_bias * 1.10
	if raw_bias.length() > 1.0:
		raw_bias = raw_bias.normalized()
	var raw_interaction: float = clampf(total_strength * 0.55 + nearby_strength * 0.65 + bond_strength * 0.75 + seek_strength * 0.20 + capture_strength * 0.35 + excess_noise * 0.12, 0.0, 1.4)
	# Low-pass smoothing keeps the sheath shape from snapping when nearby state
	# changes. Smoothing is on the raw (un-normalized) bias so falling-off
	# neighbors decay continuously instead of leaving a unit vector pointing at
	# nothing. dt-aware lerp coefficient => stable across frame rates.
	var bias_alpha: float = clampf(PLASMA_BIAS_LERP_RATE * delta, 0.0, 1.0)
	var inter_alpha: float = clampf(PLASMA_INTERACTION_LERP_RATE * delta, 0.0, 1.0)
	_plasma_bias_smooth = _plasma_bias_smooth.lerp(raw_bias, bias_alpha)
	_plasma_interaction_smooth = lerpf(_plasma_interaction_smooth, raw_interaction, inter_alpha)
	var bias_dir: Vector2 = Vector2.ZERO
	if _plasma_bias_smooth.length_squared() > 0.000001:
		bias_dir = _plasma_bias_smooth.limit_length(1.0)
	# Phase derives from monotonic accumulated time and the persistent per-cell
	# seed only. Interaction was previously folded into phase, which made the
	# wave packets jump position whenever nearby state shifted; that reads as a
	# restart. Interaction now modulates amplitude in the path drawer, not phase.
	var pulse_phase: float = _plasma_time * LOCAL_PLASMA_PULSE_SPEED + _plasma_seed
	return {
		"bias_dir": bias_dir,
		"interaction": _plasma_interaction_smooth,
		"charge_ratio": charge_ratio,
		"pulse_phase": pulse_phase,
		"excess_noise": excess_noise,
	}


func _round_body_field_context() -> Dictionary:
	var local_axis: Vector2 = Vector2.UP
	var ambient_local: Vector2 = _ambient_debug_vector.rotated(-rotation)
	var ambient_strength: float = clampf(
		_ambient_debug_strength / maxf(PetriDish.AMBIENT_FIELD_STRENGTH, 0.001),
		0.0,
		1.0
	)
	var total_local: Vector2 = ambient_local
	var total_strength: float = ambient_strength
	var neighbor_local: Vector2 = Vector2.ZERO
	var neighbor_strength: float = 0.0
	var dish: PetriDish = _dish_parent()
	if dish != null:
		var total_world: Vector2 = dish.sample_total_field(dish.to_global(position))
		if total_world.length_squared() > 0.000001:
			total_local = total_world.rotated(-rotation)
			total_strength = clampf(
				total_world.length() / maxf(PetriDish.TOTAL_FIELD_MAX_STRENGTH, 0.001),
				0.0,
				1.0
			)
		var neighbor_world: Vector2 = dish._magnetic_interaction_vector(self)
		if neighbor_world.length_squared() > 0.000001:
			neighbor_local = neighbor_world.rotated(-rotation)
			neighbor_strength = dish._magnetic_interaction_activity(self)
	var flow_axis: Vector2 = local_axis
	if total_local.length_squared() > 0.000001:
		flow_axis = flow_axis.lerp(total_local.normalized(), 0.24 + total_strength * 0.24)
	if neighbor_local.length_squared() > 0.000001:
		flow_axis = flow_axis.lerp(neighbor_local.normalized(), 0.16 + neighbor_strength * 0.28)
	if flow_axis.length_squared() <= 0.000001:
		flow_axis = Vector2.UP
	else:
		flow_axis = flow_axis.normalized()
	return {
		"axis": flow_axis,
		"perp": Vector2(-flow_axis.y, flow_axis.x),
		"ambient_strength": ambient_strength,
		"total_strength": total_strength,
		"neighbor_strength": neighbor_strength,
		"phase": _plasma_time * CELL_PLASMA_FLOW_SPEED + _plasma_seed,
	}


func _draw_round_filament_path(points: PackedVector2Array, base_col: Color, alpha_scale: float, pulse_phase: float) -> void:
	if points.size() < 2:
		return
	for i in range(points.size() - 1):
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[i + 1]
		var t0: float = float(i) / float(points.size() - 1)
		var t1: float = float(i + 1) / float(points.size() - 1)
		var mid_t: float = (t0 + t1) * 0.5
		var center_weight: float = pow(maxf(sin(PI * mid_t), 0.0), 0.72)
		var crawl: float = 0.72 + 0.28 * sin(pulse_phase - mid_t * 5.6)
		var glow_w: float = CELL_PLASMA_FILAMENT_GLOW_WIDTH * (0.38 + 0.62 * center_weight)
		var core_w: float = CELL_PLASMA_FILAMENT_WIDTH * (0.52 + 0.48 * center_weight)
		var glow_col: Color = Color(
			minf(1.0, base_col.r * (0.92 + crawl * 0.08)),
			minf(1.0, base_col.g * (0.94 + crawl * 0.06)),
			1.0,
			CELL_PLASMA_FILAMENT_ALPHA * alpha_scale * (0.62 + 0.38 * crawl)
		)
		var core_col: Color = Color(
			minf(1.0, 0.90 + base_col.r * 0.16),
			minf(1.0, 0.95 + base_col.g * 0.08),
			1.0,
			CELL_PLASMA_FILAMENT_ALPHA * alpha_scale * 0.72 * (0.70 + 0.30 * crawl)
		)
		draw_line(p0, p1, glow_col, glow_w, true)
		draw_line(p0, p1, core_col, core_w, true)


func _draw_local_plasma(_jitter: Vector2, r: float, charge_ratio: float, excess_noise: float, delta: float) -> void:
	if not LOCAL_PLASMA_ENABLED or signature == null:
		return
	# When the cell is bonded, the dish-level cluster sheath owns the outer
	# field and renders it as one continuous union shape. Drawing the per-cell
	# sheath on top would re-introduce the "three rings touching" read. Fade
	# this layer out smoothly with bond count instead of cutting it off.
	var bond_fade: float = 1.0 if bonded_count <= 0 else maxf(0.0, 1.0 - float(bonded_count) * 0.85)
	if bond_fade <= 0.005:
		return
	# Plasma path positions are sampled in cell-local coordinates with NO
	# per-frame jitter. The body draw still uses jitter for the cell shape, so
	# the plasma reads as an attached field around the cell rather than a
	# detached randomized halo.
	var origin: Vector2 = Vector2.ZERO
	var context: Dictionary = _local_plasma_context(charge_ratio, excess_noise, delta)
	var base_col: Color = glow_color().lerp(Color(0.94, 0.99, 1.00, 1.0), 0.18)
	var interaction: float = float(context["interaction"])
	var pulse_phase: float = float(context["pulse_phase"])
	var bias_dir: Vector2 = context["bias_dir"] as Vector2
	var alpha_scale: float = (0.52 + 0.48 * charge_ratio) * (1.0 + interaction * LOCAL_PLASMA_INTERACTION_GAIN) * bond_fade
	var geom: String = _canonical_geom()
	match geom:
		"round":
			for band in 2:
				var shell_points: PackedVector2Array = _sample_round_plasma_outline(origin, r, band, bias_dir, interaction, pulse_phase)
				_draw_local_plasma_path(shell_points, base_col, true, alpha_scale, pulse_phase + float(band) * 0.8)
		"triangle":
			for band in 2:
				var tri_points: PackedVector2Array = _sample_triangle_plasma_outline(origin, r, band, bias_dir, interaction, pulse_phase)
				_draw_local_plasma_path(tri_points, base_col, true, alpha_scale * 0.92, pulse_phase + float(band) * 0.6)
		"crescent":
			var outer_points: PackedVector2Array = _sample_crescent_plasma_arc(origin, r * 1.14, bias_dir, interaction, pulse_phase, false)
			var inner_points: PackedVector2Array = _sample_crescent_plasma_arc(origin, r * 0.88, bias_dir, interaction, pulse_phase + 0.9, true)
			_draw_local_plasma_path(outer_points, base_col, false, alpha_scale, pulse_phase)
			_draw_local_plasma_path(inner_points, base_col.lerp(Color(1.0, 0.92, 1.0, 1.0), 0.12), false, alpha_scale * 0.82, pulse_phase + 0.9)
		"spiral":
			for band in 2:
				var coil_points: PackedVector2Array = _sample_capsule_plasma_outline(origin, Vector2(r * (0.88 + band * 0.10), r * (1.28 + band * 0.12)), bias_dir, interaction, pulse_phase + float(band) * 0.7)
				_draw_local_plasma_path(coil_points, base_col, true, alpha_scale * 0.95, pulse_phase + float(band) * 0.7)
		"line":
			var line_points: PackedVector2Array = _sample_capsule_plasma_outline(origin, Vector2(r * 0.56, r * 1.46), bias_dir, interaction, pulse_phase)
			_draw_local_plasma_path(line_points, base_col, true, alpha_scale * 0.84, pulse_phase)


func _draw_local_plasma_path(points: PackedVector2Array, base_col: Color, closed: bool, alpha_scale: float, pulse_phase: float) -> void:
	if points.size() < 2:
		return
	var limit: int = points.size() if closed else points.size() - 1
	for i in range(limit):
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[(i + 1) % points.size()]
		var mid_t: float = (float(i) + 0.5) / float(maxi(limit, 1))
		var envelope: float = 0.55 + 0.45 * pow(maxf(sin(PI * mid_t), 0.0), 0.7)
		var pulse_head: float = 0.5 + 0.28 * sin(pulse_phase)
		var pulse_tail: float = 0.5 + 0.24 * sin(pulse_phase + 1.6)
		var packet_a: float = exp(-pow((mid_t - pulse_head) / 0.18, 2.0))
		var packet_b: float = exp(-pow((mid_t - pulse_tail) / 0.22, 2.0))
		var packet_mix: float = maxf(packet_a, packet_b)
		var glow_w: float = LOCAL_PLASMA_GLOW_WIDTH * LOCAL_PLASMA_THICKNESS_GAIN * envelope
		var core_w: float = LOCAL_PLASMA_CORE_WIDTH * LOCAL_PLASMA_THICKNESS_GAIN * envelope
		var glow_col: Color = Color(
			minf(1.0, base_col.r * (0.92 + packet_mix * 0.08) * LOCAL_PLASMA_BRIGHTNESS_GAIN),
			minf(1.0, base_col.g * (0.94 + packet_mix * 0.06) * LOCAL_PLASMA_BRIGHTNESS_GAIN),
			1.0,
			LOCAL_PLASMA_GLOW_ALPHA * alpha_scale * (0.75 + packet_mix * LOCAL_PLASMA_PULSE_GAIN)
		)
		var core_col: Color = Color(
			minf(1.0, 0.90 + base_col.r * 0.18),
			minf(1.0, 0.95 + base_col.g * 0.08),
			1.0,
			LOCAL_PLASMA_CORE_ALPHA * alpha_scale * (0.82 + packet_mix * LOCAL_PLASMA_PULSE_GAIN)
		)
		draw_line(p0, p1, glow_col, glow_w, true)
		draw_line(p0, p1, core_col, core_w, true)


func _sample_round_plasma_outline(jitter: Vector2, r: float, band: int, bias_dir: Vector2, interaction: float, pulse_phase: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var base_scale: float = 1.10 + float(band) * 0.10
	for i in range(42):
		var ang: float = (float(i) / 42.0) * TAU
		var normal: Vector2 = Vector2(cos(ang), sin(ang))
		var tangent: Vector2 = Vector2(-normal.y, normal.x)
		var directional: float = normal.dot(bias_dir)
		var side_flow: float = tangent.dot(bias_dir)
		var wave: float = sin(ang * 2.0 + pulse_phase + float(band) * 0.9)
		var radial: float = r * base_scale
		radial += r * directional * LOCAL_PLASMA_DISTORTION_GAIN * interaction * 0.20
		radial += r * wave * (0.020 + interaction * 0.020)
		points.append(jitter + normal * radial + tangent * r * side_flow * interaction * 0.035)
	return points


func _sample_triangle_plasma_outline(jitter: Vector2, r: float, band: int, bias_dir: Vector2, interaction: float, pulse_phase: float) -> PackedVector2Array:
	var tip: Vector2 = Vector2(0.0, -r * 1.24)
	var base_r: Vector2 = Vector2(r * 1.02, r * 0.92)
	var base_l: Vector2 = Vector2(-r * 1.02, r * 0.92)
	var verts: Array[Vector2] = [tip, base_r, base_l]
	var points: PackedVector2Array = PackedVector2Array()
	for edge_idx in range(verts.size()):
		var a: Vector2 = verts[edge_idx]
		var b: Vector2 = verts[(edge_idx + 1) % verts.size()]
		for seg in range(8):
			var t: float = float(seg) / 8.0
			var point: Vector2 = a.lerp(b, t)
			var outward: Vector2 = point.normalized()
			var tangent: Vector2 = Vector2(-outward.y, outward.x)
			var directional: float = outward.dot(bias_dir)
			var wave: float = sin((float(edge_idx) + t) * TAU + pulse_phase + float(band) * 0.7)
			var inflate: float = r * (0.18 + float(band) * 0.06)
			inflate += r * directional * LOCAL_PLASMA_DISTORTION_GAIN * interaction * 0.16
			points.append(jitter + point + outward * inflate + tangent * wave * r * 0.025 * (0.4 + interaction))
	return points


func _sample_capsule_plasma_outline(jitter: Vector2, extents: Vector2, bias_dir: Vector2, interaction: float, pulse_phase: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(36):
		var ang: float = (float(i) / 36.0) * TAU
		var normal: Vector2 = Vector2(cos(ang), sin(ang))
		var tangent: Vector2 = Vector2(-normal.y, normal.x)
		var directional: float = normal.dot(bias_dir)
		var wave: float = sin(ang * 3.0 + pulse_phase)
		var p: Vector2 = Vector2(normal.x * extents.x, normal.y * extents.y)
		var distort: Vector2 = normal * extents.y * directional * LOCAL_PLASMA_DISTORTION_GAIN * interaction * 0.14
		p += distort + tangent * extents.x * wave * 0.06 * (0.35 + interaction)
		points.append(jitter + p)
	return points


func _sample_crescent_plasma_arc(jitter: Vector2, radius_value: float, bias_dir: Vector2, interaction: float, pulse_phase: float, inner: bool) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var a_start: float = -PI * (0.82 if inner else 0.88)
	var a_end: float = PI * (0.82 if inner else 0.88)
	for i in range(26):
		var t: float = float(i) / 25.0
		var ang: float = lerpf(a_start, a_end, t)
		var normal: Vector2 = Vector2(cos(ang), sin(ang))
		var tangent: Vector2 = Vector2(-sin(ang), cos(ang))
		if inner:
			normal = -normal
		var directional: float = normal.dot(bias_dir)
		var wave: float = sin(t * TAU * 1.4 + pulse_phase)
		var radial: float = radius_value + radius_value * directional * LOCAL_PLASMA_DISTORTION_GAIN * interaction * 0.12
		var point: Vector2 = Vector2(cos(ang), sin(ang)) * radial
		point += tangent * wave * radius_value * 0.035 * (0.35 + interaction)
		points.append(jitter + point)
	return points


# ROUND: contained plasma orb — bright core, soft sheath, internal field filaments.
func _draw_round(offset: Vector2, r: float, brightness: float, alpha: float, chroma: float, field_ctx: Dictionary) -> void:
	var col: Color = _body_color(brightness, alpha)
	var healthy: float = round_healthy_factor()
	var over: float = round_overcharge_factor()
	var noisy: float = clampf(round_noise_excess(), 0.0, 1.0)
	var axis: Vector2 = (field_ctx.get("axis", Vector2.UP) as Vector2).normalized()
	if axis.length_squared() <= 0.000001:
		axis = Vector2.UP
	var perp: Vector2 = field_ctx.get("perp", Vector2.RIGHT) as Vector2
	var ambient_strength: float = float(field_ctx.get("ambient_strength", 0.0))
	var total_strength: float = float(field_ctx.get("total_strength", ambient_strength))
	var neighbor_strength: float = float(field_ctx.get("neighbor_strength", 0.0))
	var plasma_phase: float = float(field_ctx.get("phase", _plasma_time * CELL_PLASMA_FLOW_SPEED + _plasma_seed))
	var core_shift: Vector2 = axis * (sin(plasma_phase * 0.78) * r * CELL_PLASMA_WARP_STRENGTH * 0.10)
	core_shift += perp * (cos(plasma_phase * 0.58 + 0.6) * r * CELL_PLASMA_WARP_STRENGTH * 0.07)
	# Outer atmospheric halo (kept soft so the orb remains discrete).
	for i in 2:
		var t_halo: float = float(i) / 2.0
		var halo_r: float = r * (1.10 + t_halo * 0.22)
		var halo_alpha: float = alpha * (0.07 - t_halo * 0.03) * (0.70 + total_strength * 0.25)
		draw_circle(offset, halo_r, Color(col.r, col.g, col.b, halo_alpha))
	# Chromatic split when noisy
	if chroma > 0.05:
		var pair: Array = _chroma_pair(col, chroma)
		draw_circle(offset + Vector2(chroma * 1.2, 0.0), r * 0.96, Color(pair[0].r, pair[0].g, pair[0].b, pair[0].a * 0.12))
		draw_circle(offset - Vector2(chroma * 1.2, 0.0), r * 0.96, Color(pair[1].r, pair[1].g, pair[1].b, pair[1].a * 0.12))
	# Inner plasma core buildup with slow field-aware drift.
	for i in 5:
		var t: float = float(i) / 5.0
		var inner_r: float = r * (0.98 - t * 0.66)
		var layer_shift: Vector2 = core_shift * (0.12 + t * 0.28)
		var inner: Color = Color(
			lerpf(col.r, 1.0, (0.28 + t * 0.50) * CELL_PLASMA_CORE_BRIGHTNESS * 0.72),
			lerpf(col.g, 1.0, (0.34 + t * 0.46) * CELL_PLASMA_CORE_BRIGHTNESS * 0.76),
			lerpf(col.b, 1.0, (0.42 + t * 0.42) * CELL_PLASMA_CORE_BRIGHTNESS * 0.82),
			alpha * (0.14 + t * 0.22) * (0.78 + total_strength * 0.22),
		)
		if healthy > 0.0:
			inner.r = lerpf(inner.r, 0.95, healthy * 0.18)
			inner.g = lerpf(inner.g, 0.98, healthy * 0.24)
			inner.b = lerpf(inner.b, 1.0, healthy * 0.24)
			inner.a += healthy * 0.06
		draw_circle(offset + layer_shift, inner_r, inner)
	# Internal contained filaments: live inside the orb and follow field bias.
	var filament_count: int = CELL_PLASMA_FILAMENT_COUNT
	for idx in range(filament_count):
		var lane: float = 0.0
		if filament_count > 1:
			lane = lerpf(-1.0, 1.0, float(idx) / float(filament_count - 1))
		var points: PackedVector2Array = PackedVector2Array()
		var samples: int = 13
		for s in range(samples):
			var u: float = float(s) / float(samples - 1)
			var x_n: float = lerpf(-0.72, 0.72, u)
			var span: float = sqrt(maxf(0.0, 1.0 - x_n * x_n))
			var lane_span: float = span * (0.96 - absf(lane) * 0.14)
			var wave_a: float = sin(plasma_phase + u * TAU * 1.20 + lane * 1.6)
			var wave_b: float = cos(plasma_phase * 0.66 + u * TAU * 0.86 - lane * 1.1)
			var x_warp: float = x_n + wave_b * 0.05 * neighbor_strength * lane_span
			var y_n: float = lane * (0.20 + 0.10 * absf(lane)) * lane_span
			y_n += wave_a * 0.085 * (0.35 + total_strength * 0.65) * lane_span
			y_n += wave_b * 0.045 * (0.40 + ambient_strength * 0.60) * lane_span
			var local: Vector2 = axis * (x_warp * r * 0.78) + perp * (y_n * r * 0.92)
			points.append(offset + local)
		var filament_col: Color = col.lerp(Color(0.96, 0.99, 1.0, 1.0), 0.34 + total_strength * 0.18)
		var filament_alpha: float = alpha * (0.76 + total_strength * 0.20) * (0.86 - absf(lane) * 0.14)
		_draw_round_filament_path(points, filament_col, filament_alpha, plasma_phase + lane * 0.9)
	# Thin luminous sheath: full soft band plus brighter field-biased highlights.
	var sheath_width: float = maxf(0.9, r * CELL_PLASMA_SHEATH_WIDTH * 0.34)
	var sheath_base: Color = Color(0.82 + col.r * 0.18, 0.90 + col.g * 0.10, 1.0, alpha * 0.20 * CELL_PLASMA_SHEATH_BRIGHTNESS)
	draw_arc(offset, r * 0.985, 0.0, TAU, 42, sheath_base, sheath_width, true)
	var sheath_angle: float = axis.angle()
	var highlight_col: Color = Color(0.95, 0.99, 1.0, alpha * (0.22 + total_strength * 0.12) * CELL_PLASMA_SHEATH_BRIGHTNESS)
	draw_arc(offset, r * 0.99, sheath_angle - 0.92, sheath_angle + 0.92, 18, highlight_col, sheath_width * 1.28, true)
	draw_arc(offset, r * 0.985, sheath_angle + PI - 0.64, sheath_angle + PI + 0.64, 14, Color(0.78, 0.92, 1.0, alpha * (0.12 + neighbor_strength * 0.10) * CELL_PLASMA_SHEATH_BRIGHTNESS), sheath_width, true)
	if over > 0.0:
		draw_circle(offset, r * 1.02, Color(1.0, 0.84, 0.54, alpha * (0.05 + over * 0.08)))
	if noisy > 0.04:
		draw_circle(offset + core_shift * 1.4, r * 0.92, Color(1.0, 0.66, 0.76, noisy * 0.05))
	# Specular/plasma node highlight.
	var spec: Vector2 = offset + Vector2(-r * 0.34, -r * 0.36) + core_shift * 0.55
	draw_circle(spec, r * 0.14, Color(1.0, 1.0, 1.0, alpha * 0.42))
	draw_circle(spec, r * 0.24, Color(1.0, 1.0, 1.0, alpha * 0.08))


# WEDGE/TRIANGLE: sharp translucent shell with one bright cutting edge
func _draw_wedge(offset: Vector2, r: float, brightness: float, alpha: float, chroma: float) -> void:
	var col: Color = _body_color(brightness, alpha)
	var tip: Vector2 = offset + Vector2(0, -r * 1.20)
	var base_r: Vector2 = offset + Vector2(r * 0.95, r * 0.85)
	var base_l: Vector2 = offset + Vector2(-r * 0.95, r * 0.85)
	# Translucent body
	var body_col: Color = Color(col.r, col.g, col.b, alpha * 0.22)
	draw_colored_polygon(PackedVector2Array([tip, base_r, base_l]), body_col)
	# Inner faint glow polygon (smaller, brighter)
	var inset: float = 0.6
	var t2: Vector2 = offset + Vector2(0, -r * 1.20 * inset)
	var br2: Vector2 = offset + Vector2(r * 0.95 * inset, r * 0.85 * inset)
	var bl2: Vector2 = offset + Vector2(-r * 0.95 * inset, r * 0.85 * inset)
	draw_colored_polygon(PackedVector2Array([t2, br2, bl2]), Color(col.r, col.g, col.b, alpha * 0.18))
	# Bright cutting edge: left flank (tip → base_l)
	var edge_col: Color = Color(lerpf(col.r, 1.0, 0.4), lerpf(col.g, 1.0, 0.4), lerpf(col.b, 1.0, 0.4), alpha * 0.95)
	draw_line(tip, base_l, edge_col, 1.6, true)
	# Dim back edges
	var dim: Color = Color(col.r, col.g, col.b, alpha * 0.45)
	draw_line(tip, base_r, dim, 0.9, true)
	draw_line(base_l, base_r, dim, 0.9, true)
	# Chromatic split on cutting edge when noisy
	if chroma > 0.05:
		var pair: Array = _chroma_pair(edge_col, chroma)
		draw_line(tip + Vector2(chroma * 2.0, 0), base_l + Vector2(chroma * 2.0, 0), pair[0], 1.0, true)
		draw_line(tip - Vector2(chroma * 2.0, 0), base_l - Vector2(chroma * 2.0, 0), pair[1], 1.0, true)
	# Bright tip kernel
	draw_circle(tip, r * 0.16, Color(1.0, 0.97, 0.85, alpha * 0.75))
	draw_circle(tip, r * 0.28, Color(1.0, 0.95, 0.80, alpha * 0.20))


# SPIRAL: side-view coil — stacked flattened ellipses along the cell's local Y axis with
# alternating brightness for depth. Phase-modulated by rhythm_phase.
func _draw_spiral_coil(offset: Vector2, r: float, brightness: float, alpha: float, chroma: float) -> void:
	var col: Color = _body_color(brightness, alpha)
	var loops: int = 5
	var total_h: float = r * 1.85
	var loop_w: float = r * 0.95
	var ellipse_h: float = r * 0.22
	for i in loops:
		var t: float = float(i) / float(loops - 1)
		var y: float = lerpf(-total_h * 0.5, total_h * 0.5, t) + offset.y
		var center: Vector2 = Vector2(offset.x, y)
		# Alternate brightness: front-facing loops brighter, back-facing dimmer
		var depth_phase: float = sin(signature.rhythm_phase + t * PI)
		var bright_factor: float = 0.55 + 0.45 * (1.0 if (i % 2 == 0) else -1.0) * sign(depth_phase + 0.001)
		bright_factor = clampf(bright_factor, 0.30, 1.0)
		var loop_col: Color = Color(
			lerpf(col.r, 1.0, bright_factor * 0.35),
			lerpf(col.g, 1.0, bright_factor * 0.35),
			lerpf(col.b, 1.0, bright_factor * 0.35),
			alpha * (0.40 + 0.55 * bright_factor),
		)
		# Build flattened ellipse polyline
		var pts: PackedVector2Array = PackedVector2Array()
		var steps: int = 18
		for k in range(steps + 1):
			var ang: float = (float(k) / float(steps)) * TAU
			pts.append(Vector2(center.x + cos(ang) * loop_w * 0.5, center.y + sin(ang) * ellipse_h))
		draw_polyline(pts, loop_col, 1.3, true)
		# Bright caps at the ends of each loop (the rim catching light)
		var cap_l: Vector2 = Vector2(center.x - loop_w * 0.5, center.y)
		var cap_r: Vector2 = Vector2(center.x + loop_w * 0.5, center.y)
		var cap_col: Color = Color(loop_col.r, loop_col.g, loop_col.b, alpha * 0.85)
		draw_circle(cap_l, 1.4, cap_col)
		draw_circle(cap_r, 1.4, cap_col)
	# Soft outer halo around whole coil
	var halo_col: Color = Color(col.r, col.g, col.b, alpha * 0.10)
	draw_circle(offset, r * 1.15, halo_col)


# LINE: glowing filament/rod, brighter at ends. Drawn along local Y so cell rotation orients it.
func _draw_line(offset: Vector2, r: float, brightness: float, alpha: float, chroma: float) -> void:
	# LEGACY_LINE_CELL_PATH: preserved until plasma bridge replacement exists.
	var col: Color = _body_color(brightness, alpha)
	var half_len: float = r * 1.2
	var a_end: Vector2 = offset + Vector2(0, -half_len)
	var b_end: Vector2 = offset + Vector2(0, half_len)
	# Outer halo strip
	draw_line(a_end, b_end, Color(col.r, col.g, col.b, alpha * 0.18), 6.0, true)
	# Mid line
	draw_line(a_end, b_end, Color(col.r, col.g, col.b, alpha * 0.55), 1.6, true)
	# Chromatic split when noisy
	if chroma > 0.05:
		var pair: Array = _chroma_pair(col, chroma)
		draw_line(a_end + Vector2(chroma * 2.0, 0), b_end + Vector2(chroma * 2.0, 0), pair[0], 1.0, true)
		draw_line(a_end - Vector2(chroma * 2.0, 0), b_end - Vector2(chroma * 2.0, 0), pair[1], 1.0, true)
	# Bright end caps with halo
	for end in [a_end, b_end]:
		draw_circle(end, r * 0.45, Color(col.r, col.g, col.b, alpha * 0.20))
		draw_circle(end, r * 0.22, Color(1.0, 1.0, 1.0, alpha * 0.85))


# CRESCENT: curved shell with glow on inner curve.
func _draw_crescent(offset: Vector2, r: float, brightness: float, alpha: float, chroma: float) -> void:
	var col: Color = _body_color(brightness, alpha)
	# Crescent opens to the right (local +X). Outer curve from upper-left through bottom to lower-left.
	var a_start: float = -PI * 0.85
	var a_end_arc: float = PI * 0.85
	# Outer dim hull
	draw_arc(offset, r, a_start, a_end_arc, 36, Color(col.r, col.g, col.b, alpha * 0.55), 2.2, true)
	# Bright inner curve (slightly smaller radius, opposite side)
	var inner_r: float = r * 0.72
	var inner_col: Color = Color(lerpf(col.r, 1.0, 0.35), lerpf(col.g, 1.0, 0.35), lerpf(col.b, 1.0, 0.35), alpha * 0.80)
	draw_arc(offset, inner_r, a_start * 0.85, a_end_arc * 0.85, 30, inner_col, 1.4, true)
	# Faint glow along inner curve
	draw_arc(offset, inner_r * 0.92, a_start * 0.7, a_end_arc * 0.7, 24, Color(inner_col.r, inner_col.g, inner_col.b, alpha * 0.30), 3.0, true)
	# Outer halo
	draw_arc(offset, r * 1.10, a_start, a_end_arc, 36, Color(col.r, col.g, col.b, alpha * 0.18), 4.0, true)
	# Chromatic split on inner curve when noisy
	if chroma > 0.05:
		var pair: Array = _chroma_pair(inner_col, chroma)
		draw_arc(offset + Vector2(chroma * 2.5, 0), inner_r, a_start * 0.85, a_end_arc * 0.85, 24, pair[0], 1.0, true)
		draw_arc(offset - Vector2(chroma * 2.5, 0), inner_r, a_start * 0.85, a_end_arc * 0.85, 24, pair[1], 1.0, true)
