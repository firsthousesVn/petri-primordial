extends RefCounted
class_name CellPort

# Physical contact anchor on a CellBody.
# local_position: body-local point where the contact lives (tip, mid-flat, line-end, etc.)
# local_normal:   outward direction at that point.
# zone_type:      semantic role used by the contact classifier.
#                 One of: "surface", "tip_sharp", "flat", "end", "side",
#                         "inner_curve", "outer_curve", "tip_hook".
# strength:       per-anchor weight, used as a secondary tiebreak in classification.

var local_position: Vector2
var local_normal: Vector2
var zone_type: String
var strength: float


func _init(pos: Vector2 = Vector2.ZERO, normal: Vector2 = Vector2.RIGHT, zone: String = "surface", s: float = 1.0) -> void:
	local_position = pos
	local_normal = normal.normalized() if normal.length() > 0.0001 else Vector2.RIGHT
	zone_type = zone
	strength = s
