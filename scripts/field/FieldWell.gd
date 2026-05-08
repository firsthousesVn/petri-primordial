extends RefCounted
class_name FieldWell

const FieldSampleType = preload("res://scripts/field/FieldSample.gd")

var position: Vector2
var radius: float
var strength: float
var charge_bias: float


func _init(
	initial_position: Vector2 = Vector2.ZERO,
	initial_radius: float = 96.0,
	initial_strength: float = 24.0,
	initial_charge_bias: float = 0.0
) -> void:
	position = initial_position
	radius = maxf(initial_radius, 0.001)
	strength = initial_strength
	charge_bias = initial_charge_bias


func contribute_to_sample(world_position: Vector2, sample: FieldSampleType) -> void:
	if radius <= 0.0:
		return

	var offset_from_center: Vector2 = world_position - position
	var distance: float = offset_from_center.length()
	if distance >= radius:
		return

	var distance_ratio: float = clampf(distance / radius, 0.0, 1.0)
	var falloff: float = 1.0 - _smoothstep01(distance_ratio)
	var height_delta: float = -strength * falloff

	sample.height += height_delta
	sample.charge += charge_bias * falloff

	if distance > 0.0001:
		var slope_magnitude: float = (strength / radius) * _smoothstep_derivative01(distance_ratio)
		var toward_center: Vector2 = -offset_from_center / distance
		sample.gradient += toward_center * slope_magnitude

	var strength_scale := maxf(absf(strength), 0.001)
	var center_influence: float = clampf(absf(height_delta) / strength_scale, 0.0, 1.0)
	sample.coherence += center_influence * minf(strength_scale / 42.0, 1.0) * 0.12


func _smoothstep01(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _smoothstep_derivative01(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return 6.0 * t * (1.0 - t)
