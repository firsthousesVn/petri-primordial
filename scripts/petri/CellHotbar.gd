extends Control
class_name CellHotbar

const SLOT_WIDTH: float = 148.0
const SLOT_HEIGHT: float = 74.0
const SLOT_GAP: float = 14.0
const BOTTOM_PAD: float = 20.0
const LABEL_PAD: float = 14.0
const ICON_RADIUS: float = 16.0

var entries: Array[Dictionary] = []
var selected_index: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func set_entries(next_entries: Array, next_selected: int) -> void:
	entries.clear()
	for item in next_entries:
		entries.append((item as Dictionary).duplicate(true))
	selected_index = clampi(next_selected, 0, maxi(entries.size() - 1, 0))
	queue_redraw()


func set_selected_index(next_selected: int) -> void:
	selected_index = clampi(next_selected, 0, maxi(entries.size() - 1, 0))
	queue_redraw()


func _draw() -> void:
	if entries.is_empty():
		return
	var count: int = entries.size()
	var total_width: float = count * SLOT_WIDTH + maxi(0, count - 1) * SLOT_GAP
	var start: Vector2 = Vector2((size.x - total_width) * 0.5, size.y - SLOT_HEIGHT - BOTTOM_PAD)
	var strip_rect: Rect2 = Rect2(
		Vector2(start.x - 18.0, start.y - LABEL_PAD - 8.0),
		Vector2(total_width + 36.0, SLOT_HEIGHT + LABEL_PAD + 18.0),
	)
	draw_rect(strip_rect, Color(0.02, 0.025, 0.045, 0.72), true)
	draw_rect(strip_rect, Color(0.30, 0.38, 0.56, 0.38), false, 1.2, true)
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	if font != null:
		var title: String = "Selected: %s" % _selected_name()
		var title_size: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size + 2)
		var title_pos: Vector2 = Vector2((size.x - title_size.x) * 0.5, start.y - 10.0)
		draw_string(font, title_pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size + 2, Color(0.88, 0.92, 1.0, 0.92))
	for i in count:
		var slot: Dictionary = entries[i]
		var rect: Rect2 = Rect2(start + Vector2(i * (SLOT_WIDTH + SLOT_GAP), 0.0), Vector2(SLOT_WIDTH, SLOT_HEIGHT))
		var active: bool = i == selected_index
		_draw_slot(rect, slot, active)


func _draw_slot(rect: Rect2, slot: Dictionary, active: bool) -> void:
	var fill: Color = Color(0.05, 0.065, 0.105, 0.92)
	var edge: Color = Color(0.36, 0.44, 0.62, 0.55)
	if active:
		fill = Color(0.11, 0.14, 0.21, 0.96)
		edge = Color(0.92, 0.74, 0.36, 0.95)
	draw_rect(rect, fill, true)
	draw_rect(rect, edge, false, 1.6, true)
	var glow_rect: Rect2 = rect.grow(-4.0)
	if active:
		draw_rect(glow_rect, Color(0.95, 0.86, 0.50, 0.08), true)
	var font: Font = get_theme_default_font()
	var font_size: int = get_theme_default_font_size()
	var key_text: String = str(slot.get("key", "?"))
	var label: String = str(slot.get("label", "Cell"))
	var kind: String = str(slot.get("kind", "round"))
	if font != null:
		draw_string(font, rect.position + Vector2(12.0, 20.0), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size + 3, Color(1.0, 0.96, 0.86, 0.96))
		draw_string(font, rect.position + Vector2(12.0, rect.size.y - 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.84, 0.89, 1.0, 0.96))
	var icon_center: Vector2 = rect.position + Vector2(rect.size.x - 36.0, rect.size.y * 0.5)
	_draw_icon(kind, icon_center, active)


func _draw_icon(kind: String, center: Vector2, active: bool) -> void:
	var tint: Color = Color(0.72, 0.84, 1.0, 0.92)
	if active:
		tint = Color(0.98, 0.90, 0.62, 0.98)
	match kind:
		"triangle":
			var tip: Vector2 = center + Vector2(0.0, -ICON_RADIUS * 0.95)
			var left: Vector2 = center + Vector2(-ICON_RADIUS * 0.82, ICON_RADIUS * 0.72)
			var right: Vector2 = center + Vector2(ICON_RADIUS * 0.82, ICON_RADIUS * 0.72)
			draw_colored_polygon(PackedVector2Array([tip, right, left]), Color(tint.r, tint.g, tint.b, 0.18))
			draw_line(tip, left, tint, 1.6, true)
			draw_line(tip, right, Color(tint.r, tint.g, tint.b, 0.48), 1.0, true)
			draw_line(left, right, Color(tint.r, tint.g, tint.b, 0.48), 1.0, true)
			draw_circle(tip, 2.0, Color(1.0, 0.98, 0.88, 0.95))
		"line":
			var a: Vector2 = center + Vector2(0.0, -ICON_RADIUS * 1.1)
			var b: Vector2 = center + Vector2(0.0, ICON_RADIUS * 1.1)
			draw_line(a, b, Color(tint.r, tint.g, tint.b, 0.28), 6.0, true)
			draw_line(a, b, tint, 1.6, true)
			draw_circle(a, 2.0, Color(1.0, 1.0, 1.0, 0.86))
			draw_circle(b, 2.0, Color(1.0, 1.0, 1.0, 0.86))
		"crescent":
			draw_arc(center, ICON_RADIUS, -PI * 0.82, PI * 0.82, 28, Color(tint.r, tint.g, tint.b, 0.55), 2.0, true)
			draw_arc(center, ICON_RADIUS * 0.68, -PI * 0.70, PI * 0.70, 24, tint, 1.4, true)
			draw_arc(center, ICON_RADIUS * 0.90, -PI * 0.52, PI * 0.52, 20, Color(tint.r, tint.g, tint.b, 0.20), 3.0, true)
		"spiral":
			# Side-view coil: 4 stacked flattened ellipses.
			var loops: int = 4
			var loop_w: float = ICON_RADIUS * 1.05
			var ellipse_h: float = ICON_RADIUS * 0.20
			var total_h: float = ICON_RADIUS * 1.70
			for i in loops:
				var t: float = float(i) / float(loops - 1)
				var y: float = lerpf(-total_h * 0.5, total_h * 0.5, t)
				var pts: PackedVector2Array = PackedVector2Array()
				for k in range(17):
					var ang: float = (float(k) / 16.0) * TAU
					pts.append(center + Vector2(cos(ang) * loop_w * 0.5, y + sin(ang) * ellipse_h))
				var bright: float = 0.55 + 0.45 * (1.0 if (i % 2 == 0) else -1.0)
				bright = clampf(bright, 0.30, 1.0)
				draw_polyline(pts, Color(tint.r, tint.g, tint.b, 0.30 + 0.55 * bright * 0.5), 1.3, true)
		_:
			draw_circle(center, ICON_RADIUS * 0.82, Color(tint.r, tint.g, tint.b, 0.14))
			draw_circle(center, ICON_RADIUS * 0.58, Color(tint.r, tint.g, tint.b, 0.30))
			draw_arc(center, ICON_RADIUS * 0.82, 0.0, TAU, 28, tint, 1.4, true)
			draw_circle(center + Vector2(-ICON_RADIUS * 0.22, -ICON_RADIUS * 0.22), ICON_RADIUS * 0.14, Color(1.0, 1.0, 1.0, 0.82))


func _selected_name() -> String:
	if entries.is_empty():
		return ""
	return str(entries[clampi(selected_index, 0, entries.size() - 1)].get("label", ""))
