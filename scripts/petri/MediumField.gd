extends Node2D
class_name MediumField

const DEFAULT_GRID: int = 64

const CHARGE_GAIN_RATE: float = 0.18
const CHARGE_MAX: float = 1.0
const CHARGE_DIFFUSE: float = 0.10
const NOISE_DIFFUSE: float = 0.20
const NOISE_DECAY: float = 0.7
const NOISE_MAX: float = 4.0
const STEP_HZ: float = 20.0
const FLOW_SPEED: float = 14.0

var grid_size: int = DEFAULT_GRID
var radius: float = 320.0
var cell_size: float = 1.0

var light: PackedFloat32Array
var charge: PackedFloat32Array
var noise: PackedFloat32Array
var flow: PackedVector2Array
var inside: PackedByteArray

var _temp: PackedFloat32Array
var _step_accum: float = 0.0

var debug_charge: bool = false
var debug_noise: bool = false
var debug_light: bool = false


func configure(r: float, gs: int = DEFAULT_GRID) -> void:
	radius = r
	grid_size = gs


func _ready() -> void:
	_allocate()
	_bake_light_and_flow()


func _allocate() -> void:
	var n: int = grid_size * grid_size
	light = PackedFloat32Array()
	charge = PackedFloat32Array()
	noise = PackedFloat32Array()
	_temp = PackedFloat32Array()
	light.resize(n)
	charge.resize(n)
	noise.resize(n)
	_temp.resize(n)
	flow = PackedVector2Array()
	flow.resize(n)
	inside = PackedByteArray()
	inside.resize(n)
	cell_size = (radius * 2.0) / float(grid_size)


func _bake_light_and_flow() -> void:
	for y in grid_size:
		for x in grid_size:
			var idx: int = y * grid_size + x
			var p: Vector2 = _grid_to_local(x, y)
			var d: float = p.length()
			if d > radius:
				inside[idx] = 0
				light[idx] = 0.0
				flow[idx] = Vector2.ZERO
				continue
			inside[idx] = 1
			# Light: window at upper-left, gradient from there.
			var t: float = (p.dot(Vector2(1.0, 1.0).normalized()) / (radius * 1.4)) * 0.5 + 0.5
			light[idx] = clampf(1.0 - t, 0.05, 1.0)
			# Flow: gentle counter-clockwise swirl, weaker near the rim.
			var perp: Vector2 = Vector2(-p.y, p.x)
			var rim_falloff: float = 1.0 - clampf(d / radius, 0.0, 1.0)
			flow[idx] = perp.normalized() * FLOW_SPEED * rim_falloff if perp.length() > 0.01 else Vector2.ZERO


func _grid_to_local(gx: int, gy: int) -> Vector2:
	var fx: float = (float(gx) + 0.5) / float(grid_size)
	var fy: float = (float(gy) + 0.5) / float(grid_size)
	return Vector2(fx * 2.0 - 1.0, fy * 2.0 - 1.0) * radius


func world_to_grid(pos: Vector2) -> Vector2i:
	var fx: float = (pos.x / radius + 1.0) * 0.5
	var fy: float = (pos.y / radius + 1.0) * 0.5
	var gx: int = clampi(int(fx * grid_size), 0, grid_size - 1)
	var gy: int = clampi(int(fy * grid_size), 0, grid_size - 1)
	return Vector2i(gx, gy)


func _sample_float(arr: PackedFloat32Array, pos: Vector2) -> float:
	var fx: float = (pos.x / radius + 1.0) * 0.5 * grid_size - 0.5
	var fy: float = (pos.y / radius + 1.0) * 0.5 * grid_size - 0.5
	var x0: int = clampi(int(floor(fx)), 0, grid_size - 1)
	var y0: int = clampi(int(floor(fy)), 0, grid_size - 1)
	var x1: int = clampi(x0 + 1, 0, grid_size - 1)
	var y1: int = clampi(y0 + 1, 0, grid_size - 1)
	var tx: float = clampf(fx - float(x0), 0.0, 1.0)
	var ty: float = clampf(fy - float(y0), 0.0, 1.0)
	var a: float = arr[y0 * grid_size + x0]
	var b: float = arr[y0 * grid_size + x1]
	var c: float = arr[y1 * grid_size + x0]
	var d: float = arr[y1 * grid_size + x1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)


func sample_light(pos: Vector2) -> float:
	return _sample_float(light, pos)


func sample_charge(pos: Vector2) -> float:
	return _sample_float(charge, pos)


func sample_noise(pos: Vector2) -> float:
	return _sample_float(noise, pos)


func sample_flow(pos: Vector2) -> Vector2:
	var g: Vector2i = world_to_grid(pos)
	return flow[g.y * grid_size + g.x]


func add_noise(pos: Vector2, amount: float) -> void:
	var g: Vector2i = world_to_grid(pos)
	var idx: int = g.y * grid_size + g.x
	if inside[idx] == 0:
		return
	noise[idx] = clampf(noise[idx] + amount, 0.0, NOISE_MAX)


func consume_charge(pos: Vector2, amount: float) -> float:
	var g: Vector2i = world_to_grid(pos)
	var idx: int = g.y * grid_size + g.x
	if inside[idx] == 0:
		return 0.0
	var taken: float = minf(charge[idx], maxf(amount, 0.0))
	charge[idx] -= taken
	return taken


func clear_dynamic_state() -> void:
	var n: int = charge.size()
	for i in n:
		charge[i] = 0.0
		noise[i] = 0.0
	_step_accum = 0.0
	queue_redraw()


func step(delta: float) -> void:
	_step_accum += delta
	var dt_step: float = 1.0 / STEP_HZ
	var ran: bool = false
	while _step_accum >= dt_step:
		_step_accum -= dt_step
		_gain_charge(dt_step)
		_diffuse(charge, CHARGE_DIFFUSE, 0.0)
		_diffuse(noise, NOISE_DIFFUSE, NOISE_DECAY * dt_step)
		ran = true
	if ran and (debug_charge or debug_noise or debug_light):
		queue_redraw()


func _gain_charge(dt: float) -> void:
	var n: int = charge.size()
	for i in n:
		if inside[i] == 0:
			continue
		var c: float = charge[i] + light[i] * CHARGE_GAIN_RATE * dt
		if c > CHARGE_MAX:
			c = CHARGE_MAX
		charge[i] = c


func _diffuse(arr: PackedFloat32Array, rate: float, decay: float) -> void:
	for y in grid_size:
		for x in grid_size:
			var idx: int = y * grid_size + x
			if inside[idx] == 0:
				_temp[idx] = 0.0
				continue
			var v: float = arr[idx]
			var sum: float = 0.0
			var n_count: int = 0
			if x > 0 and inside[idx - 1] == 1:
				sum += arr[idx - 1]
				n_count += 1
			if x < grid_size - 1 and inside[idx + 1] == 1:
				sum += arr[idx + 1]
				n_count += 1
			if y > 0 and inside[idx - grid_size] == 1:
				sum += arr[idx - grid_size]
				n_count += 1
			if y < grid_size - 1 and inside[idx + grid_size] == 1:
				sum += arr[idx + grid_size]
				n_count += 1
			var avg: float = (sum / float(n_count)) if n_count > 0 else v
			_temp[idx] = lerpf(v, avg, rate) * (1.0 - decay)
	var n: int = arr.size()
	for i in n:
		arr[i] = _temp[i]


func toggle_debug_charge() -> void:
	debug_charge = not debug_charge
	queue_redraw()


func toggle_debug_noise() -> void:
	debug_noise = not debug_noise
	queue_redraw()


func toggle_debug_light() -> void:
	debug_light = not debug_light
	queue_redraw()


func _draw() -> void:
	if not (debug_charge or debug_noise or debug_light):
		return
	var half: Vector2 = Vector2(cell_size, cell_size) * 0.5
	var size_v: Vector2 = Vector2(cell_size + 0.5, cell_size + 0.5)
	for y in grid_size:
		for x in grid_size:
			var idx: int = y * grid_size + x
			if inside[idx] == 0:
				continue
			var rect: Rect2 = Rect2(_grid_to_local(x, y) - half, size_v)
			if debug_light:
				draw_rect(rect, Color(0.95, 0.85, 0.45, light[idx] * 0.18))
			if debug_charge:
				var cv: float = clampf(charge[idx], 0.0, 1.0)
				draw_rect(rect, Color(0.30, 0.65, 1.00, cv * 0.28))
			if debug_noise:
				var nv: float = clampf(noise[idx] * 0.5, 0.0, 1.0)
				draw_rect(rect, Color(1.00, 0.35, 0.40, nv * 0.30))
