extends Node2D
class_name MagneticFieldOverlay

var dish: Node
var _last_should_draw: bool = false


func _ready() -> void:
	top_level = false
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(_delta: float) -> void:
	if dish == null or not is_instance_valid(dish):
		return
	var petri: PetriDish = dish as PetriDish
	if petri == null:
		return
	var should_draw: bool = petri.should_redraw_cell_field_overlay()
	if should_draw or should_draw != _last_should_draw:
		queue_redraw()
	_last_should_draw = should_draw


func _draw() -> void:
	if dish == null or not is_instance_valid(dish):
		return
	var petri: PetriDish = dish as PetriDish
	if petri == null:
		return
	# LEGACY FILE NAME: this overlay now draws the ambient-field reveal plus
	# the main cell-field arc layer. Additional streamline/contour diagnostics
	# are still gated inside PetriDish by debug_magnetic_field.
	petri.draw_ambient_field_reveal_on(self)
	petri.draw_cell_field_arcs_on(self)
