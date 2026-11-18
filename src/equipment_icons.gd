extends RefCounted

static func _path(canvas: CanvasItem, center: Vector2, unit: float, points: Array, color: Color, closed := false) -> void:
	var path := PackedVector2Array()
	for point in points:
		path.append(center + Vector2(point[0], point[1]) * unit)
	if closed:
		path.append(path[0])
	canvas.draw_polyline(path, color, maxf(1.3, unit * 1.55), true)

static func paint_rule(canvas: CanvasItem, center: Vector2, unit: float, color: Color, rule: int) -> void:
	match rule:
		1:
			_path(canvas, center, unit, [[-9, -5], [-2, 0], [-9, 5]], color)
			_path(canvas, center, unit, [[-1, -8], [9, 0], [-1, 8]], color)
		2:
			_path(canvas, center, unit, [[-8, 0], [0, -8], [8, 0]], color)
			_path(canvas, center, unit, [[-5, 6], [0, 1], [5, 6]], color)
		3:
			_path(canvas, center, unit, [[-8, -6], [0, -9], [8, -6], [7, 3], [0, 9], [-7, 3]], color, true)
			_path(canvas, center, unit, [[-4, -1], [0, 3], [4, -2]], color)
		_:
			canvas.draw_circle(center, 5.0 * unit, color, false, 1.5, true)

static func paint(canvas: CanvasItem, center: Vector2, unit: float, color: Color, id: int) -> void:
	match id:
		0: # Oil and blade
			_path(canvas, center, unit, [[-6, 7], [7, -8], [8, -2], [-1, 7]], color, true)
			canvas.draw_circle(center + Vector2(-7, -4) * unit, 2.4 * unit, color, true, -1, true)
		1: # Woven running tread
			_path(canvas, center, unit, [[-8, 4], [-5, -4], [2, -4], [5, 1], [9, 3], [9, 7], [-9, 7]], color, true)
			_path(canvas, center, unit, [[-3, 0], [2, 0]], color)
		2: # Roller bearing
			canvas.draw_circle(center, 8.0 * unit, color, false, 1.5, true)
			canvas.draw_circle(center, 3.0 * unit, color, false, 1.5, true)
			for i in 6:
				canvas.draw_circle(center + Vector2.from_angle(i * TAU / 6.0) * 5.5 * unit, 0.9 * unit, color)
		3: # Boot spring
			_path(canvas, center, unit, [[-7, -7], [7, -7], [-5, -2], [6, 1], [-5, 5], [7, 7]], color)
		4: # Flat coil
			_path(canvas, center, unit, [[-9, 4], [-6, -5], [-2, 5], [2, -5], [6, 5], [9, -4]], color)
		5: # Blade's arc
			canvas.draw_arc(center, 8.0 * unit, -1.45, 1.45, 25, color, 1.6, true)
			_path(canvas, center, unit, [[-8, 6], [4, 0], [-8, -6]], color, true)
		6: # Segmented armor
			paint_rule(canvas, center, unit, color, 3)
			_path(canvas, center, unit, [[-7, 0], [7, 0]], color)
		7: # Prism
			_path(canvas, center, unit, [[-8, 6], [0, -8], [8, 6]], color, true)
			_path(canvas, center, unit, [[-9, -2], [1, 1], [9, -3]], color)
		8: # Cell
			_path(canvas, center, unit, [[-8, -5], [7, -5], [7, -3], [9, -3], [9, 3], [7, 3], [7, 5], [-8, 5]], color, true)
			_path(canvas, center, unit, [[1, -3], [-2, 0], [2, 0], [-1, 3]], color)
		9: # Chemical flask
			_path(canvas, center, unit, [[-4, -8], [4, -8], [3, -1], [8, 7], [-8, 7], [-3, -1]], color, true)
			_path(canvas, center, unit, [[-5, 3], [5, 3]], color)
		10: # Blunted blade
			_path(canvas, center, unit, [[-7, 8], [-9, 5], [3, -8], [7, -4], [4, 0], [0, 0], [0, 3]], color, true)
		11: # Magnet
			_path(canvas, center, unit, [[-8, -7], [-8, 1], [-5, 6], [0, 8], [5, 6], [8, 1], [8, -7]], color)
			_path(canvas, center, unit, [[-9, -3], [-5, -3]], color)
			_path(canvas, center, unit, [[5, -3], [9, -3]], color)
		12: # Bound joint
			canvas.draw_circle(center, 4.5 * unit, color, false, 1.6, true)
			_path(canvas, center, unit, [[-8, -8], [-4, -4]], color)
			_path(canvas, center, unit, [[4, 4], [8, 8]], color)
			_path(canvas, center, unit, [[-8, 3], [3, -8]], color)
		13: # Weight
			_path(canvas, center, unit, [[-5, -4], [5, -4], [8, 7], [-8, 7]], color, true)
			canvas.draw_arc(center + Vector2(0, -4) * unit, 3.0 * unit, -PI, 0.0, 12, color, 1.5, true)
		14: # Broken chain
			_path(canvas, center, unit, [[-4, 1], [-8, 5], [-5, 8], [-1, 4]], color)
			_path(canvas, center, unit, [[1, -4], [5, -8], [8, -5], [4, -1]], color)
			_path(canvas, center, unit, [[-7, -3], [-3, -2], [-4, -7]], color)
		15: # Cracked lens
			canvas.draw_circle(center, 8.0 * unit, color, false, 1.5, true)
			_path(canvas, center, unit, [[2, -8], [-2, -1], [2, 0], [-3, 7]], color)
		16: # Weld patch
			_path(canvas, center, unit, [[-8, -6], [8, -6], [8, 6], [-8, 6]], color, true)
			_path(canvas, center, unit, [[-4, 0], [4, 0]], color)
			_path(canvas, center, unit, [[0, -4], [0, 4]], color)
		17: # Insulation grid
			for offset in [-4, 0, 4]:
				_path(canvas, center, unit, [[-9, offset + 2], [-3, offset - 3], [9, offset - 3], [3, offset + 2]], color, true)
		18: # Locked circuit
			_path(canvas, center, unit, [[-7, -1], [7, -1], [7, 7], [-7, 7]], color, true)
			canvas.draw_arc(center + Vector2(0, -1) * unit, 4.0 * unit, -PI, 0.0, 16, color, 1.5, true)
			canvas.draw_circle(center + Vector2(0, 3) * unit, 1.25 * unit, color, true, -1, true)
		19: # Brake teeth
			_path(canvas, center, unit, [[-8, 6], [-8, -6], [-4, 3], [0, -6], [4, 3], [8, -6], [8, 6]], color, true)
