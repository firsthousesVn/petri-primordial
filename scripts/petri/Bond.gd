extends RefCounted
class_name Bond

var a: CellBody
var b: CellBody
var anchor_a: int
var anchor_b: int
var local_anchor_a: Vector2
var local_anchor_b: Vector2
var bond_type: String
var strength: float
var strain: float = 0.0
var rest_distance: float = 0.0
var target_overlap: float = 0.0
var age: float = 0.0
var broken: bool = false
var capture_timer: float = 0.0
var hold_timer: float = 0.0
var over_strain_time: float = 0.0


func _init(
	cell_a: CellBody,
	cell_b: CellBody,
	idx_a: int,
	idx_b: int,
	type: String,
	s: float,
	rest: float,
	overlap: float,
) -> void:
	a = cell_a
	b = cell_b
	anchor_a = idx_a
	anchor_b = idx_b
	local_anchor_a = a.ports[idx_a].local_position
	local_anchor_b = b.ports[idx_b].local_position
	bond_type = type
	strength = s
	rest_distance = rest
	target_overlap = overlap


func endpoint_a() -> Vector2:
	return a.position + local_anchor_a.rotated(a.rotation)


func endpoint_b() -> Vector2:
	return b.position + local_anchor_b.rotated(b.rotation)


func midpoint() -> Vector2:
	return (endpoint_a() + endpoint_b()) * 0.5
