extends Node2D
class_name CoilCell

const DishFieldType = preload("res://scripts/field/DishField.gd")
const FieldSampleType = preload("res://scripts/field/FieldSample.gd")
const FieldTwistType = preload("res://scripts/field/FieldTwist.gd")

const BODY_POINT_COUNT: int = 34
const BODY_LENGTH: float = 34.0
const PROBE_FORWARD_DISTANCE: float = 22.0
const PROBE_LATERAL_DISTANCE: float = 14.0
const PROBE_LONG_DISTANCE: float = 112.0
const BOUNDARY_MARGIN: float = 40.0
const MAX_SPEED: float = 94.0
const BASE_SWIM_SPEED: float = 34.0
const DRIFT_SCALE: float = 44.0
const STEER_RATE: float = 2.2
const BODY_WIDTH: float = 2.55
const MAX_STORED_ENERGY: float = 1.6
const ENERGY_INTAKE_RATE: float = 0.72
const BASAL_ENERGY_COST: float = 0.11
const SPIN_ENERGY_COST: float = 0.085
const STRAIN_ENERGY_COST: float = 0.04
const COAST_DRAG: float = 0.032
const STRAIN_DRAG: float = 0.045
const WAVE_PUSH_STRENGTH: float = 324.0
const FLOW_LOCK_THRESHOLD: float = 0.18
const STILLNESS_THRESHOLD: float = 0.055
const RIDE_ADAPT_WEAK: float = 0.42
const RIDE_ADAPT_STRONG: float = 2.6
const RIDE_LOCK_BUILD: float = 2.8
const RIDE_LOCK_DECAY: float = 0.55
const LOCAL_FLOW_NUDGE: float = 0.0
const VELOCITY_RESPONSE: float = 0.022
const NO_WAVE_DECAY_DELAY: float = 0.42
const NO_WAVE_DECAY_TIME: float = 1.95
const MAX_SPARKS: int = 14
const SPARK_LIFE_MIN: float = 0.10
const SPARK_LIFE_MAX: float = 0.23

var field: DishFieldType
var velocity: Vector2 = Vector2.ZERO
var heading: float = 0.0
var phase: float = 0.0
var stored_energy: float = 0.82
var spin_rate: float = 0.0
var field_alignment: float = 0.0
var strain: float = 0.0
var torsion_strength: float = 0.0
var flow_strength: float = 0.0
var ride_direction: Vector2 = Vector2.RIGHT
var ride_strength: float = 0.0
var no_wave_time: float = 0.0
var _ride_commitment: float = 0.0
var _spin_direction: float = 1.0
var _helix_amplitude: float = 6.2

var _body_points: PackedVector2Array = PackedVector2Array()
var _depth_samples: PackedFloat32Array = PackedFloat32Array()
var _twist_samples: PackedFloat32Array = PackedFloat32Array()
var _ribbon_half_widths: PackedFloat32Array = PackedFloat32Array()
var _spark_positions: PackedVector2Array = PackedVector2Array()
var _spark_velocities: PackedVector2Array = PackedVector2Array()
var _spark_lives: PackedFloat32Array = PackedFloat32Array()
var _spark_life_max: PackedFloat32Array = PackedFloat32Array()
var _spark_sizes: PackedFloat32Array = PackedFloat32Array()
var _spark_colors: PackedColorArray = PackedColorArray()
var _center_sample: FieldSampleType = FieldSampleType.new()
var _head_sample: FieldSampleType = FieldSampleType.new()
var _left_sample: FieldSampleType = FieldSampleType.new()
var _right_sample: FieldSampleType = FieldSampleType.new()
var _far_sample: FieldSampleType = FieldSampleType.new()
var _twist_contributor: FieldTwistType


func _ready() -> void:
	_body_points.resize(BODY_POINT_COUNT)
	_depth_samples.resize(BODY_POINT_COUNT)
	_twist_samples.resize(BODY_POINT_COUNT)
	_ribbon_half_widths.resize(BODY_POINT_COUNT)
	_spark_positions.resize(MAX_SPARKS)
	_spark_velocities.resize(MAX_SPARKS)
	_spark_lives.resize(MAX_SPARKS)
	_spark_life_max.resize(MAX_SPARKS)
	_spark_sizes.resize(MAX_SPARKS)
	_spark_colors.resize(MAX_SPARKS)
	for spark_index in MAX_SPARKS:
		_spark_positions[spark_index] = Vector2.ZERO
		_spark_velocities[spark_index] = Vector2.ZERO
		_spark_lives[spark_index] = 0.0
		_spark_life_max[spark_index] = 0.0
		_spark_sizes[spark_index] = 0.0
		_spark_colors[spark_index] = Color.TRANSPARENT
	_refresh_body_geometry()


func configure(new_field: DishFieldType, initial_heading: float) -> void:
	field = new_field
	heading = initial_heading
	phase = fposmod(position.x * 0.071 + position.y * 0.053, TAU)
	_spin_direction = 1.0 if sin(initial_heading * 1.91 + position.x * 0.017 - position.y * 0.013) >= 0.0 else -1.0
	spin_rate = 0.18 * _spin_direction
	rotation = heading
	field.sample_into(global_position, _center_sample)
	var spawn_flow: Vector2 = _center_sample.flow
	var spawn_flow_magnitude: float = spawn_flow.length()
	var forward := Vector2.RIGHT.rotated(heading)
	if spawn_flow_magnitude > 0.0001:
		ride_direction = spawn_flow / spawn_flow_magnitude
		ride_strength = spawn_flow_magnitude
		field_alignment = clampf(forward.dot(ride_direction), -1.0, 1.0)
	else:
		ride_direction = forward
		ride_strength = 0.0
		field_alignment = 0.0
	stored_energy = clampf(0.70 + _sample_usable_energy(_center_sample) * 0.38, 0.45, 1.05)
	velocity = ride_direction * ride_strength * 28.0 + forward * maxf(0.0, field_alignment) * 3.0

	if _twist_contributor == null:
		_twist_contributor = FieldTwistType.new()
		field.add_contributor(_twist_contributor)

	_sync_twist_contributor()


func _exit_tree() -> void:
	if field != null and _twist_contributor != null:
		field.remove_contributor(_twist_contributor)


func _process(delta: float) -> void:
	if field == null:
		return

	var forward := Vector2.RIGHT.rotated(heading)
	var side := Vector2(-forward.y, forward.x)
	var travel_probe_direction: Vector2 = ride_direction if ride_strength > STILLNESS_THRESHOLD else forward
	if velocity.length_squared() > 9.0:
		travel_probe_direction = velocity.normalized()
	var center_probe_position := global_position
	var head_probe_position := global_position + forward * PROBE_FORWARD_DISTANCE
	var left_probe_position := global_position + forward * (PROBE_FORWARD_DISTANCE * 0.78) + side * PROBE_LATERAL_DISTANCE
	var right_probe_position := global_position + forward * (PROBE_FORWARD_DISTANCE * 0.78) - side * PROBE_LATERAL_DISTANCE
	var far_probe_position := global_position + travel_probe_direction * PROBE_LONG_DISTANCE

	field.sample_into(center_probe_position, _center_sample)
	field.sample_into(head_probe_position, _head_sample)
	field.sample_into(left_probe_position, _left_sample)
	field.sample_into(right_probe_position, _right_sample)
	field.sample_into(far_probe_position, _far_sample)

	var head_activity: float = _sample_usable_energy(_head_sample)
	var center_activity: float = _sample_usable_energy(_center_sample)
	var left_activity: float = _sample_usable_energy(_left_sample)
	var right_activity: float = _sample_usable_energy(_right_sample)
	var side_activity: float = (left_activity + right_activity) * 0.5
	var steer_signal: float = clampf(
		(_left_sample.flow.dot(side) - _right_sample.flow.dot(side)) * 0.14
		+ (left_activity - right_activity) * 0.04,
		-1.0,
		1.0
	)

	var local_flow: Vector2 = (
		_head_sample.flow * 0.34
		+ _center_sample.flow * 0.36
		+ _left_sample.flow * 0.15
		+ _right_sample.flow * 0.15
	)
	var local_flow_strength: float = local_flow.length()
	var raw_long_flow: Vector2 = (
		_far_sample.flow * 0.68
		+ _center_sample.flow * 0.24
		+ _head_sample.flow * 0.08
	)
	var energy_gradient: Vector2 = (
		_far_sample.gradient * 0.20
		+ _center_sample.gradient * 0.46
		+ _head_sample.gradient * 0.24
		+ (_head_sample.gradient - _center_sample.gradient) * 0.10
	)
	var raw_energy_vector: Vector2 = raw_long_flow + energy_gradient * 0.12
	var raw_energy_strength: float = raw_energy_vector.length()
	if raw_energy_strength > 0.0001:
		var raw_energy_direction: Vector2 = raw_energy_vector / raw_energy_strength
		var opposition: float = ride_direction.dot(raw_energy_direction) if ride_strength > 0.0001 else 1.0
		if ride_strength > STILLNESS_THRESHOLD and opposition < -0.72 and raw_energy_strength < ride_strength * (1.45 + _ride_commitment * 0.50):
			raw_energy_direction = ride_direction
			raw_energy_strength = maxf(raw_energy_strength * 0.94, ride_strength * 0.98)

		var adapt_rate: float = lerpf(
			RIDE_ADAPT_WEAK,
			RIDE_ADAPT_STRONG,
			clampf(raw_energy_strength / 0.55, 0.0, 1.0)
		)
		if ride_direction.length_squared() <= 0.0001:
			ride_direction = raw_energy_direction
		ride_direction = ride_direction.lerp(raw_energy_direction, delta * adapt_rate).normalized()
		ride_strength = lerpf(ride_strength, raw_energy_strength, delta * adapt_rate)
		if raw_energy_strength > FLOW_LOCK_THRESHOLD:
			_ride_commitment = clampf(_ride_commitment + delta * RIDE_LOCK_BUILD, 0.0, 1.0)
		else:
			_ride_commitment = maxf(_ride_commitment - delta * RIDE_LOCK_DECAY, 0.0)
	else:
		ride_strength = move_toward(ride_strength, 0.0, delta * 0.08)
		_ride_commitment = maxf(_ride_commitment - delta * RIDE_LOCK_DECAY, 0.0)

	flow_strength = ride_strength
	var energy_direction: Vector2 = ride_direction
	var field_flow: Vector2 = energy_direction * ride_strength
	var energy_present: bool = ride_strength > STILLNESS_THRESHOLD * 1.18 or raw_energy_strength > STILLNESS_THRESHOLD * 1.28
	if energy_present:
		no_wave_time = 0.0
	else:
		no_wave_time += delta
	var stillness_decay: float = clampf((no_wave_time - NO_WAVE_DECAY_DELAY) / NO_WAVE_DECAY_TIME, 0.0, 1.0)
	var recent_energy_presence: float = 1.0 - stillness_decay
	if ride_strength > 0.0001:
		field_alignment = clampf(forward.dot(energy_direction), -1.0, 1.0)
	else:
		field_alignment = 0.0

	var usable_activity: float = clampf(
		(local_flow_strength * 0.34)
		+ (ride_strength * 0.34)
		+ (raw_energy_strength * 0.18)
		+ (_far_sample.flow.length() * 0.10)
		+ head_activity * 0.18
		+ center_activity * 0.14
		+ side_activity * 0.08
		+ absf(_center_sample.charge) * 0.12
		+ _center_sample.coherence * 0.08,
		0.0,
		1.4
	)
	strain = clampf(
		absf(steer_signal) * 0.16
		+ maxf(0.0, -field_alignment) * 0.36
		+ _center_sample.turbulence * 0.24
		+ side_activity * 0.06,
		0.0,
		1.0
	)

	var capture_strength: float = maxf(0.0, field_alignment) * ride_strength
	var energy_intake: float = capture_strength * usable_activity * (0.20 + ride_strength * 1.24 + local_flow_strength * 0.44) * ENERGY_INTAKE_RATE
	stored_energy += energy_intake * delta
	stored_energy -= (BASAL_ENERGY_COST + strain * STRAIN_ENERGY_COST) * delta
	stored_energy -= absf(spin_rate) * SPIN_ENERGY_COST * delta
	stored_energy -= maxf(0.0, -field_alignment) * ride_strength * 0.055 * delta
	stored_energy = clampf(stored_energy, 0.0, MAX_STORED_ENERGY)

	var energy_ratio: float = stored_energy / MAX_STORED_ENERGY
	var velocity_length: float = velocity.length()
	var speed_ratio: float = clampf(velocity_length / MAX_SPEED, 0.0, 1.0)
	var velocity_direction := velocity.normalized() if velocity_length > 0.0001 else forward
	var travel_alignment: float = clampf(velocity_direction.dot(energy_direction), -1.0, 1.0) if ride_strength > 0.0001 else 0.0
	var travel_capture: float = maxf(0.0, travel_alignment) * clampf(velocity_length / MAX_SPEED, 0.0, 1.0)
	var positive_travel: float = maxf(0.0, travel_alignment)
	var target_spin_drive: float = maxf(
		0.0,
		speed_ratio * (0.54 + recent_energy_presence * 0.42)
		+ positive_travel * velocity_length * 0.034
		+ capture_strength * 1.52
		+ ride_strength * 1.14
		+ raw_energy_strength * 0.84
		+ recent_energy_presence * 0.10
		- strain * 0.08
	)
	var target_spin_abs: float = clampf(
		(0.08 + energy_ratio * 0.84) * target_spin_drive,
		0.0,
		2.15
	)
	target_spin_abs *= 1.0 - stillness_decay * 0.90
	if ride_strength < STILLNESS_THRESHOLD and raw_energy_strength < STILLNESS_THRESHOLD:
		target_spin_abs *= clampf(1.0 - stillness_decay * 0.75, 0.06, 1.0)
	var spin_response: float = 0.28 + usable_activity * 0.24
	if energy_present:
		spin_response = 4.2 + positive_travel * 3.4 + ride_strength * 1.8
	spin_rate = move_toward(
		spin_rate,
		_spin_direction * target_spin_abs,
		delta * spin_response
	)
	var spin_abs: float = absf(spin_rate)
	var visual_spin_drive: float = maxf(spin_abs * 0.72, speed_ratio * (0.95 + recent_energy_presence * 0.45))
	var spin_phase_speed: float = visual_spin_drive * (2.6 + speed_ratio * 6.1 + recent_energy_presence * 0.9)
	phase += delta * spin_phase_speed * _spin_direction
	_helix_amplitude = 9.8 + energy_ratio * 1.6 + spin_abs * 0.9

	forward = Vector2.RIGHT.rotated(heading)
	side = Vector2(-forward.y, forward.x)

	var thrust_alignment: float = maxf(0.0, field_alignment)
	var surf_thrust: float = spin_abs * thrust_alignment * travel_capture * (1.9 + energy_ratio * 1.6)
	velocity += field_flow * (WAVE_PUSH_STRENGTH * (1.12 + ride_strength * 0.62 + _center_sample.coherence * 0.22 + recent_energy_presence * 0.14)) * delta
	velocity += local_flow * LOCAL_FLOW_NUDGE * delta
	velocity += forward * surf_thrust * delta
	var desired_velocity := (
		field_flow * (DRIFT_SCALE * 2.48 + ride_strength * 46.0 + _center_sample.coherence * 10.0 + recent_energy_presence * 6.0)
		+ forward * surf_thrust
	)
	velocity = velocity.lerp(
		desired_velocity,
		delta * (VELOCITY_RESPONSE + ride_strength * 0.010 + usable_activity * 0.008)
	)
	var drag: float = (
		COAST_DRAG * (0.26 + stillness_decay * 1.28)
		+ strain * STRAIN_DRAG * (0.26 + stillness_decay * 0.58)
		+ maxf(0.0, 0.05 - ride_strength * 0.05 - energy_ratio * 0.03)
	)
	velocity *= maxf(0.0, 1.0 - drag * delta)
	if velocity.length() > MAX_SPEED:
		velocity = velocity.limit_length(MAX_SPEED)

	position += velocity * delta
	_resolve_boundary()

	if velocity.length_squared() > 2.25:
		heading = lerp_angle(heading, velocity.angle(), delta * (2.7 + ride_strength * 0.9))
	elif ride_strength > STILLNESS_THRESHOLD:
		heading = lerp_angle(heading, energy_direction.angle(), delta * 0.34)

	torsion_strength = clampf(
		spin_abs
		* clampf(velocity.length() / MAX_SPEED, 0.0, 1.0)
			* (0.05 + energy_ratio * 0.08 + ride_strength * 0.22 + raw_energy_strength * 0.16 + positive_travel * 0.12)
			* (1.0 - strain * 0.18),
		0.0,
		0.32
	)
	rotation = heading
	_sync_twist_contributor()
	_refresh_body_geometry()
	_update_sparks(delta)
	_maybe_emit_spin_spark(usable_activity, delta)
	queue_redraw()


func _draw() -> void:
	var underside_color := Color(0.018, 0.024, 0.042, 0.95)
	var graphite_face := Color(0.032, 0.042, 0.070, 0.995)
	var chrome_face := Color(0.970, 0.982, 1.000, 0.985)
	var cyan_edge := Color(0.320, 0.970, 1.000, 0.44)
	var magenta_edge := Color(0.840, 0.220, 0.720, 0.035)
	var yellow_edge := Color(1.000, 0.940, 0.340, 0.03)
	var white_glint := Color(0.985, 1.000, 1.000, 0.28)
	var speed_visual: float = clampf(velocity.length() / MAX_SPEED, 0.0, 1.0)
	var spin_visual: float = clampf(absf(spin_rate) * 0.28 + speed_visual * 1.08, 0.0, 1.0)
	var outer_points := PackedVector2Array()
	var inner_points := PackedVector2Array()
	var shadow_outer_points := PackedVector2Array()
	var shadow_inner_points := PackedVector2Array()
	var face_colors := PackedColorArray()
	var shadow_colors := PackedColorArray()
	var outer_edge_colors := PackedColorArray()
	var inner_edge_colors := PackedColorArray()
	var outer_warm_colors := PackedColorArray()
	var inner_warm_colors := PackedColorArray()
	var glint_points := PackedVector2Array()
	var glint_colors := PackedColorArray()

	outer_points.resize(BODY_POINT_COUNT)
	inner_points.resize(BODY_POINT_COUNT)
	shadow_outer_points.resize(BODY_POINT_COUNT)
	shadow_inner_points.resize(BODY_POINT_COUNT)
	face_colors.resize(BODY_POINT_COUNT * 2)
	shadow_colors.resize(BODY_POINT_COUNT * 2)
	outer_edge_colors.resize(BODY_POINT_COUNT)
	inner_edge_colors.resize(BODY_POINT_COUNT)
	outer_warm_colors.resize(BODY_POINT_COUNT)
	inner_warm_colors.resize(BODY_POINT_COUNT)
	glint_points.resize(BODY_POINT_COUNT)
	glint_colors.resize(BODY_POINT_COUNT)

	for point_index in BODY_POINT_COUNT:
		var point: Vector2 = _body_points[point_index]
		var tangent := _point_tangent(point_index)
		var normal := Vector2(-tangent.y, tangent.x)
		var ribbon_axis := _ribbon_axis(point_index)
		var half_width: float = _ribbon_half_widths[point_index]
		var twist_wave: float = _twist_samples[point_index]
		var front_wave: float = _depth_samples[point_index]
		var front_factor: float = front_wave * 0.5 + 0.5
		var t: float = float(point_index) / float(BODY_POINT_COUNT - 1)
		var nose_factor: float = _smoothstep_local(clampf((t - 0.66) / 0.34, 0.0, 1.0))
		var rear_factor: float = 1.0 - _smoothstep_local(clampf((t - 0.18) / 0.24, 0.0, 1.0))
		var spin_band: float = 0.5 + 0.5 * sin(phase * 0.92 - t * TAU * 1.04)
		var alternate_band: float = 0.5 + 0.5 * sin(phase * 0.68 + t * TAU * 0.52)
		var glint_strength: float = pow(clampf(front_factor * 0.82 + spin_band * 0.34 + nose_factor * 0.24, 0.0, 1.0), 1.55)
		var outer_point: Vector2 = point + ribbon_axis * half_width
		var inner_point: Vector2 = point - ribbon_axis * half_width
		var shadow_shift: Vector2 = -normal * (0.42 + front_factor * 0.18) + tangent * -0.24
		var outer_color_mix: float = clampf(0.01 + maxf(front_wave, 0.0) * (0.86 + spin_visual * 0.24) + spin_band * (0.04 + spin_visual * 0.10) + nose_factor * 0.24, 0.0, 1.0)
		var inner_color_mix: float = clampf(0.01 + maxf(-front_wave, 0.0) * (0.86 + spin_visual * 0.24) + spin_band * (0.04 + spin_visual * 0.10) + nose_factor * 0.16, 0.0, 1.0)
		var outer_face_color: Color = graphite_face.lerp(chrome_face, outer_color_mix)
		var inner_face_color: Color = graphite_face.lerp(chrome_face, inner_color_mix)
		var visible_outer_alpha: float = 0.06 + maxf(front_wave, 0.0) * 0.16 + maxf(twist_wave, 0.0) * 0.12 + spin_band * (0.02 + spin_visual * 0.05) + nose_factor * (0.06 + spin_visual * 0.05)
		var visible_inner_alpha: float = 0.06 + maxf(-front_wave, 0.0) * 0.16 + maxf(-twist_wave, 0.0) * 0.12 + spin_band * (0.02 + spin_visual * 0.05) + nose_factor * (0.04 + spin_visual * 0.04)
		var warm_outer_alpha: float = 0.010 + maxf(-twist_wave, 0.0) * 0.018 + alternate_band * 0.008 + rear_factor * 0.012
		var warm_inner_alpha: float = 0.010 + maxf(twist_wave, 0.0) * 0.018 + alternate_band * 0.008 + rear_factor * 0.012
		var glint_offset: Vector2 = ribbon_axis * (0.14 + front_factor * 0.34)
		var glint_color: Color = white_glint
		glint_color.a = 0.07 + glint_strength * (0.14 + nose_factor * 0.06)

		outer_points[point_index] = outer_point
		inner_points[point_index] = inner_point
		shadow_outer_points[point_index] = outer_point + shadow_shift
		shadow_inner_points[point_index] = inner_point + shadow_shift
		face_colors[point_index] = outer_face_color
		face_colors[(BODY_POINT_COUNT * 2) - 1 - point_index] = inner_face_color
		shadow_colors[point_index] = underside_color
		shadow_colors[(BODY_POINT_COUNT * 2) - 1 - point_index] = underside_color

		var outer_edge_color: Color = cyan_edge
		outer_edge_color.a = visible_outer_alpha
		var inner_edge_color: Color = cyan_edge
		inner_edge_color.a = visible_inner_alpha
		var outer_warm_color: Color = magenta_edge.lerp(yellow_edge, 0.18 + spin_band * 0.58)
		outer_warm_color.a = warm_outer_alpha
		var inner_warm_color: Color = magenta_edge.lerp(yellow_edge, 0.18 + spin_band * 0.58)
		inner_warm_color.a = warm_inner_alpha

		outer_edge_colors[point_index] = outer_edge_color
		inner_edge_colors[point_index] = inner_edge_color
		outer_warm_colors[point_index] = outer_warm_color
		inner_warm_colors[point_index] = inner_warm_color
		glint_points[point_index] = point + glint_offset
		glint_colors[point_index] = glint_color

	var shadow_polygon := _build_ribbon_polygon(shadow_outer_points, shadow_inner_points)
	var face_polygon := _build_ribbon_polygon(outer_points, inner_points)
	var nose_base_index: int = BODY_POINT_COUNT - 6
	var nose_base: Vector2 = _body_points[nose_base_index]
	var nose_axis := _ribbon_axis(nose_base_index)
	var nose_half_width: float = _ribbon_half_widths[nose_base_index] * 1.52
	var nose_tip: Vector2 = _body_points[BODY_POINT_COUNT - 1] + Vector2(BODY_WIDTH * 5.1, 0.0)
	var nose_shadow_tip: Vector2 = nose_tip + Vector2(-0.55, 0.16)
	var nose_shadow := PackedVector2Array([
		nose_base + nose_axis * nose_half_width + Vector2(-0.30, -0.10),
		nose_shadow_tip,
		nose_base - nose_axis * nose_half_width + Vector2(-0.30, 0.10)
	])
	var nose_face := PackedVector2Array([
		nose_base + nose_axis * nose_half_width,
		nose_tip,
		nose_base - nose_axis * nose_half_width
	])
	var nose_shadow_colors := PackedColorArray([underside_color, underside_color, underside_color])
	var nose_face_color: Color = chrome_face.lerp(graphite_face, 0.18)
	nose_face_color.a = 0.99
	var nose_face_colors := PackedColorArray([nose_face_color, chrome_face, nose_face_color])
	draw_polygon(shadow_polygon, shadow_colors)
	draw_polygon(face_polygon, face_colors)
	draw_polygon(nose_shadow, nose_shadow_colors)
	draw_polygon(nose_face, nose_face_colors)
	draw_polyline_colors(outer_points, outer_edge_colors, 1.10, true)
	draw_polyline_colors(inner_points, inner_edge_colors, 1.10, true)
	draw_polyline_colors(outer_points, outer_warm_colors, 0.46, true)
	draw_polyline_colors(inner_points, inner_warm_colors, 0.46, true)
	draw_polyline_colors(glint_points, glint_colors, 1.28, true)
	var nose_cool := PackedColorArray()
	nose_cool.resize(3)
	var nose_warm := PackedColorArray()
	nose_warm.resize(3)
	nose_cool[0] = Color(cyan_edge.r, cyan_edge.g, cyan_edge.b, 0.62 + speed_visual * 0.10)
	nose_cool[1] = Color(cyan_edge.r, cyan_edge.g, cyan_edge.b, 0.78 + speed_visual * 0.10)
	nose_cool[2] = Color(cyan_edge.r, cyan_edge.g, cyan_edge.b, 0.62 + speed_visual * 0.10)
	nose_warm[0] = Color(magenta_edge.r, magenta_edge.g, magenta_edge.b, 0.055)
	nose_warm[1] = Color(yellow_edge.r, yellow_edge.g, yellow_edge.b, 0.065)
	nose_warm[2] = Color(magenta_edge.r, magenta_edge.g, magenta_edge.b, 0.055)
	draw_polyline_colors(nose_face, nose_cool, 1.22, true)
	draw_polyline_colors(nose_face, nose_warm, 0.42, true)
	_draw_sparks()


func _resolve_boundary() -> void:
	var max_radius: float = maxf(field.dish_radius - BOUNDARY_MARGIN, 0.0)
	var distance_from_center: float = position.length()
	if distance_from_center <= max_radius:
		return

	var normal := position / maxf(distance_from_center, 0.001)
	var tangent := Vector2(-normal.y, normal.x)
	var tangential_velocity: Vector2 = tangent * velocity.dot(tangent)
	var normal_speed: float = velocity.dot(normal)
	var overflow: float = distance_from_center - max_radius
	var inward_velocity: Vector2 = normal * minf(normal_speed, 0.0) * 0.84
	var outward_velocity: Vector2 = normal * maxf(normal_speed, 0.0) * 0.18

	position = normal * max_radius
	velocity = (
		tangential_velocity * 0.96
		+ inward_velocity
		+ outward_velocity
		- normal * (4.0 + overflow * 0.34)
	)

	if velocity.length_squared() > 1.0:
		heading = lerp_angle(heading, velocity.angle(), 0.45)
	else:
		heading = lerp_angle(heading, tangent.angle(), 0.35)


func _refresh_body_geometry() -> void:
	var lateral_amplitude: float = _helix_amplitude
	var helix_turns: float = 2.72

	for point_index in BODY_POINT_COUNT:
		var t: float = float(point_index) / float(BODY_POINT_COUNT - 1)
		var x: float = lerpf(-BODY_LENGTH * 0.76, BODY_LENGTH * 0.06, t)
		var twist_phase: float = phase * 0.96 + t * TAU * helix_turns
		var twist_wave: float = sin(twist_phase)
		var front_wave: float = cos(twist_phase)
		var center_profile: float = pow(sin(clampf((t - 0.04) / 0.92, 0.0, 1.0) * PI), 0.60)
		var rear_rise: float = _smoothstep_local(clampf((t - 0.02) / 0.18, 0.0, 1.0))
		var nose_drop: float = _smoothstep_local(clampf((t - 0.78) / 0.22, 0.0, 1.0))
		var nose_taper: float = 1.0 - nose_drop
		var shoulder_profile: float = _smoothstep_local(clampf((t - 0.42) / 0.22, 0.0, 1.0)) * nose_taper
		var tail_taper: float = 0.14 + rear_rise * 0.86
		var width_profile: float = (0.08 + center_profile * 0.76 + shoulder_profile * 0.50) * tail_taper * (0.18 + nose_taper * 0.82)
		var ridge_profile: float = (0.16 + center_profile * 0.90 + shoulder_profile * 0.12) * tail_taper * (0.10 + nose_taper * 0.90)
		var centerline_wave: float = twist_wave * lateral_amplitude * ridge_profile
		var point := Vector2(x, centerline_wave)

		_body_points[point_index] = point
		_depth_samples[point_index] = front_wave
		_twist_samples[point_index] = twist_wave
		_ribbon_half_widths[point_index] = BODY_WIDTH * (0.06 + absf(front_wave) * 0.04 + width_profile * 0.96)


func _update_sparks(delta: float) -> void:
	for spark_index in MAX_SPARKS:
		var remaining: float = _spark_lives[spark_index]
		if remaining <= 0.0:
			continue

		remaining = maxf(remaining - delta, 0.0)
		_spark_lives[spark_index] = remaining
		_spark_positions[spark_index] += _spark_velocities[spark_index] * delta
		_spark_velocities[spark_index] *= 0.92


func _maybe_emit_spin_spark(usable_activity: float, delta: float) -> void:
	var speed_ratio: float = clampf(velocity.length() / MAX_SPEED, 0.0, 1.0)
	var spin_peak: float = maxf(0.0, absf(sin(phase * 0.96)) - 0.72) / 0.28
	var spark_drive: float = clampf(
		(spin_peak * 0.46 + speed_ratio * 0.54)
		* (
			usable_activity * 0.24
			+ absf(spin_rate) * 0.48
			+ speed_ratio * 0.62
			+ (stored_energy / MAX_STORED_ENERGY) * 0.22
		),
		0.0,
		1.0
	)
	if spark_drive <= 0.02:
		return

	if randf() > spark_drive * delta * 24.0:
		return

	var spark_slot: int = _find_free_spark_slot()
	if spark_slot < 0:
		return

	var rear_bias: float = pow(randf(), 2.35)
	var point_index: int = clampi(int(lerpf(2.0, BODY_POINT_COUNT * 0.76, rear_bias)), 2, BODY_POINT_COUNT - 4)
	var point: Vector2 = _body_points[point_index]
	var tangent := _point_tangent(point_index)
	var ribbon_axis := _ribbon_axis(point_index)
	var half_width: float = _ribbon_half_widths[point_index]
	var edge_sign: float = 1.0 if _twist_samples[point_index] >= 0.0 else -1.0
	var edge_point: Vector2 = point + ribbon_axis * half_width * edge_sign
	var outward: Vector2 = ribbon_axis * edge_sign
	var rear_push: Vector2 = Vector2.LEFT * randf_range(14.0, 26.0) * (0.70 + speed_ratio * 1.20)
	var tangential_push: Vector2 = tangent * _spin_direction * randf_range(6.5, 13.0) * (0.68 + speed_ratio * 0.92)
	var outward_push: Vector2 = outward * randf_range(13.0, 26.0) * (0.62 + speed_ratio * 1.12)
	var spark_life: float = randf_range(SPARK_LIFE_MIN, SPARK_LIFE_MAX)
	var spark_color := Color(0.620, 0.980, 1.000, 0.52)
	var color_roll: float = randf()
	if color_roll > 0.78:
		spark_color = Color(0.985, 1.000, 1.000, 0.42)
	elif color_roll < 0.12:
		spark_color = Color(0.860, 0.220, 0.760, 0.28)
	elif color_roll < 0.18:
		spark_color = Color(1.000, 0.930, 0.320, 0.26)

	_spark_positions[spark_slot] = edge_point + outward * randf_range(1.0, 2.4) + Vector2.LEFT * randf_range(1.0, 2.8)
	_spark_velocities[spark_slot] = outward_push + tangential_push + rear_push
	_spark_lives[spark_slot] = spark_life
	_spark_life_max[spark_slot] = spark_life
	_spark_sizes[spark_slot] = randf_range(0.9, 1.65)
	_spark_colors[spark_slot] = spark_color


func _find_free_spark_slot() -> int:
	for spark_index in MAX_SPARKS:
		if _spark_lives[spark_index] <= 0.0:
			return spark_index
	return -1


func _draw_sparks() -> void:
	for spark_index in MAX_SPARKS:
		var remaining: float = _spark_lives[spark_index]
		if remaining <= 0.0:
			continue

		var max_life: float = maxf(_spark_life_max[spark_index], 0.0001)
		var life_ratio: float = remaining / max_life
		var spark_color: Color = _spark_colors[spark_index]
		spark_color.a *= life_ratio
		var spark_position: Vector2 = _spark_positions[spark_index]
		var spark_velocity: Vector2 = _spark_velocities[spark_index]
		var spark_direction: Vector2 = spark_velocity.normalized() if spark_velocity.length_squared() > 0.0001 else Vector2.RIGHT
		var streak_length: float = (0.8 + _spark_sizes[spark_index]) * life_ratio * 2.4
		var streak_start: Vector2 = spark_position - spark_direction * streak_length
		draw_line(streak_start, spark_position, spark_color, 0.65 + _spark_sizes[spark_index] * 0.22, true)
		draw_circle(spark_position, 0.42 + _spark_sizes[spark_index] * 0.16, spark_color)


func _sample_usable_energy(sample: FieldSampleType) -> float:
	return clampf(
		sample.flow.length() * 0.72
		+ sample.gradient.length() * 0.34
		+ absf(sample.charge) * 0.22
		+ sample.turbulence * 0.16
		+ sample.coherence * 0.10
		+ maxf(0.0, -sample.height) * 0.0048,
		0.0,
		1.0
	)


func _sync_twist_contributor() -> void:
	if _twist_contributor == null:
		return

	_twist_contributor.sync_from_coil_state(
		global_position,
		heading,
		phase,
		spin_rate,
		stored_energy,
		_helix_amplitude,
		velocity.length(),
		torsion_strength
	)


func write_shader_torsion_uniforms(
	data_a: PackedVector4Array,
	data_b: PackedVector4Array,
	data_c: PackedVector4Array,
	index: int
) -> void:
	if _twist_contributor == null:
		return

	data_a[index] = _twist_contributor.get_shader_data_a()
	data_b[index] = _twist_contributor.get_shader_data_b()
	data_c[index] = _twist_contributor.get_shader_data_c()


func _ribbon_axis(point_index: int) -> Vector2:
	var tangent := _point_tangent(point_index)
	var normal := Vector2(-tangent.y, tangent.x)
	var twist_wave: float = _twist_samples[point_index]
	var face_wave: float = _depth_samples[point_index]
	var exposure: float = 0.78 + absf(face_wave) * 0.22
	var axis := (normal * exposure + tangent * twist_wave * 0.34).normalized()
	if axis.length_squared() <= 0.0001:
		return normal
	return axis


func _point_tangent(point_index: int) -> Vector2:
	var previous_index: int = maxi(point_index - 1, 0)
	var next_index: int = mini(point_index + 1, BODY_POINT_COUNT - 1)
	var tangent := _body_points[next_index] - _body_points[previous_index]
	if tangent.length_squared() <= 0.0001:
		return Vector2.RIGHT
	return tangent.normalized()


func _build_ribbon_polygon(outer_points: PackedVector2Array, inner_points: PackedVector2Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	polygon.resize(BODY_POINT_COUNT * 2)
	for point_index in BODY_POINT_COUNT:
		polygon[point_index] = outer_points[point_index]
		polygon[(BODY_POINT_COUNT * 2) - 1 - point_index] = inner_points[point_index]
	return polygon


func _smoothstep_local(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
