extends RefCounted

var kind := ""
var variant := 0
var targets: Array[Vector2] = []
var ledges: Array[Rect2] = []
var cursor := 0
var clock := 0.0
var limit := 0.0
var timing := 0.0
var echo := Vector2.ZERO
var cargo := Vector2.ZERO
var attached := false
var socket := Vector2.ZERO
var socket_rule := 0
var plate := Vector2(280, 488)
var technique := 0

func load_level(level: Array) -> void:
	kind = "" if level[2] == "boss" else level[2]
	variant = level[6]
	targets.clear()
	ledges.clear()
	for point in level[7]:
		targets.append(Vector2(point[0], point[1]))
		if point[1] < 488:
			ledges.append(Rect2(point[0] - 100, point[1], 178, 14))
	if kind == "lift":
		ledges.append(Rect2(385, 412, 156, 14))
		ledges.append(Rect2(714, 319, 135, 14))
	elif variant > 0 and kind in ["chase", "reflect", "echo", "cargo", "live"]:
		ledges.append(Rect2(556, 430, 93, 14))
	if kind == "cross":
		ledges = [Rect2(408, 431, 135, 18), Rect2(676, 397, 130, 18)]
	cursor = 0
	clock = 0.0
	timing = 0.0
	limit = 28.0 if kind == "chase" else 0.0
	echo = Vector2.ZERO
	cargo = Vector2(320, 488)
	attached = false
	socket = Vector2(282, 488)
	socket_rule = {"lift": 2, "reflect": 3, "chase": 1, "live": 1}.get(kind, 0)
	technique = 0

func evacuation() -> void:
	load_level(["", 3, "chase", 5, -1, 0.0, 3, [[487, 488], [747, 405], [1030, 488]]])
	limit = 18.0

func active() -> bool:
	return not kind.is_empty() and cursor < targets.size()

func target() -> Vector2:
	return targets[cursor] if active() else Vector2.ZERO

func surface(next: Vector2, from_y: float, base: float) -> float:
	for ledge in ledges:
		if next.x >= ledge.position.x and next.x <= ledge.end.x and from_y <= ledge.position.y + 0.5:
			base = minf(base, ledge.position.y)
	return base

func near(a: Vector2, b: Vector2, width: float, height := 46.0) -> bool:
	return absf(a.x - b.x) <= width and absf(a.y - b.y) <= height

func steal(g: Node2D) -> bool:
	if not active():
		return false
	if kind == "swap" and near(g.p, target(), 102.0):
		var offered: int = 1 + (cursor + variant) % 3
		if offered == g.player_rule:
			offered = offered % 3 + 1
		g.player_rule = offered
		g.charge = true
		g.steals += 1
		step(g)
		return true
	if socket_rule > 0 and near(g.p, socket, 99.0):
		var previous: int = g.player_rule
		g.player_rule = socket_rule
		socket_rule = previous if previous > 0 else {"lift": 2, "reflect": 3, "chase": 1, "live": 1}.get(kind, 1)
		g.charge = true
		g.steals += 1
		g.audio_rig.fire("rule")
		return true
	return false

func strike(g: Node2D) -> void:
	if not active():
		return
	if kind == "cargo" and near(g.p, cargo, 88.0):
		attached = true
		g.audio_rig.fire("rule")
	if kind in ["break", "belt", "timer"] and near(g.p, target(), 105.0, 75.0):
		if kind != "timer" or cursor > 0 or timing > 0.0:
			g._roll_drop(target() - Vector2(0, 20))
			step(g)

func step(g: Node2D) -> void:
	var mark := target()
	cursor += 1
	technique += 1
	g.charge = true
	g._impact(mark - Vector2(0, 22), Color("#a5efc4"))
	if cursor == targets.size():
		g._finish_arena()

func hazard() -> Rect2:
	if not kind in ["break", "live", "belt", "cargo", "chase"]:
		return Rect2()
	var lane := (int(clock / 1.8) + variant) % 3
	var width := 100.0 + variant * 22.0
	return Rect2(373.0 + lane * 173.0, 447.0 if kind != "chase" else 462.0, width, 56.0)

func tick(g: Node2D, dt: float) -> void:
	if not active():
		return
	clock += dt
	timing = maxf(0.0, timing - dt)
	var point := target()
	if limit > 0.0 and clock >= limit:
		g.mode = "lost"
		g.audio_rig.fire("hurt")
		return
	var box := hazard()
	if box.has_area() and fmod(clock, 1.8) >= 1.18:
		var previous: int = g.hp
		g._check_hurt(box, box.get_center().x, true)
		if g.hp < previous and attached:
			attached = false
		if g.mode != "fight":
			return
	if kind == "belt" and g.grounded and g.p.x > 350.0:
		g.p.x = clampf(g.p.x + dt * (-105 if g.p.x < 700.0 else 70), g.LEFT, g.RIGHT)
	if kind == "timer":
		if near(g.p, plate, 62.0):
			timing = 5.0
		if cursor > 0 and near(g.p, point, 40.0):
			step(g)
	elif kind == "cargo":
		if attached:
			cargo = g.p
			if near(cargo, point, 42.0):
				step(g)
	elif kind == "reflect" or kind == "echo":
		var phase := fmod(clock, 2.8)
		if phase < dt:
			g.charge = true
			echo = Vector2.ZERO
		elif phase >= 1.85 and phase - dt < 1.85:
			echo = g.p
		elif phase >= 2.43 and phase - dt < 2.43:
			var pulse := Rect2(echo.x - 53.0, echo.y - 66.0, 106.0, 80.0)
			if kind == "reflect" and g.guard > 0.0 and near(echo, point, 115.0) and near(g.p, echo, 70.0):
				step(g)
			elif kind == "echo" and near(echo, point, 74.0):
				step(g)
			if g.mode == "fight":
				g._check_hurt(pulse, echo.x)
	elif kind in ["cross", "chase", "lift", "live"] and near(g.p, point, 44.0, 32.0):
		step(g)
	if kind == "lift" and g.grounded:
		g.charge = true
