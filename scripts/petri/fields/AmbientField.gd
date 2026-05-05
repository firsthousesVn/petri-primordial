extends RefCounted
class_name AmbientField

# The dish-wide energetic medium. Pure sampling math — every value is derived
# from `(local_pos, sim_time, dish_radius)` so a sampler called twice at the
# same point/time returns the same value. PetriDish owns the world↔local
# transform and the global sim clock; this class only does math.
#
# Master dials for the medium itself. Renderer/interaction dials live in their
# own modules.
const STRENGTH: float = 18.0
const SCALE: float = 0.0085
const TIME_SPEED: float = 0.10
const VORTEX_GAIN: float = 0.72
const FLOW_GAIN: float = 1.00
const PULSE_GAIN: float = 0.12
const PULSE_SPEED: float = 0.24

var enabled: bool = true


func _flow_basis(local_pos: Vector2, sim_time: float) -> Vector2:
	var x: float = local_pos.x * SCALE
	var y: float = local_pos.y * SCALE
	var t: float = sim_time * TIME_SPEED
	var lane_a: Vector2 = Vector2(cos(0.55 * t + 0.65), sin(0.42 * t - 0.35))
	var lane_b: Vector2 = Vector2(cos(-0.38 * t + 2.10), sin(0.33 * t + 1.30))
	var lane_mix_a: float = 0.5 + 0.5 * sin(0.92 * x + 0.37 * y + 0.70 * t)
	var lane_mix_b: float = 0.5 + 0.5 * cos(-0.58 * x + 0.82 * y - 0.48 * t)
	return lane_a * lane_mix_a + lane_b * lane_mix_b


func _vortex_basis(local_pos: Vector2, sim_time: float) -> Vector2:
	var x: float = local_pos.x * SCALE
	var y: float = local_pos.y * SCALE
	var t: float = sim_time * TIME_SPEED
	var arg_a: float = 1.25 * x - 0.55 * y + 0.60 * t
	var arg_b: float = -0.74 * x + 1.08 * y - 0.42 * t + 1.70
	var grad_a: Vector2 = Vector2(1.25 * cos(arg_a), -0.55 * cos(arg_a))
	var grad_b: Vector2 = Vector2(-0.74 * 0.72 * cos(arg_b), 1.08 * 0.72 * cos(arg_b))
	var gradient: Vector2 = grad_a + grad_b
	return Vector2(-gradient.y, gradient.x)


func strength_envelope(local_pos: Vector2, sim_time: float, dish_radius: float) -> float:
	var x: float = local_pos.x * SCALE
	var y: float = local_pos.y * SCALE
	var t: float = sim_time * TIME_SPEED
	var weather: float = sin(0.54 * x - 0.86 * y + 0.22 * t + 1.10) * cos(0.78 * x + 0.34 * y - 0.18 * t - 0.60)
	var weather01: float = 0.5 + 0.5 * weather
	var radius_ratio: float = clampf(local_pos.length() / maxf(dish_radius, 0.001), 0.0, 1.0)
	var edge_taper: float = lerpf(1.0, 0.82, radius_ratio * radius_ratio)
	return clampf((0.32 + 0.68 * weather01) * edge_taper, 0.0, 1.0)


# Returns the ambient field vector at `local_pos` (dish-local coords).
func sample_local(local_pos: Vector2, sim_time: float, dish_radius: float) -> Vector2:
	if not enabled:
		return Vector2.ZERO
	var flow: Vector2 = _flow_basis(local_pos, sim_time) * FLOW_GAIN
	var vortex: Vector2 = _vortex_basis(local_pos, sim_time) * VORTEX_GAIN
	var envelope: float = strength_envelope(local_pos, sim_time, dish_radius)
	var pulse: float = 1.0 + PULSE_GAIN * sin(sim_time * PULSE_SPEED)
	var field_vec: Vector2 = (flow + vortex) * (STRENGTH * envelope * pulse)
	if not field_vec.is_finite():
		return Vector2.ZERO
	return field_vec.limit_length(STRENGTH * 1.6)


func sample_calm_local(local_pos: Vector2, sim_time: float, dish_radius: float) -> float:
	if not enabled:
		return 1.0
	return clampf(1.0 - strength_envelope(local_pos, sim_time, dish_radius), 0.0, 1.0)


# Curl is computed by central-difference around `local_pos`.
func sample_curl_local(local_pos: Vector2, sim_time: float, dish_radius: float) -> float:
	if not enabled:
		return 0.0
	var eps: float = 16.0
	var left: Vector2 = sample_local(local_pos + Vector2.LEFT * eps, sim_time, dish_radius)
	var right: Vector2 = sample_local(local_pos + Vector2.RIGHT * eps, sim_time, dish_radius)
	var up: Vector2 = sample_local(local_pos + Vector2.UP * eps, sim_time, dish_radius)
	var down: Vector2 = sample_local(local_pos + Vector2.DOWN * eps, sim_time, dish_radius)
	return (right.y - left.y) / (2.0 * eps) - (down.x - up.x) / (2.0 * eps)
