extends RefCounted
class_name FieldTwist

const FieldSampleType = preload("res://scripts/field/FieldSample.gd")

# Mechanical and visual field signature of a rotating CoilCell body.
var position: Vector2 = Vector2.ZERO
var heading: float = 0.0
var phase: float = 0.0
var spin_rate: float = 0.75
var radius: float = 40.0
var strength: float = 0.170
var shear_strength: float = 0.068
var charge_strength: float = 0.055
var turbulence_strength: float = 0.062
var coherence_loss: float = 0.020
var helix_amplitude: float = 0.5


func sync_from_coil_state(
	coil_position: Vector2,
	coil_heading: float,
	coil_phase: float,
	coil_spin_rate: float,
	coil_stored_energy: float,
	body_amplitude: float,
	coil_velocity_length: float,
	coil_torsion_strength: float
) -> void:
	position = coil_position
	heading = coil_heading
	phase = coil_phase
	spin_rate = coil_spin_rate
	helix_amplitude = clampf(body_amplitude / 12.0, 0.45, 2.2)
	var energy_ratio: float = clampf(coil_stored_energy / 1.6, 0.0, 1.0)
	var speed_ratio: float = clampf(coil_velocity_length / 94.0, 0.0, 1.0)
	var spin_abs: float = absf(coil_spin_rate)
	radius = 34.0 + helix_amplitude * 7.0 + speed_ratio * 12.0 + energy_ratio * 8.0
	strength = coil_torsion_strength
	shear_strength = 0.012 + coil_torsion_strength * 0.24 + speed_ratio * 0.010 + spin_abs * 0.008
	charge_strength = 0.016 + energy_ratio * 0.018 + helix_amplitude * 0.008 + spin_abs * 0.006
	turbulence_strength = 0.010 + coil_torsion_strength * 0.22 + speed_ratio * 0.014
	coherence_loss = 0.006 + coil_torsion_strength * 0.12 + spin_abs * 0.005


func get_shader_data_a() -> Vector4:
	return Vector4(position.x, position.y, radius, phase)


func get_shader_data_b() -> Vector4:
	var forward := Vector2.RIGHT.rotated(heading)
	return Vector4(spin_rate, strength, forward.x, forward.y)


func get_shader_data_c() -> Vector4:
	return Vector4(shear_strength, charge_strength, turbulence_strength, helix_amplitude)


func contribute_to_sample(world_position: Vector2, sample: FieldSampleType) -> void:
	if radius <= 0.0:
		return

	var offset_from_center: Vector2 = world_position - position
	var distance_squared: float = offset_from_center.length_squared()
	var radius_squared: float = radius * radius
	if distance_squared <= 0.000001 or distance_squared >= radius_squared:
		return

	var distance: float = sqrt(distance_squared)
	var distance_ratio: float = clampf(distance / radius, 0.0, 1.0)
	var falloff: float = 1.0 - _smoothstep01(distance_ratio)
	var forward := Vector2.RIGHT.rotated(heading)
	var side := Vector2(-forward.y, forward.x)
	var local_forward: float = offset_from_center.dot(forward)
	var local_side: float = offset_from_center.dot(side)
	var local_angle: float = atan2(local_side, local_forward)
	var tangent: Vector2 = Vector2(-offset_from_center.y, offset_from_center.x) / distance
	var spin_sign: float = 1.0 if spin_rate >= 0.0 else -1.0
	var torsion_strength: float = strength * spin_sign * (0.88 + helix_amplitude * 0.18)
	var phase_wave: float = sin(
		phase
		+ local_angle * 1.7
		+ local_forward / maxf(radius, 0.001) * PI * 1.4
	)
	var turbulence_wave: float = 0.68 + absf(sin(phase * 0.82 - local_angle * 1.9)) * 0.32
	var spin_abs: float = absf(spin_rate)
	var flow_torsion: Vector2 = tangent * torsion_strength * falloff
	var flow_shear: Vector2 = forward * phase_wave * falloff * shear_strength * spin_abs
	var front_offset: float = radius * (0.34 + helix_amplitude * 0.06)
	var rear_offset: float = radius * (0.20 + helix_amplitude * 0.05)
	var front_point: Vector2 = position + forward * front_offset
	var rear_point: Vector2 = position - forward * rear_offset
	var front_delta: Vector2 = world_position - front_point
	var rear_delta: Vector2 = world_position - rear_point
	var front_distance: float = maxf(front_delta.length(), 0.0001)
	var rear_distance: float = maxf(rear_delta.length(), 0.0001)
	var front_long: float = front_delta.dot(forward)
	var rear_long: float = -rear_delta.dot(forward)
	var front_side: float = absf(front_delta.dot(side))
	var rear_side: float = absf(rear_delta.dot(side))
	var front_axial: float = _smoothstep01(clampf((front_long + radius * 0.08) / (radius * 0.68), 0.0, 1.0))
	var rear_axial: float = _smoothstep01(clampf((rear_long + radius * 0.16) / (radius * 1.52), 0.0, 1.0))
	var front_side_limit: float = radius * lerpf(0.12, 0.24, front_axial)
	var rear_side_limit: float = radius * lerpf(0.22, 0.64, rear_axial)
	var front_side_focus: float = 1.0 - _smoothstep01(clampf(front_side / maxf(front_side_limit, 0.001), 0.0, 1.0))
	var rear_side_focus: float = 1.0 - _smoothstep01(clampf(rear_side / maxf(rear_side_limit, 0.001), 0.0, 1.0))
	var front_distance_focus: float = 1.0 - _smoothstep01(clampf(front_distance / (radius * 0.82), 0.0, 1.0))
	var rear_distance_focus: float = 1.0 - _smoothstep01(clampf(rear_distance / (radius * 1.62), 0.0, 1.0))
	var front_focus: float = front_axial * front_side_focus * front_distance_focus
	var rear_focus: float = rear_axial * rear_side_focus * rear_distance_focus
	var intake_direction: Vector2 = (front_point - world_position) / front_distance
	var rear_side_sign: float = signf(rear_delta.dot(side))
	var bite_pull: Vector2 = intake_direction * front_focus * (shear_strength * (1.05 + spin_abs * 0.78) + strength * 0.22)
	var front_compress: Vector2 = -side * signf(front_delta.dot(side)) * front_focus * shear_strength * 0.18
	var rear_trail: Vector2 = -forward * rear_focus * (shear_strength * (0.72 + spin_abs * 0.46) + strength * 0.14)
	var rear_splay: Vector2 = (
		tangent * phase_wave * 0.88
		+ side * rear_side_sign * 0.42
		- forward * 0.18
	) * rear_focus * strength * 0.34

	sample.gradient += flow_torsion
	sample.gradient += flow_shear
	sample.gradient += bite_pull
	sample.gradient += front_compress
	sample.gradient += rear_trail
	sample.gradient += rear_splay
	sample.flow += flow_torsion * 1.05
	sample.flow += flow_shear * 1.25
	sample.flow += bite_pull * 1.60
	sample.flow += front_compress * 1.24
	sample.flow += rear_trail * 1.48
	sample.flow += rear_splay * 1.26
	sample.turbulence += spin_abs * falloff * turbulence_strength * turbulence_wave
	sample.turbulence += (front_focus * 0.020 + rear_focus * 0.070) * (0.8 + spin_abs) * turbulence_strength
	sample.charge += sin(phase + local_angle * 2.0) * charge_strength * falloff
	sample.charge += sin(phase * 1.14 + front_long * 0.12) * charge_strength * front_focus * 0.42
	sample.charge += cos(phase * 0.92 - rear_long * 0.10) * charge_strength * rear_focus * 0.56
	sample.coherence -= spin_abs * falloff * coherence_loss
	sample.coherence -= (front_focus * 0.010 + rear_focus * 0.016) * coherence_loss


func _smoothstep01(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
