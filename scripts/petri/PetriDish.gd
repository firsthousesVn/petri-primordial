extends Node2D
class_name PetriDish

const DISH_RADIUS: float = 320.0
const BOUNDARY_COLOR: Color = Color(0.18, 0.18, 0.20, 1.0)
const BOUNDARY_WIDTH: float = 3.0
const SURFACE_COLOR: Color = Color(0.96, 0.94, 0.88, 1.0)

@onready var debug_label: Label = $HUD/DebugLabel
@onready var camera: Camera2D = $Camera2D

var cells: Array = []
var _hud_accum: float = 0.0
const HUD_INTERVAL: float = 0.25


func _ready() -> void:
	camera.position = Vector2.ZERO
	camera.make_current()
	queue_redraw()


func _process(delta: float) -> void:
	_hud_accum += delta
	if _hud_accum >= HUD_INTERVAL:
		_hud_accum = 0.0
		_update_debug()


func _draw() -> void:
	draw_circle(Vector2.ZERO, DISH_RADIUS, SURFACE_COLOR)
	draw_arc(Vector2.ZERO, DISH_RADIUS, 0.0, TAU, 96, BOUNDARY_COLOR, BOUNDARY_WIDTH, true)


func _update_debug() -> void:
	var count: int = cells.size()
	var avg_charge: float = 0.0
	var avg_noise: float = 0.0
	if count > 0:
		var sum_c: float = 0.0
		var sum_n: float = 0.0
		for c in cells:
			sum_c += c.charge
			sum_n += c.noise
		avg_charge = sum_c / count
		avg_noise = sum_n / count
	debug_label.text = "cells: %d\navg charge: %.3f\navg noise: %.3f\nfps: %d" % [
		count, avg_charge, avg_noise, Engine.get_frames_per_second()
	]
