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
var ferry := Rect2()
var combo := 0
var hold := 0.0
var required_rule := 0
var ridden := false
var last_checkpoint := Vector2.ZERO
var checkpoint_age := 0.0
var region := 0
var phase := 0
var shift_cd := 0.0
var phase_decks: Array[Rect2] = []

const OFFER := {"lift": 2, "reflect": 3, "chase": 1, "live": 1}

func load_level(level: Array) -> void:
	kind = "" if level[2] == "boss" else level[2]
	region = level[1]
	variant = level[6]
	targets.clear()
	ledges.clear()
	for point in level[7]:
		targets.append(Vector2(point[0], point[1]))
		if point[1] < 488:
			ledges.append(Rect2(point[0] - 100, point[1], 178, 14))
	phase_decks.assign(ledges)
	phase = 0
	shift_cd = 0.0
	if kind == "lift":
		ledges.append(Rect2(385, 412, 156, 14))
		ledges.append(Rect2(714, 319, 135, 14))
	elif variant > 0 and kind in ["chase", "reflect", "echo", "cargo", "live"]:
		ledges.append(Rect2(556, 430, 93, 14))
	if kind == "cross":
		ledges = [Rect2(348, 440, 163, 18), Rect2(568, 403, 153, 18), Rect2(805, 446, 113, 18)]
	cursor = 0
	clock = 0.0
	timing = 0.0
	limit = 23.0 + variant if kind == "chase" else 0.0
	echo = Vector2.ZERO
	cargo = Vector2(320, 488)
	attached = false
	socket = Vector2(282, 488)
	socket_rule = OFFER.get(kind, 0)
	technique = 0
	combo = 0
	hold = 0.0
	ridden = false
	last_checkpoint = Vector2.ZERO
	checkpoint_age = 0.0
	ferry = _ferry_at(0.0) if kind == "ferry" else Rect2()
	_configure_gate()

func _configure_gate() -> void:
	if kind != "key" or not active():
		return
	required_rule = 1 + (cursor + variant) % 3
	socket = Vector2(maxf(251.0, target().x - 137.0), 488.0)
	socket_rule = required_rule

func evacuation() -> void:
	load_level(["", 3, "chase", 5, -1, 0.0, 3, [[487, 488], [747, 405], [1030, 488]]])
	limit = 18.0

func active() -> bool:
	return not kind.is_empty() and cursor < targets.size()

func target() -> Vector2:
	return targets[cursor] if active() else Vector2.ZERO

func surface(next: Vector2, from_y: float, base: float) -> float:
	for i in ledges.size():
		var ledge := ledges[i]
		if kind == "phase" and i % 2 != phase:
			continue
		if next.x >= ledge.position.x and next.x <= ledge.end.x and from_y <= ledge.position.y + 0.5:
			base = minf(base, ledge.position.y)
	if ferry.has_area() and next.x >= ferry.position.x and next.x <= ferry.end.x and from_y <= ferry.position.y + 0.5:
		base = minf(base, ferry.position.y)
	return base

func _ferry_at(t: float) -> Rect2:
	var slide := (1.0 - cos(t * (0.95 + variant * 0.10))) * 0.5
	return Rect2(270.0 + 498.0 * slide, 423.0 - 57.0 * slide, 124.0, 14.0)

func carry_platform(g: Node2D, dt: float) -> void:
	if kind != "ferry":
		return
	var next := _ferry_at(clock + dt)
	if g.grounded and absf(g.p.y - ferry.position.y) < 0.6 and g.p.x >= ferry.position.x and g.p.x <= ferry.end.x:
		g.p += next.position - ferry.position
		ridden = true
	ferry = next

func near(a: Vector2, b: Vector2, width: float, height := 46.0) -> bool:
	return absf(a.x - b.x) <= width and absf(a.y - b.y) <= height

func steal(g: Node2D) -> bool:
	if not active():
		return false
	if kind in ["phase", "blink"]:
		if shift_cd > 0.0:
			return false
		if kind == "blink":
			if not near(g.p, target(), 310.0, 192.0):
				g._report("Anchor out of range", "Move inside the anchor ring before shifting.", 1.0)
				return false
			var previous: Vector2 = g.p
			g.p = target()
			g.v = Vector2.ZERO
			echo = previous
			g.wire_from = previous - Vector2(0, 22)
			g.wire_to = g.p - Vector2(0, 22)
			g.wire_color = Color("#90ddde")
			g.wire_time = 0.5
			step(g)
		else:
			phase = 1 - phase
			g.shift_phase = phase
			g._impact(g.p - Vector2(0, 22), Color("#90ddde") if phase == 0 else Color("#f2c389"))
		shift_cd = 0.48
		g.route_shifts += 1
		g.phase_transition = 0.55
		g.audio_rig.fire("steal")
		return true
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
		if kind == "key":
			g.player_rule = required_rule
			g.charge = true
			g.steals += 1
			g.audio_rig.fire("rule")
			return true
		var previous: int = g.player_rule
		g.player_rule = socket_rule
		socket_rule = previous if previous > 0 else OFFER.get(kind, 1)
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
	if kind == "combo" and near(g.p, target(), 99.0, 70.0):
		combo = (combo if timing > 0.0 else 0) + 1
		timing = 1.05 - variant * 0.08
		g.audio_rig.fire("hit")
		g._roll_drop(target() - Vector2(0, 20))
		if combo == 3:
			step(g)
		return
	if kind in ["break", "belt", "timer"] and near(g.p, target(), 105.0, 75.0):
		if kind != "timer" or cursor > 0 or timing > 0.0:
			g._roll_drop(target() - Vector2(0, 20))
			combo += 1
			g.audio_rig.fire("hit")
			var required := 3 if kind == "break" else (2 if kind == "belt" else 1)
			if combo >= required:
				step(g)

func use_at_gate(g: Node2D) -> bool:
	if kind != "key" or not active() or not near(g.p, target(), 94.0, 72.0) or g.player_rule != required_rule:
		return false
	step(g)
	return true

func step(g: Node2D) -> void:
	var mark := target()
	last_checkpoint = mark
	checkpoint_age = 1.0
	cursor += 1
	technique += 1
	combo = 0
	hold = 0.0
	g.charge = true
	g._impact(mark - Vector2(0, 22), Color("#a5efc4"))
	g.audio_rig.fire("objective")
	_configure_gate()
	if cursor == targets.size():
		g.finish_route()

func hazard() -> Rect2:
	if kind == "sensor" or (kind == "cargo" and region == 5):
		var x := 550.0 + cos(clock * (1.32 + variant * 0.16)) * 304.0
		return Rect2(x - 12.0, 447.0, 24.0, 53.0)
	if not kind in ["break", "live", "belt", "cargo", "chase"]:
		return Rect2()
	var lane := (int(clock / 1.8) + variant) % 3
	if kind == "break":
		# The first lock is safe. Teach a single readable sweep on the way to lock two.
		return Rect2(658.0 + lane * 12.0, 458.0, 93, 42.0)
	elif region in [2, 6, 7] and kind != "chase":
		lane = 2 - lane
	var width := 100.0 + variant * 22.0
	return Rect2(373.0 + lane * 173.0, 447.0 if kind != "chase" else 462.0, width, 56.0)

func hazard_live() -> bool:
	return kind == "sensor" or (kind == "cargo" and region == 5) or fmod(clock, 1.8) >= hazard_ignition()

func hazard_ignition() -> float:
	return 1.36 if kind == "break" else 1.18

func hazard_charge() -> float:
	return clampf(fmod(clock, 1.8) / hazard_ignition(), 0.0, 1.0)

func pulse_box() -> Rect2:
	if not active():
		return Rect2()
	if kind == "evade":
		return Rect2(target() - Vector2(59, 64), Vector2(118, 72))
	if kind == "hold" and echo != Vector2.ZERO:
		return Rect2(echo - Vector2(49, 65), Vector2(98, 75))
	return Rect2()

func pulse_phase() -> float:
	return fmod(clock, 2.6)

func _dodge_drill(g: Node2D, dt: float) -> void:
	var phase := pulse_phase()
	if phase >= 1.84 and phase - dt < 1.84:
		g.audio_rig.fire("warn")
		if kind == "hold":
			echo = g.p
	if phase >= 2.35 and phase - dt < 2.35:
		if kind == "evade" and g.dodge_protection > 0.0 and near(g.p, target(), 118, 83):
			step(g)
		else:
			var box := pulse_box()
			if box.has_area():
				g._check_hurt(box, box.get_center().x)
		echo = Vector2.ZERO
	if kind == "hold" and g.mode == "fight":
		var inside := near(g.p, target(), 74.0, 54.0)
		hold = clampf(hold + dt * (1.0 if inside else -0.55), 0.0, 2.1)
		if hold >= 2.1:
			step(g)

func tick(g: Node2D, dt: float) -> void:
	if not active():
		return
	clock += dt
	shift_cd = maxf(0.0, shift_cd - dt)
	timing = maxf(0.0, timing - dt)
	checkpoint_age = maxf(0.0, checkpoint_age - dt)
	var point := target()
	if limit > 0.0 and clock >= limit:
		g.last_failure = "Borrow RUSH from the socket to cross the closing gates."
		g.mode = "lost"
		g.audio_rig.fire("hurt")
		return
	var box := hazard()
	if box.has_area() and kind != "sensor":
		var phase := fmod(clock, 1.8)
		var cue := hazard_ignition() - 0.30
		if phase >= cue and phase - dt < cue and box.grow(190).has_point(g.p):
			g.audio_rig.fire("warn")
	if box.has_area() and hazard_live():
		var previous: int = g.hp
		g._check_hurt(box, box.get_center().x, true)
		if g.hp < previous and attached:
			attached = false
		if g.mode != "fight":
			return
	if kind == "belt" and g.grounded and g.p.x > 350.0:
		g.p.x = clampf(g.p.x + dt * (-105 if g.p.x < 700.0 else 70), g.LEFT, g.RIGHT)
	if kind in ["hold", "evade"]:
		_dodge_drill(g, dt)
	elif kind == "timer":
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
	elif kind == "phase":
		if phase == cursor % 2 and near(g.p, point, 44.0, 32.0):
			step(g)
	elif kind in ["cross", "chase", "lift", "live", "sensor", "ferry"] and near(g.p, point, 44.0, 32.0):
		if kind == "ferry" and not ridden:
			return
		if kind == "sensor" and absf(box.get_center().x - point.x) < 82.0:
			return
		step(g)
	if kind == "lift" and g.grounded:
		g.charge = true
