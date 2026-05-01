extends Resource
class_name CellSignature

@export_enum("round", "triangle", "line", "crescent", "spiral", "wedge") var geometry_type: String = "round"
@export_enum("pearl", "glass", "soft") var material_type: String = "pearl"

@export var rhythm_frequency: float = 1.0
@export var rhythm_phase: float = 0.0

@export var charge_capacity: float = 1.0
@export var charge: float = 0.0
@export var noise: float = 0.0
@export var stability: float = 1.0

@export var impulse_bias: float = 0.0
@export var storage_bias: float = 0.0
@export var rhythm_bias: float = 0.0

@export var memory_tags: Array[String] = []


func summary() -> String:
	return "[%s/%s] cap=%.2f q=%.2f n=%.2f stab=%.2f | imp=%.2f stor=%.2f rhy=%.2f | f=%.2fHz φ=%.2f | tags=%s" % [
		geometry_type, material_type,
		charge_capacity, charge, noise, stability,
		impulse_bias, storage_bias, rhythm_bias,
		rhythm_frequency, rhythm_phase,
		str(memory_tags),
	]
