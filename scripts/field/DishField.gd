extends RefCounted
class_name DishField

const FieldSampleType = preload("res://scripts/field/FieldSample.gd")

const DEFAULT_BREATH_FREQUENCY_A := Vector2(0.010, 0.013)
const DEFAULT_BREATH_FREQUENCY_B := Vector2(-0.007, 0.009)
const DEFAULT_HUM_FREQUENCY_A := Vector2(0.039, -0.035)
const DEFAULT_HUM_FREQUENCY_B := Vector2(-0.054, 0.046)
const DEFAULT_HUM_ENVELOPE_FREQUENCY := Vector2(0.006, -0.005)
const BASE_COHERENCE: float = 0.9
const BASE_TURBULENCE: float = 0.08
const MAX_GRADIENT_TURBULENCE: float = 0.22
const DEFAULT_BREATH_WAVE_WEIGHTS := Vector2(0.6, 0.4)
const DEFAULT_HUM_WAVE_WEIGHTS := Vector2(0.55, 0.45)
const DEFAULT_HUM_ENVELOPE_SHAPE := Vector2(0.66, 0.34)
const DEFAULT_HUM_HEIGHT_SCALE: float = 0.24
const DEFAULT_HUM_CHARGE_SCALE: float = 0.045
const DEFAULT_HUM_TURBULENCE_SCALE: float = 0.04
const DEFAULT_BREATH_GRADIENT_SCALE: float = 4.2
const DEFAULT_FLOW_STRENGTH_SCALE: float = 0.16
const DEFAULT_FLOW_HUM_SCALE: float = 0.62
const DEFAULT_FLOW_VORTICITY_SCALE: float = 0.42
const DEFAULT_WALL_WAVE_REACH_RATIO: float = 0.62
const DEFAULT_WALL_WAVE_FREQUENCY: float = 0.036
const DEFAULT_WALL_WAVE_SPEED: float = 1.26
const DEFAULT_WALL_WAVE_SHARPNESS: float = 1.6
const DEFAULT_WALL_WAVE_HEIGHT_STRENGTH: float = 1.05
const DEFAULT_WALL_WAVE_PUSH_STRENGTH: float = 0.96
const DEFAULT_WALL_WAVE_SWIRL_STRENGTH: float = 0.12
const DEFAULT_WALL_WAVE_SWIRL_SPEED: float = 0.34

# Internal field doctrine:
# - height usually lives around -55..12 with the current primordial well scale.
# - gradient is a local pull vector; magnitudes are intended to stay near 0..1.
# - charge is normalized to -1..1.
# - coherence and turbulence are normalized to 0..1.
var dish_radius: float
var base_pulse_speed: float
var base_pulse_strength: float
var time: float = 0.0
var contributors: Array = []
var breath_frequency_a: Vector2 = DEFAULT_BREATH_FREQUENCY_A
var breath_frequency_b: Vector2 = DEFAULT_BREATH_FREQUENCY_B
var hum_frequency_a: Vector2 = DEFAULT_HUM_FREQUENCY_A
var hum_frequency_b: Vector2 = DEFAULT_HUM_FREQUENCY_B
var hum_envelope_frequency: Vector2 = DEFAULT_HUM_ENVELOPE_FREQUENCY
var breath_wave_weights: Vector2 = DEFAULT_BREATH_WAVE_WEIGHTS
var hum_wave_weights: Vector2 = DEFAULT_HUM_WAVE_WEIGHTS
var hum_envelope_shape: Vector2 = DEFAULT_HUM_ENVELOPE_SHAPE
var hum_height_scale: float = DEFAULT_HUM_HEIGHT_SCALE
var hum_charge_scale: float = DEFAULT_HUM_CHARGE_SCALE
var hum_turbulence_scale: float = DEFAULT_HUM_TURBULENCE_SCALE
var breath_gradient_scale: float = DEFAULT_BREATH_GRADIENT_SCALE
var flow_strength_scale: float = DEFAULT_FLOW_STRENGTH_SCALE
var flow_hum_scale: float = DEFAULT_FLOW_HUM_SCALE
var flow_vorticity_scale: float = DEFAULT_FLOW_VORTICITY_SCALE
var wall_wave_reach_ratio: float = DEFAULT_WALL_WAVE_REACH_RATIO
var wall_wave_frequency: float = DEFAULT_WALL_WAVE_FREQUENCY
var wall_wave_speed: float = DEFAULT_WALL_WAVE_SPEED
var wall_wave_sharpness: float = DEFAULT_WALL_WAVE_SHARPNESS
var wall_wave_height_strength: float = DEFAULT_WALL_WAVE_HEIGHT_STRENGTH
var wall_wave_push_strength: float = DEFAULT_WALL_WAVE_PUSH_STRENGTH
var wall_wave_swirl_strength: float = DEFAULT_WALL_WAVE_SWIRL_STRENGTH
var wall_wave_swirl_speed: float = DEFAULT_WALL_WAVE_SWIRL_SPEED


func _init(
	initial_dish_radius: float = 1140.0,
	initial_pulse_speed: float = 0.35,
	initial_pulse_strength: float = 3.2
) -> void:
	dish_radius = initial_dish_radius
	base_pulse_speed = initial_pulse_speed
	base_pulse_strength = initial_pulse_strength


func advance(delta: float) -> void:
	time += delta


func add_contributor(contributor: Object) -> void:
	# Future sphere cells, arcs, bonds, and group fields all enter the substrate through this seam.
	if contributor != null:
		contributors.append(contributor)


func remove_contributor(contributor: Object) -> void:
	if contributor != null:
		contributors.erase(contributor)


func sample(world_position: Vector2) -> FieldSampleType:
	var field_sample: FieldSampleType = FieldSampleType.new()
	sample_into(world_position, field_sample)
	return field_sample


func sample_into(world_position: Vector2, out_sample: FieldSampleType) -> void:
	var sample_position := clamp_to_dish(world_position)
	var hum: float = _sample_substrate_hum(sample_position)
	var hum_abs: float = absf(hum)
	var base_gradient: Vector2 = _sample_base_gradient(sample_position)
	var boundary_height: float = _sample_boundary_wave_height(sample_position)
	var boundary_gradient: Vector2 = _sample_boundary_wave_gradient(sample_position)
	var boundary_flow: Vector2 = _sample_boundary_wave_flow(sample_position)

	out_sample.height = _sample_base_height(sample_position) + boundary_height
	out_sample.gradient = base_gradient + boundary_gradient
	out_sample.flow = _sample_base_flow(sample_position, base_gradient) + boundary_flow
	out_sample.charge = hum * _sample_radial_presence(sample_position) * hum_charge_scale
	out_sample.coherence = BASE_COHERENCE - hum_abs * 0.04
	out_sample.turbulence = BASE_TURBULENCE + hum_abs * hum_turbulence_scale

	for contributor_variant in _get_relevant_contributors(sample_position):
		var contributor: Object = contributor_variant
		if contributor != null and contributor.has_method("contribute_to_sample"):
			contributor.contribute_to_sample(sample_position, out_sample)

	var gradient_energy: float = out_sample.gradient.length()
	var flow_energy: float = out_sample.flow.length()
	out_sample.turbulence += clampf(gradient_energy * 0.09 + flow_energy * 0.06, 0.0, MAX_GRADIENT_TURBULENCE)
	out_sample.coherence = clampf(out_sample.coherence - out_sample.turbulence * 0.08, 0.0, 1.0)
	out_sample.charge = clampf(out_sample.charge, -1.0, 1.0)
	out_sample.turbulence = clampf(out_sample.turbulence, 0.0, 1.0)


func sample_flow_at(world_position: Vector2) -> Vector2:
	var field_sample: FieldSampleType = FieldSampleType.new()
	sample_into(world_position, field_sample)
	return field_sample.flow


func is_inside_dish(world_position: Vector2) -> bool:
	return world_position.length_squared() <= dish_radius * dish_radius


func clamp_to_dish(world_position: Vector2) -> Vector2:
	if is_inside_dish(world_position):
		return world_position

	var distance := world_position.length()
	if distance <= 0.0001:
		return Vector2.ZERO

	return (world_position / distance) * dish_radius


func _sample_base_height(world_position: Vector2) -> float:
	var phase_a := world_position.dot(breath_frequency_a) + time * base_pulse_speed
	var phase_b := world_position.dot(breath_frequency_b) - time * base_pulse_speed * 0.73
	var breath: float = (sin(phase_a) * breath_wave_weights.x) + (sin(phase_b) * breath_wave_weights.y)
	return (base_pulse_strength * breath) + (base_pulse_strength * hum_height_scale * _sample_substrate_hum(world_position))


func _sample_base_gradient(world_position: Vector2) -> Vector2:
	var phase_a := world_position.dot(breath_frequency_a) + time * base_pulse_speed
	var phase_b := world_position.dot(breath_frequency_b) - time * base_pulse_speed * 0.73
	var breath_slope: Vector2 = (
		breath_frequency_a * cos(phase_a) * breath_wave_weights.x
	) + (
		breath_frequency_b * cos(phase_b) * breath_wave_weights.y
	)

	var hum_phase_a := world_position.dot(hum_frequency_a) - time * (base_pulse_speed * 3.8 + 0.72)
	var hum_phase_b := world_position.dot(hum_frequency_b) + time * (base_pulse_speed * 4.4 + 1.06)
	var envelope_phase := world_position.dot(hum_envelope_frequency) - time * (base_pulse_speed * 0.32 + 0.09)
	var hum_wave: float = (sin(hum_phase_a) * hum_wave_weights.x) + (sin(hum_phase_b) * hum_wave_weights.y)
	var hum_envelope: float = hum_envelope_shape.x + (sin(envelope_phase) * hum_envelope_shape.y)
	var hum_slope: Vector2 = (
		hum_envelope * (
			(hum_frequency_a * cos(hum_phase_a) * hum_wave_weights.x)
			+ (hum_frequency_b * cos(hum_phase_b) * hum_wave_weights.y)
		)
	) + (
		hum_wave * hum_envelope_frequency * cos(envelope_phase) * hum_envelope_shape.y
	)

	return (breath_slope + (hum_slope * hum_height_scale)) * base_pulse_strength * breath_gradient_scale


func _sample_base_flow(world_position: Vector2, base_gradient: Vector2) -> Vector2:
	var phase_a := world_position.dot(breath_frequency_a) + time * base_pulse_speed
	var phase_b := world_position.dot(breath_frequency_b) - time * base_pulse_speed * 0.73
	var breath_drive: Vector2 = (
		_safe_normalized(breath_frequency_a) * ((sin(phase_a) * 0.5) + 0.5) * breath_wave_weights.x
	) + (
		_safe_normalized(breath_frequency_b) * ((sin(phase_b) * 0.5) + 0.5) * breath_wave_weights.y
	)

	var hum_phase_a := world_position.dot(hum_frequency_a) - time * (base_pulse_speed * 3.8 + 0.72)
	var hum_phase_b := world_position.dot(hum_frequency_b) + time * (base_pulse_speed * 4.4 + 1.06)
	var envelope_phase := world_position.dot(hum_envelope_frequency) - time * (base_pulse_speed * 0.32 + 0.09)
	var hum_envelope: float = hum_envelope_shape.x + (sin(envelope_phase) * hum_envelope_shape.y)
	var hum_drive: Vector2 = (
		_safe_normalized(hum_frequency_a) * ((sin(hum_phase_a) * 0.5) + 0.5) * hum_wave_weights.x
	) + (
		_safe_normalized(hum_frequency_b) * ((sin(hum_phase_b) * 0.5) + 0.5) * hum_wave_weights.y
	)

	var vortical_flow := Vector2(-base_gradient.y, base_gradient.x)

	return (
		breath_drive
		+ hum_drive * hum_envelope * flow_hum_scale
		+ vortical_flow * flow_vorticity_scale
	) * base_pulse_strength * flow_strength_scale


func _sample_boundary_wave_height(world_position: Vector2) -> float:
	var inward: Vector2 = _safe_inward(world_position)
	if inward == Vector2.ZERO:
		return 0.0

	var distance_to_wall: float = maxf(dish_radius - world_position.length(), 0.0)
	var reach: float = _wall_wave_reach()
	var wall_band: float = _wall_wave_band(distance_to_wall, reach)
	if wall_band <= 0.0:
		return 0.0
	
	var wave_signal: float = _sample_boundary_wave_signal(distance_to_wall, world_position)
	return wave_signal * wall_wave_height_strength * wall_band


func _sample_boundary_wave_gradient(world_position: Vector2) -> Vector2:
	var inward: Vector2 = _safe_inward(world_position)
	if inward == Vector2.ZERO:
		return Vector2.ZERO

	var distance_to_wall: float = maxf(dish_radius - world_position.length(), 0.0)
	var reach: float = _wall_wave_reach()
	var wall_band: float = _wall_wave_band(distance_to_wall, reach)
	if wall_band <= 0.0:
		return Vector2.ZERO
	
	var band_slope: float = _wall_wave_band_derivative(distance_to_wall, reach)
	var wave_signal: float = _sample_boundary_wave_signal(distance_to_wall, world_position)
	var wave_slope: float = _sample_boundary_wave_signal_derivative(distance_to_wall, world_position)
	var height_slope: float = (
		wave_slope * wall_wave_height_strength * wall_band
	) + (
		wave_signal * wall_wave_height_strength * band_slope
	)
	return inward * height_slope


func _sample_boundary_wave_flow(world_position: Vector2) -> Vector2:
	var inward: Vector2 = _safe_inward(world_position)
	if inward == Vector2.ZERO:
		return Vector2.ZERO

	var distance_to_wall: float = maxf(dish_radius - world_position.length(), 0.0)
	var reach: float = _wall_wave_reach()
	var wall_band: float = _wall_wave_band(distance_to_wall, reach)
	if wall_band <= 0.0:
		return Vector2.ZERO
	
	var wave_signal: float = _sample_boundary_wave_signal(distance_to_wall, world_position)
	var pulse: float = _sample_boundary_wave_pulse(wave_signal)
	var tangent := Vector2(-inward.y, inward.x)
	var angle: float = atan2(world_position.y, world_position.x)
	var swirl_phase: float = (
		time * (wall_wave_swirl_speed * 0.86 + 0.05)
		+ distance_to_wall * wall_wave_frequency * 0.31
		+ angle * 1.2
	)
	var swirl: float = sin(swirl_phase) * wall_wave_swirl_strength * (0.45 + pulse * 0.55)
	
	return (
		inward * pulse * wall_wave_push_strength * wall_band
		+ tangent * swirl * wall_band
	)


func _sample_boundary_wave_signal(distance_to_wall: float, world_position: Vector2) -> float:
	var angle: float = atan2(world_position.y, world_position.x)
	var primary_phase: float = distance_to_wall * wall_wave_frequency - time * wall_wave_speed
	var angular_drift_phase: float = angle * 1.7 + time * (wall_wave_swirl_speed * 0.48 + 0.07)
	var angular_drift: float = sin(angular_drift_phase + distance_to_wall * wall_wave_frequency * 0.22) * 0.42
	var secondary_phase: float = (
		distance_to_wall * wall_wave_frequency * 0.61
		- time * (wall_wave_speed * 0.57 + 0.11)
		+ angle * 1.9
	)
	var envelope: float = 0.78 + sin(angle * 2.3 - time * (wall_wave_swirl_speed * 0.36 + 0.05)) * 0.22
	return (
		sin(primary_phase + angular_drift) * 0.74
		+ sin(secondary_phase) * 0.26
	) * envelope


func _sample_boundary_wave_signal_derivative(distance_to_wall: float, world_position: Vector2) -> float:
	var angle: float = atan2(world_position.y, world_position.x)
	var angular_drift_phase: float = angle * 1.7 + time * (wall_wave_swirl_speed * 0.48 + 0.07)
	var angular_argument: float = angular_drift_phase + distance_to_wall * wall_wave_frequency * 0.22
	var angular_drift: float = sin(angular_argument) * 0.42
	var angular_drift_derivative: float = cos(angular_argument) * wall_wave_frequency * 0.22 * 0.42
	var primary_total: float = distance_to_wall * wall_wave_frequency - time * wall_wave_speed + angular_drift
	var secondary_phase: float = (
		distance_to_wall * wall_wave_frequency * 0.61
		- time * (wall_wave_speed * 0.57 + 0.11)
		+ angle * 1.9
	)
	var envelope: float = 0.78 + sin(angle * 2.3 - time * (wall_wave_swirl_speed * 0.36 + 0.05)) * 0.22
	return (
		cos(primary_total) * (wall_wave_frequency + angular_drift_derivative) * 0.74
		+ cos(secondary_phase) * wall_wave_frequency * 0.61 * 0.26
	) * envelope


func _sample_boundary_wave_pulse(wave_signal: float) -> float:
	return pow(clampf(wave_signal * 0.58 + 0.42, 0.0, 1.0), _wall_wave_sharpness_value())


func _get_relevant_contributors(_world_position: Vector2) -> Array:
	return contributors


func _sample_substrate_hum(world_position: Vector2) -> float:
	var hum_phase_a := world_position.dot(hum_frequency_a) - time * (base_pulse_speed * 3.8 + 0.72)
	var hum_phase_b := world_position.dot(hum_frequency_b) + time * (base_pulse_speed * 4.4 + 1.06)
	var envelope_phase := world_position.dot(hum_envelope_frequency) - time * (base_pulse_speed * 0.32 + 0.09)
	var hum_wave: float = (sin(hum_phase_a) * hum_wave_weights.x) + (sin(hum_phase_b) * hum_wave_weights.y)
	var hum_envelope: float = hum_envelope_shape.x + (sin(envelope_phase) * hum_envelope_shape.y)
	return hum_wave * hum_envelope


func _sample_radial_presence(world_position: Vector2) -> float:
	if dish_radius <= 0.0:
		return 1.0

	var radius_ratio: float = clampf(world_position.length() / dish_radius, 0.0, 1.0)
	return 0.58 + ((1.0 - radius_ratio) * 0.42)


func _safe_normalized(vector: Vector2) -> Vector2:
	if vector.length_squared() <= 0.000001:
		return Vector2.ZERO
	return vector.normalized()


func _safe_inward(world_position: Vector2) -> Vector2:
	if world_position.length_squared() <= 0.000001:
		return Vector2.ZERO
	return -world_position.normalized()


func _wall_wave_reach() -> float:
	return maxf(dish_radius * wall_wave_reach_ratio, 0.001)


func _wall_wave_band(distance_to_wall: float, reach: float) -> float:
	return 1.0 - _smoothstep01(distance_to_wall / reach)


func _wall_wave_band_derivative(distance_to_wall: float, reach: float) -> float:
	if reach <= 0.000001:
		return 0.0
	return -_smoothstep_derivative01(distance_to_wall / reach) / reach


func _wall_wave_sharpness_value() -> float:
	return maxf(wall_wave_sharpness, 1.0)


func _smoothstep01(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _smoothstep_derivative01(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return 6.0 * t * (1.0 - t)
