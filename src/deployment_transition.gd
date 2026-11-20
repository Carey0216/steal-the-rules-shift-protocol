extends Control
var elapsed := 0.0
var heading := ""
var title := ""
var tone := Color("#dcb777")
var font: Font
var face: Font

func _ready() -> void:
	size = Vector2(1152, 648)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= 0.62:
		get_parent().queue_free()

func _draw() -> void:
	var open := clampf((elapsed - 0.17) / 0.44, 0.0, 1.0)
	open = 1.0 - pow(1.0 - open, 3.0)
	var offset := open * 480.0
	var alpha := 1.0 - open
	var shade := Color("#081b26")
	draw_rect(Rect2(0, -offset, 1152, 325), shade)
	draw_rect(Rect2(0, 323 + offset, 1152, 325), shade)
	draw_line(Vector2(0, 322 - offset), Vector2(1152, 322 - offset), Color(tone, alpha), 2.0, true)
	draw_line(Vector2(0, 326 + offset), Vector2(1152, 326 + offset), Color(tone, alpha), 2.0, true)
	var center := Vector2(173, 324)
	for radius in [39, 47, 65]:
		draw_arc(center, radius, -PI + open * 0.4, PI - open * 0.4, 44, Color(tone, alpha * 0.8), 1.2, true)
	var arrows := PackedVector2Array([center + Vector2(-22, -10), center + Vector2(23, -10), center + Vector2(14, -18)])
	draw_polyline(arrows, Color(tone, alpha), 2.5, true)
	var reverse := PackedVector2Array([center + Vector2(22, 10), center + Vector2(-23, 10), center + Vector2(-14, 18)])
	draw_polyline(reverse, Color(tone, alpha), 2.5, true)
	if font != null and face != null:
		draw_string(font, Vector2(286, 307), heading, HORIZONTAL_ALIGNMENT_LEFT, 780, 16, Color(tone, alpha))
		draw_string(face, Vector2(284, 359), title, HORIZONTAL_ALIGNMENT_LEFT, 780, 35, Color("#f6edda", alpha))
