extends RefCounted
const POSES := preload("res://assets/operative-poses.png")
const ANCHORS := [Vector2(230, 406), Vector2(265, 384), Vector2(268, 388), Vector2(260, 357), Vector2(245, 390), Vector2(262, 378), Vector2(270, 387), Vector2(252, 388)]
## Articulated operative. Each pose is driven by real movement and combat state.
static func paint(c: CanvasItem, at: Vector2, s: float, face: float, t: float, velocity: Vector2, grounded: bool, swing: float, hurt: float, dash: float, tint: Color, reduced: bool, landing := 0.0) -> void:
	var pose := 0
	if hurt > 0.18:
		pose = 7
	elif swing > 0.0:
		pose = 6
	elif dash > 0.0:
		pose = 5
	elif not grounded:
		pose = 3 if velocity.y < 0.0 else 4
	elif absf(velocity.x) > 30.0:
		pose = 1 + int(t * 10.0) % 2
	var cell := Vector2(POSES.get_width() / 4.0, POSES.get_height() / 2.0)
	var region := Rect2(Vector2(pose % 4, pose / 4) * cell, cell)
	var unit := s * 0.172
	var origin := at + Vector2(-ANCHORS[pose].x * face * unit, -ANCHORS[pose].y * unit)
	var rect := Rect2(origin, Vector2(cell.x * face, cell.y) * unit)
	c.draw_texture_rect_region(POSES, rect, region, Color("#ffd0b7") if hurt > 0.18 else Color.WHITE)
