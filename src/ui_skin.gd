extends StyleBox
## Native, resolution-independent cut-metal controls; no image text.
var fill := Color("#223941")
var edge := Color("#78938f")
var primary := false
var lit := false
var disabled := false
var focus_only := false

func _get_minimum_size() -> Vector2:
	return Vector2(16, 16)

func _draw(item: RID, at: Rect2) -> void:
	var r := at.grow(-0.5)
	var c := minf(12.0, r.size.y * 0.22)
	var points := PackedVector2Array([
		r.position + Vector2(c, 0), Vector2(r.end.x, r.position.y),
		r.end - Vector2(0, c), r.end - Vector2(c, 0),
		Vector2(r.position.x, r.end.y), r.position + Vector2(0, c),
	])
	var seam := PackedVector2Array(points)
	seam.append(points[0])
	if not focus_only:
		RenderingServer.canvas_item_add_polygon(item, points, PackedColorArray([fill]))
	RenderingServer.canvas_item_add_polyline(item, seam, PackedColorArray([edge]), 1.5 if focus_only or lit else 1.0, true)
	if focus_only:
		return
	var alpha := 0.19 if disabled else (0.62 if lit else 0.25)
	var stripe := Color(edge, alpha)
	RenderingServer.canvas_item_add_line(item, r.position + Vector2(c + 8, 3), Vector2(r.end.x - 12, r.position.y + 3), stripe, 1.0, true)
	if primary:
		var tip := r.end - Vector2(19, r.size.y * 0.5)
		var arrow := PackedVector2Array([tip + Vector2(-4, -5), tip + Vector2(1, 0), tip + Vector2(-4, 5)])
		RenderingServer.canvas_item_add_polyline(item, arrow, PackedColorArray([Color("#183b3b")]), 1.6, true)
