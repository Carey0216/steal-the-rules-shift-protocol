extends RefCounted

const Locale = preload("res://src/locale.gd")
const Menu = preload("res://src/title_menu.gd")
const Levels = preload("res://src/levels.gd")
const Gear = preload("res://src/gear.gd")
const Icons = preload("res://src/equipment_icons.gd")
const OVERLOOK = preload("res://assets/gate-overlook.webp")

const INK := Color("#0b131b")
const PAPER := Color("#f5e9cd")
const TEXT := Color("#ecede5")
const DIM := Color("#a6b5bc")
const GREEN := Color("#81fbd2")
const RED := Color("#ff9469")
const LINE := Color("#364853")
const W := 1152.0
const H := 648.0
var g: Node2D
var accent: Color
var sec := 0
var district := 0

func paint(game: Node2D) -> void:
	g = game
	sec = g.stage if g.mode != "title" else 0
	district = 0
	accent = g.ENCOUNTERS[sec].accent
	if g.mode != "title" and g.mission_sector:
		district = Levels.TABLE[g.sector_index][1]
		accent = Levels.TINTS[district]
	if g.mode == "title":
		_title()
		return
	var shift := Vector2.ZERO
	if not g.reduced_motion:
		shift = Vector2(sin(g.clock * 142.0), cos(g.clock * 173.0) * 0.58) * g.shake
	_background(g.floor_y, g.clock)
	g.draw_set_transform(shift)
	_floor(g.floor_y)
	if g.route.kind.is_empty():
		_warnings()
	_world_fx(false)
	if not g.route.kind.is_empty():
		_route()
	else:
		_boss(g.b, g.b_facing, 1.0, g.boss_rule, false)
		if g.mission_sector and sec == 2:
			_marker(Vector2(952, g.floor_y - 30), "#", accent)
		for lock in g.boss_locks:
			_marker(lock - Vector2(0, 30), "!", accent)
	_player(g.p, g.facing, 1.0)
	_equipment()
	_world_fx(true)
	g.draw_set_transform(Vector2.ZERO)
	if not g.record_demo:
		_hud()
	if g.mode == "brief":
		_briefing()

func _marker(center: Vector2, glyph: String, tint: Color) -> void:
	g.draw_circle(center + Vector2(0, 3), 30, Color("#080f199d"), true, -1, true)
	g.draw_circle(center, 28, Color("#1a2a3be8"), true, -1, true)
	g.draw_circle(center, 27, Color(tint, 0.74), false, 1.5, true)
	g.draw_arc(center, 22, -2.97, -1.25, 18, Color(tint, 0.24), 1.1, true)
	_poly([center + Vector2(-6, 25), center + Vector2(6, 25), center + Vector2(0, 33)], tint)
	if not glyph.is_empty():
		_text(glyph, center.x, center.y + 5, 13, tint, true, HORIZONTAL_ALIGNMENT_CENTER)

func _route() -> void:
	var route: RefCounted = g.route
	for deck in route.ledges:
		_rect(deck.position.x, deck.position.y, deck.size.x, deck.size.y, LINE)
		_rect(deck.position.x, deck.position.y, deck.size.x, 2, accent)
		for x in range(int(deck.position.x) + 12, int(deck.end.x) - 3, 16):
			_line(Vector2(x, deck.position.y + 5), Vector2(x - 4, deck.end.y - 2), INK)
	if not route.active():
		return
	if route.ferry.has_area():
		var deck: Rect2 = route.ferry
		_rect(deck.position.x, deck.position.y, deck.size.x, deck.size.y, Color("#334f62"))
		_line(deck.position, Vector2(deck.end.x, deck.position.y), accent, 2.0)
		_poly([deck.position + Vector2(8, 14), deck.position + Vector2(25, 32), deck.position + Vector2(96, 32), deck.position + Vector2(116, 14)], Color("#182d3b"))
		for x in [25, 98]:
			g.draw_circle(deck.position + Vector2(x, 16), 3.0, accent)
	var zone: Rect2 = route.hazard()
	if zone.has_area():
		var live: bool = route.hazard_live()
		_rect(zone.position.x, zone.position.y, zone.size.x, zone.size.y, _soft(RED, 0.36 if live else 0.13))
		for x in range(int(zone.position.x), int(zone.end.x), 12):
			_line(Vector2(x, zone.end.y - 16), Vector2(x + 9, zone.position.y + 7), RED if live else _soft(RED, 0.4))
	if route.echo != Vector2.ZERO and route.kind in ["echo", "reflect"]:
		_rect(route.echo.x - 53, route.echo.y - 66, 106, 66, _soft(accent, 0.14))
		_line(route.echo + Vector2(0, -145), route.echo, RED, 2.0)
	for i in range(route.cursor + 1, route.targets.size()):
		var future: Vector2 = route.targets[i]
		_line(future + Vector2(0, -15), future, DIM, 2.0)
	var symbols := {"echo": "!", "reflect": "E", "swap": "Q", "break": "J", "timer": "J", "belt": "J", "combo": "J", "hold": "●", "evade": "K"}
	var target: Vector2 = route.target() - Vector2(0, 34)
	_marker(target, symbols.get(route.kind, "" if route.kind == "key" else ">"), accent)
	if route.kind == "key":
		Icons.paint_rule(g, target, 1.5, g.RULE_COLORS[route.required_rule], route.required_rule)
	if route.kind == "combo":
		for i in range(3):
			_rect(target.x - 18.0 + 13.0 * i, target.y - 37.0, 10.0, 4.0, accent if i < route.combo and route.timing > 0.0 else LINE)
	if route.kind == "hold" and route.hold > 0.0:
		g.draw_arc(target, 36.0, -PI / 2.0, -PI / 2.0 + TAU * route.hold / 2.1, 40, GREEN, 3.0, true)
	if route.kind in ["evade", "hold"] and route.pulse_phase() >= 1.84:
		var pulse: Rect2 = route.pulse_box()
		if pulse.has_area():
			g.draw_rect(pulse, _soft(RED, 0.16 if route.pulse_phase() < 2.35 else 0.5))
			_columns(pulse.position.x, pulse.size.x, pulse.end.y, 12, RED)
	if route.socket_rule > 0:
		var center: Vector2 = route.socket - Vector2(0, 30)
		var tint: Color = g.RULE_COLORS[route.socket_rule]
		_marker(center, "", tint)
		Icons.paint_rule(g, center, 1.5, tint, route.socket_rule)
	if route.kind == "cargo":
		_marker(route.cargo - Vector2(-23 if route.attached else 0, 23), "+" if route.attached else "J", GREEN)
	if route.kind == "timer" and route.cursor == 0:
		_rect(route.plate.x - 60.0, route.plate.y - 5.0, 120, 5, GREEN if route.timing > 0.0 else RED)
		if route.timing > 0.0:
			_rect(route.target().x - 36.0, route.target().y - 74.0, 72.0, 3, LINE)
			_rect(route.target().x - 36.0, route.target().y - 74.0, 72.0 * route.timing / 5.0, 3, GREEN)

func _equipment() -> void:
	if g.drop.is_empty():
		return
	var id: int = g.drop.id
	var tint: Color = g.equipment_color(id)
	var origin: Vector2 = g.drop.at
	if not g.reduced_motion:
		origin.y += sin(g.clock * 7.0) * 3.5
	_marker(origin, "", tint)
	Icons.paint(g, origin + Vector2(0, 1.6), 1.67, Color("#08131f"), id)
	Icons.paint(g, origin, 1.67, tint.lerp(PAPER, 0.19), id)
	g.draw_arc(origin, 32.0, -PI * 0.5, -PI * 0.5 + TAU * g.drop.time / Gear.DROP_LIFETIME, 40, tint, 2.0, true)
	var polarity := origin + Vector2(25, -22)
	g.draw_circle(polarity, 7.0, INK)
	_line(polarity - Vector2(3, 0), polarity + Vector2(3, 0), tint, 1.6)
	if Gear.ITEMS[id][3] > 0:
		_line(polarity - Vector2(0, 3), polarity + Vector2(0, 3), tint, 1.6)

func _rect(x: float, y: float, w: float, h: float, color: Color, solid := true, thickness := 1.0) -> void:
	g.draw_rect(Rect2(x, y, w, h), color, solid, -1.0 if solid else thickness)

func _line(a: Vector2, b: Vector2, color: Color, width := 1.0) -> void:
	g.draw_line(a, b, color, width, true)

func _poly(points: Array, color: Color) -> void:
	g.draw_colored_polygon(PackedVector2Array(points), color)

func _shape(pos: Vector2, face: float, scale: float, coords: Array, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(coords.size() / 2):
		pts.append(pos + Vector2(coords[2 * i] * face, coords[2 * i + 1]) * scale)
	g.draw_colored_polygon(pts, color)

func _text(message: String, x: float, y: float, size: int, color: Color, big := false, align := HORIZONTAL_ALIGNMENT_LEFT, max_width := 0.0, max_size := 256) -> void:
	var index := Locale.current()
	var font := Locale.face(0 if size >= 100 else index, big)
	message = Locale.text(message)
	if not g.record_demo and size < 100:
		size = roundi(size * Menu.SCALES[g.text_size_index])
	size = mini(size, max_size)
	var width := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if max_width > 0 and width > max_width:
		size = maxi(10, floori(size * max_width / width))
		width = font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= width
	elif align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= width * 0.5
	g.draw_string(font, Vector2(x, y), message, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _soft(color: Color, opacity: float) -> Color:
	return Color(color, clampf(opacity, 0.0, 1.0))

func _columns(x: float, width: float, y: float, len: float, color: Color) -> void:
	for i in int(width / 12.0):
		var cx := x + i * 12.0
		_line(Vector2(cx, y + len), Vector2(cx + 7, y), color, 2.0)

func _background(floor: float, age: float) -> void:
	var darkest := Color("#0b161f").lerp(accent, 0.018)
	var lit := Color("#21343c").lerp(accent, 0.125)
	for i in 34:
		var t := float(i) / 33.0
		_rect(0, i * 20.0, W, 21.0, darkest.lerp(lit, sin(t * PI * 0.79) * 0.77))
	var move := fposmod(age * (3.0 if not g.reduced_motion else 0.0), 193.0)
	for i in range(-1, 8):
		var x := i * 193.0 - move
		_rect(x, 0, 2, floor, _soft(accent, 0.065))
		_rect(x + 4, 0, 34, floor, _soft(INK, 0.34))
		_rect(x + 9, 120, 5, floor - 120, _soft(accent, 0.07))
		_poly([Vector2(x + 34, 132), Vector2(x + 91, 204), Vector2(x + 91, 221), Vector2(x + 34, 151)], _soft(INK, 0.65))
		_poly([Vector2(x + 38, 153), Vector2(x + 76, 195), Vector2(x + 76, 198), Vector2(x + 38, 157)], _soft(accent, 0.135))
		_rect(x + 48, 268, 110, floor - 278, _soft(INK, 0.43))
		_rect(x + 48, 268, 110, floor - 278, _soft(accent, 0.08), false)
		_rect(x + 64, 285, 8, 3, _soft(accent, 0.52))
		_rect(x + 58, 294, 67, 2, _soft(accent, 0.14))
		_rect(x + 131, 311, 12, floor - 324, _soft(INK, 0.52))
	_rect(0, 205, W, 7, _soft(INK, 0.48))
	_rect(0, 220, W, 1, _soft(accent, 0.13))
	_rect(0, 441, W, 7, _soft(INK, 0.57))
	_rect(0, 450, W, 2, _soft(accent, 0.075))
	var moon := Vector2(804 if sec == 0 else 702, 318 if sec == 0 else 286)
	for i in range(10, 0, -1):
		g.draw_circle(moon, i * 27, _soft(accent, 0.023), true, -1, true)
	for i in range(1, 5):
		g.draw_arc(moon, 61 + i * 22, 0, TAU, 72, _soft(accent, 0.12 if i % 2 else 0.23), 1.0, true)
	_line(moon - Vector2(170, 0), moon + Vector2(170, 0), _soft(accent, 0.18))
	_line(moon - Vector2(0, 170), moon + Vector2(0, 170), _soft(accent, 0.18))
	if sec == 1:
		for i in 8:
			var x := 146.0 + i * 127.0
			_line(Vector2(x, 133), Vector2(x + 42, 390), _soft(accent, 0.21), 2.0)
			_line(Vector2(x + 42, 390), Vector2(x + 90, 456), _soft(accent, 0.10), 2.0)
	elif sec >= 2:
		for i in 6:
			var x := 55.0 + i * 218.0
			_rect(x, 152, 92, 10, _soft(accent, 0.20))
			_rect(x + 8, 164, 3, 256, _soft(accent, 0.13))
			_rect(x + 84, 164, 3, 256, _soft(accent, 0.13))
			if sec == 2:
				_line(Vector2(x + 46, 171), Vector2(x + 46, 438), _soft(accent, 0.27), 3)
			elif sec == 3:
				for rib in 12:
					_rect(x + 13, 411 - rib * 13, 67, 4, _soft(accent, 0.12 + rib * 0.009))
			elif sec == 4:
				_poly([Vector2(x, 200), Vector2(x + 89, 225), Vector2(x + 89, 386), Vector2(x, 423)], _soft(accent, 0.13))
	_district_scenery(floor, age)
	for i in 72:
		var x := fposmod(i * 337.1 + (age * (5.0 + i % 4) if not g.reduced_motion else 0.0), W)
		var y := 146.0 + fposmod(i * 69.7 - (age * (9 + i % 3) if not g.reduced_motion else 0.0), 365.0)
		_rect(x, y, 1 + i % 3, 1, _soft(accent, 0.10 + (i % 5) * 0.035))
	for i in 57:
		_rect(0, 4 + i * 10.0, W, 1, _soft(INK, 0.13))
	if not g.record_demo:
		_text(Locale.text("SUBLEVEL") + "  /  " + str(sec + 1).pad_zeros(2), 59, 176, 12, _soft(DIM, 0.52))
		_text("AUTHORIZED MACHINES ONLY", 1093, 176, 12, _soft(DIM, 0.52), false, HORIZONTAL_ALIGNMENT_RIGHT)

func _district_scenery(floor: float, time: float) -> void:
	if not g.mission_sector:
		return
	var motion := 0.0 if g.reduced_motion else time
	match district:
		0, 6:
			for i in 5:
				var x := 85.0 + i * 248.0
				_poly([Vector2(x, 252), Vector2(x + 98, 195), Vector2(x + 119, 201), Vector2(x + 14, 267)], _soft(INK, 0.64))
				_line(Vector2(x + 113, 205), Vector2(x + 114, 386), _soft(accent, 0.33), 1.6)
				_rect(x + 92, 383, 45, 9, _soft(accent, 0.25))
		1, 7:
			for i in 7:
				var x := 99.0 + i * 154.0
				var height := 51.0 + 15.0 * (i % 3)
				_rect(x, 408 - height, 67, height, _soft(accent, 0.085))
				_line(Vector2(x - 18, 408), Vector2(x + 89, 408), _soft(accent, 0.24), 1.1)
				_rect(x + 13, 395 - height, 8, 8, _soft(accent, 0.29 + 0.11 * sin(motion * 1.8 + i * 0.8)))
		2, 4:
			for i in 4:
				var x := 147.0 + i * 262.0
				var silo := Vector2(x, 348)
				g.draw_arc(silo, 49, PI, TAU, 35, _soft(accent, 0.25), 2.0, true)
				_rect(x - 49, 348, 98, floor - 357, _soft(accent, 0.075))
				_line(Vector2(x - 49, 348), Vector2(x - 49, floor - 13), _soft(accent, 0.22))
				for row in 4:
					_line(Vector2(x - 50, 355 + row * 20), Vector2(x + 49, 355 + row * 20), _soft(accent, 0.16))
			if district == 4:
				for row in 4:
					for i in 15:
						_rect(fposmod(i * 97.0 + motion * float(8 + row), W), 451 + row * 8.0, 58.0, 1, _soft(accent, 0.30 - row * 0.042))
		3, 5:
			for i in 6:
				var x := 33.0 + i * 207.0
				_poly([Vector2(x, 238), Vector2(x + 129, 213), Vector2(x + 129, 426), Vector2(x, 452)], _soft(accent, 0.105))
				_line(Vector2(x + 17, 424), Vector2(x + 108, 252), _soft(accent, 0.22), 2.0)
				_line(Vector2(x + 23, 431), Vector2(x + 113, 289), _soft(accent, 0.13))

func _floor(y: float) -> void:
	_rect(-25, y, W + 50, 190, Color("#101921"))
	_rect(-25, y, W + 50, 2, accent.lerp(PAPER, 0.46))
	_rect(-25, y + 2, W + 50, 8, accent.darkened(0.69))
	for i in range(-1, 20):
		var x := i * 64.0
		_poly([Vector2(x, y + 12), Vector2(x + 61, y + 12), Vector2(x + 51, y + 42), Vector2(x + 3, y + 42)], Color("#23313b"))
		_line(Vector2(x + 57, y + 15), Vector2(x + 49, y + 37), _soft(accent, 0.22), 2.0)
		_rect(x + 10, y + 23, 25, 1, _soft(accent, 0.15))
	_rect(0, y + 49, W, 2, _soft(accent, 0.15))
	_columns(58, 91, y + 4, 8, _soft(accent, 0.75))
	_columns(1000, 91, y + 4, 8, _soft(accent, 0.75))
	if g.floor_broken and g.mode != "title":
		var top: float = g.BASE
		var left: float = g.DECK_LEFT
		var right: float = g.DECK_RIGHT
		_poly([Vector2(0, top), Vector2(left, top), Vector2(left - 18, top + 22), Vector2(left - 52, top + 32), Vector2(0, top + 32)], Color("#23333d"))
		_poly([Vector2(right, top), Vector2(W, top), Vector2(W, top + 32), Vector2(right + 46, top + 32), Vector2(right + 17, top + 23)], Color("#23333d"))
		_line(Vector2(0, top), Vector2(left, top), accent, 3.0)
		_line(Vector2(right, top), Vector2(W, top), accent, 3.0)
		_columns(left - 97, 95, top + 5, 12, _soft(accent, 0.6))
		_columns(right + 13, 95, top + 5, 12, _soft(accent, 0.6))

func _boss(base: Vector2, face: float, scale: float, rule: int, poster: bool) -> void:
	var pos := base
	var rolling: float = 0.0 if g.reduced_motion else sin(g.clock * 5.0) * (2.0 if g.state != "exposed" else 0.7)
	if not poster and g.state == "dead":
		scale *= 0.92
		pos.y += 20
	pos.y += rolling
	var color: Color = g.RULE_COLORS[rule]
	if g.state in ["exposed", "reboot"] and not poster:
		color = GREEN if g.state == "exposed" else g.wire_color
	if g.boss_flash > 0.07 and not poster and not g.reduced_motion:
		color = PAPER
	var darkest := Color("#101d27")
	var shell := Color("#43535b").lerp(accent, 0.22)
	var plate := Color("#718087").lerp(accent, 0.35)
	var edge := plate.lightened(0.24)
	var core := pos + Vector2(0, -52) * scale
	for k in range(5, 0, -1):
		g.draw_circle(core, (21 + k * 15) * scale, _soft(color, 0.045), true, -1, true)
	# The Warden has a wedge helmet and counterweight legs; the Lattice uses suspended wings.
	match sec:
		0:
			_shape(pos, face, scale, [-88,-42,-60,-83,-10,-106,56,-104,83,-75,84,-37,44,-16,-65,-18], darkest)
			_shape(pos, face, scale, [-57,-68,-12,-101,52,-97,74,-75,58,-59,-56,-55], shell)
			_shape(pos, face, scale, [-12,-101,52,-97,74,-75,9,-80,-51,-67], plate)
			_shape(pos, face, scale, [58,-75,105,-48,100,-28,64,-22,41,-47], darkest)
			_shape(pos, face, scale, [58,-72,99,-48,84,-41,48,-47], color.darkened(0.22))
			_shape(pos, face, scale, [-94,-45,-69,-59,-46,-40,-48,-13,-92,-15,-109,-29], shell)
			_shape(pos, face, scale, [-75,-24,-39,-26,-29,-5,-49,2,-93,1,-103,-8], plate)
			_shape(pos, face, scale, [22,-27,58,-30,73,-12,64,1,24,2,11,-9], shell)
			_shape(pos, face, scale, [-47,-55,39,-61,37,-44,-48,-38], darkest)
			_shape(pos, face, scale, [24,-89,58,-86,68,-77,23,-81], color)
		1:
			_shape(pos, face, scale, [-26,-91,6,-105,37,-84,43,-34,17,-9,-10,-11,-34,-40], darkest)
			_shape(pos, face, scale, [-25,-85,11,-99,35,-78,30,-34,-4,-20,-28,-42], plate)
			for wing in [-1.0, 1.0]:
				var flap := -5.0 * sin(g.clock * 7.0) if g.b.y < g.floor_y - 40 and not g.reduced_motion else 0.0
				var wpos := pos + Vector2(0, flap * scale)
				_shape(wpos, wing, scale, [25,-69,97,-105,131,-88,119,-67,102,-40,37,-31], darkest)
				_shape(wpos, wing, scale, [31,-65,96,-99,125,-86,107,-71,34,-42], shell)
				_shape(wpos, wing, scale, [63,-66,113,-83,115,-77,61,-56], color)
				_shape(wpos, wing, scale, [81,-46,106,-51,114,-32,95,-18,76,-31], plate)
				_shape(wpos, wing, scale, [84,-22,107,-26,96,-10,87,-12], color)
			_shape(pos, face, scale, [-13,-85,16,-90,26,-74,-9,-71], darkest)
			_shape(pos, face, scale, [-7,-85,13,-87,21,-78,-7,-77], color)
		_:
			_shape(pos, face, scale, [-94,-18,-89,-89,-61,-121,-31,-126,-32,-60,-49,-11], shell)
			_shape(pos, face, scale, [94,-18,89,-89,61,-121,31,-126,32,-60,49,-11], shell)
			_shape(pos, face, scale, [-61,-118,-34,-123,-39,-78,-77,-66,-87,-88], plate)
			_shape(pos, face, scale, [61,-118,34,-123,39,-78,77,-66,87,-88], plate)
			_shape(pos, face, scale, [-58,-92,-22,-123,18,-123,52,-96,66,-35,21,1,-38,-2,-66,-34], darkest)
			_shape(pos, face, scale, [-32,-94,-17,-116,15,-116,35,-95,20,-67,-29,-67], plate)
			_shape(pos, face, scale, [-3,-116,14,-116,31,-96,8,-93,-22,-96], edge)
			_shape(pos, face, scale, [-53,-22,-32,-1,31,0,57,-21,39,-32,-39,-34], shell)
			_shape(pos, face, scale, [-24,-89,25,-89,17,-80,-17,-80], color)
			for x in [-74, 74]:
				_line(pos + Vector2(x, -61) * scale, pos + Vector2(x * 0.87, -33) * scale, color, 3.0 * scale)
			match sec:
				2:
					for side in [-1.0, 1.0]:
						_shape(pos, side, scale, [42,-98,71,-125,102,-125,112,-111,110,-67,82,-62], shell)
						_line(pos + Vector2(82 * side, -112) * scale, pos + Vector2(91 * side, -74) * scale, color, 5.0 * scale)
				3:
					_shape(pos, face, scale, [-110,-36,-77,-65,81,-65,106,-39,98,-10,-109,-11], shell)
					for vent in 10:
						var x := -81.0 + vent * 17.0
						_line(pos + Vector2(x, -48) * scale, pos + Vector2(x - 5, -25) * scale, color.darkened(0.2), 3.0 * scale)
				4:
					g.draw_arc(core, 79 * scale, -PI * 0.9, PI * 0.1, 32, color, 2.5 * scale, true)
					g.draw_arc(core, 79 * scale, PI * 0.1, PI * 1.1, 32, _soft(color, 0.32), 2.0 * scale, true)
	# Every rig uses the same socket. Open cores physically expand and display a range ring.
	var exposed: bool = g.state == "exposed" and not poster
	var dead: bool = g.state == "dead" and not poster
	var r := (20.0 if exposed else 13.0) * scale
	g.draw_circle(core, r + 8 * scale, darkest, true, -1, true)
	g.draw_circle(core, r + 3 * scale, _soft(color, 0.50 if not dead else 0.15), false, 2.0 * scale, true)
	if not dead:
		g.draw_circle(core, r, color.darkened(0.38) if not exposed else color, true, -1, true)
		g.draw_circle(core, r * 0.45, color.lightened(0.52), true, -1, true)
	if exposed:
		var in_range: bool = g.can_shift()
		var spread := 28.0 + (3.0 * sin(g.clock * 9.0) if not g.reduced_motion else 0.0)
		_line(core + Vector2(-spread, -18), core + Vector2(-spread - 12, 0), color, 2.0)
		_line(core + Vector2(-spread - 12, 0), core + Vector2(-spread, 18), color, 2.0)
		_line(core + Vector2(spread, -18), core + Vector2(spread + 12, 0), color, 2.0)
		_line(core + Vector2(spread + 12, 0), core + Vector2(spread, 18), color, 2.0)
		var radius := 48.0 if not in_range else 58.0
		g.draw_arc(core, radius, -PI * 0.5, -PI * 0.5 + TAU * maxf(0.01, g.state_time / g.state_total), 48, color, 2.0, true)
		if in_range:
			_rect(core.x - 55, core.y - 99, 110, 26, GREEN)
			_text("RB / SHIFT" if g.last_device == "pad" else "SHIFT / Q", core.x, core.y - 81, 13, INK, false, HORIZONTAL_ALIGNMENT_CENTER)
	if rule == g.Rule.AEGIS and g.state in ["windup", "active"] and not poster:
		g.draw_arc(core, 82, -PI, PI, 48, _soft(color, 0.66), 3, true)
		g.draw_circle(core, 82, _soft(color, 0.10), true, -1, true)

func _player(at: Vector2, face: float, scale: float) -> void:
	var color: Color = g.RULE_COLORS[g.player_rule] if g.player_rule != g.Rule.EMPTY else GREEN
	var moving: bool = absf(g.v.x) > 25 and g.grounded
	var step := sin(g.clock * 30.0) * 5.0 if moving and not g.reduced_motion else 0.0
	var pose := at + Vector2(0, -absf(step) * 0.43)
	var metal := PAPER if g.hit_flash < 0.17 else RED
	_line(at + Vector2(-23, 0) * scale, at + Vector2(23, 0) * scale, _soft(INK, 0.6), 3.0 * scale)
	_shape(pose, face, scale, [-12,-15,-5,-19,-3,-5,-8+step,0,-16+step,0], Color("#698792"))
	_shape(pose, face, scale, [4,-17,11,-19,11,-6,17-step,0,5-step,0], metal)
	_shape(pose, face, scale, [-15,-27,9,-28,13,-20,9,-11,-13,-11,-19,-17], Color("#bcb9a8"))
	_shape(pose, face, scale, [-13,-49,10,-48,18,-41,16,-29,-13,-26,-20,-34,-20,-42], INK)
	_shape(pose, face, scale, [-13,-46,9,-46,15,-41,12,-34,-13,-34,-17,-38], metal)
	_shape(pose, face, scale, [-9,-41,14,-40,15,-35,-9,-36], Color("#22333c"))
	_shape(pose, face, scale, [1,-40,14,-39,14,-36,1,-37], color)
	_shape(pose, face, scale, [-13,-48,-15,-54,-12,-55,-8,-47], color)
	_shape(pose, face, scale, [-13,-26,-5,-25,-6,-18,-15,-17], color)
	_shape(pose, face, scale, [10,-25,18,-23,20,-17,13,-16,7,-20], metal)
	if g.lift > 0.0:
		var length := (31 + (10.0 * sin(g.clock * 31) if not g.reduced_motion else 0.0)) * scale
		_poly([at - Vector2(12, 4), at + Vector2(11, -4), at + Vector2(-1, length)], _soft(color, 0.40))
	if g.guard > 0.0:
		g.draw_arc(at + Vector2(0, -25), 38, -PI, PI, 38, color, 3, true)
		g.draw_circle(at + Vector2(0, -25), 38, _soft(color, 0.18), true, -1, true)
	if g.dodge_protection > 0.0:
		g.draw_arc(at + Vector2(0, -25), 28, 0.08, TAU - 0.08, 28, _soft(PAPER, 0.85), 1.5, true)
	if g.swing > 0:
		var hand := at + Vector2(9 * face, -24) * scale
		var end := hand + Vector2(face * (62 + g.swing * 85), -14 - g.swing * 60) * scale
		_line(hand, end, _soft(color, 0.33), 14.0 * scale)
		_line(hand, end, color, 3.0 * scale)
		var angle := 0.0 if face > 0 else PI
		g.draw_arc(hand, 66 * scale, angle - 0.63, angle + 0.49, 32, _soft(color, g.swing * 3.5), 2.0, true)

func _warnings() -> void:
	for hazard in g.environmental_zones():
		var area: Rect2 = hazard.box
		var tint: Color = hazard.color
		g.draw_rect(area, _soft(tint, 0.28 if hazard.live else 0.09))
		g.draw_rect(area, _soft(tint, 0.94 if hazard.live else 0.67), false, 2)
		_columns(area.position.x, area.size.x, area.end.y - 10, 10, _soft(tint, 0.86))
		if hazard.live:
			for i in range(0, int(area.size.x), 19):
				_line(area.position + Vector2(i, 1), area.position + Vector2(i + 10, area.size.y - 1), _soft(tint, 0.36), 2)
	var progress: float = 1.0 - g.state_time / maxf(g.state_total, 0.1)
	for box in g.zones:
		g.draw_rect(box, _soft(RED, 0.08 + progress * 0.23))
		g.draw_rect(box, _soft(RED, 0.76), false, 2.0)
		_columns(box.position.x, box.size.x, box.end.y - 8, 8, _soft(RED, 0.87))
	for z in g.hazards:
		if z.delay > 0.0:
			continue
		var box: Rect2 = z.box
		var glow: Color = z.c
		g.draw_rect(box, _soft(glow, 0.29))
		if absf(z.v) > 1.0:
			var s := signf(z.v)
			_poly([Vector2(box.get_center().x - 25 * s, box.end.y), Vector2(box.get_center().x - 8 * s, box.position.y), Vector2(box.get_center().x + 23 * s, box.end.y)], glow)
		else:
			var x := box.get_center().x
			for i in 5:
				var dx := (i - 2) * 12
				_line(Vector2(x + dx, box.position.y), Vector2(x + dx, box.end.y), _soft(glow, 0.7 - absf(i - 2) * 0.19), 3 if i == 2 else 1)
		g.draw_rect(box, _soft(glow, 0.63), false, 1.0)

func _world_fx(foreground: bool) -> void:
	if not foreground:
		if not g.reduced_motion:
			for trail in g.trails:
				_rect(trail.at.x - 15, trail.at.y - 38, 30, 35, _soft(trail.c, trail.t * 0.96))
		for ring in g.rings:
			g.draw_arc(ring.at, maxf(4.0, ring.r * (1.0 - ring.t / 0.68)), 0, TAU, 55, _soft(ring.c, ring.t * (0.53 if g.reduced_motion else 1.1)), 2.0, true)
		return
	for i in g.sparks.size():
		if g.reduced_motion and i % 3 != 0:
			continue
		var s: Dictionary = g.sparks[i]
		var color := _soft(s.c, s.t / s.max)
		_rect(s.at.x, s.at.y, s.size, s.size * 0.53, color)
	if g.wire_time > 0.0:
		var points := PackedVector2Array()
		for i in 15:
			var t := i / 14.0
			var pt: Vector2 = g.wire_from.lerp(g.wire_to, t)
			pt.y += sin(t * PI) * (sin(i * 3.74 + g.clock * 25) * 14.0 if not g.reduced_motion else 0.0)
			points.append(pt)
		g.draw_polyline(points, _soft(g.wire_color, g.wire_time * 0.52), 14, true)
		g.draw_polyline(points, _soft(g.wire_color, g.wire_time * 1.75), 3, true)
		g.draw_polyline(points, _soft(PAPER, g.wire_time * 1.45), 1, true)

func _hud() -> void:
	_rect(0, 0, W, 136, Color("#141f2d"))
	_rect(0, 135, W, 1, Color("#7d7567"))
	_rect(326, 0, 500, 2, accent)
	_poly([Vector2(316, 10), Vector2(836, 10), Vector2(809, 63), Vector2(343, 63)], Color("#1e2b38"))
	_text("SHIFT PROTOCOL", 42, 35, 27, PAPER, true, HORIZONTAL_ALIGNMENT_LEFT, 270, 30)
	_text(Locale.text("SECTOR") + " " + ("%02d" % (g.sector_index + 1) if g.mission_sector else Locale.text(g.ENCOUNTERS[sec].sector)), 42, 55, 12, DIM)
	_text(g.timecode(g.run_time), 1110, 34, 19, TEXT, false, HORIZONTAL_ALIGNMENT_RIGHT)
	_text("RUN CLOCK", 1110, 55, 11, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
	var level: Array = Levels.TABLE[g.sector_index]
	_text(level[0] if g.mission_sector else g.ENCOUNTERS[sec].name, 576, 41, 32, PAPER, true, HORIZONTAL_ALIGNMENT_CENTER, 480, 34)
	_rect(326, 51, 500, 8, LINE)
	var fraction: float = float(g.route.cursor) / g.route.targets.size() if not g.route.kind.is_empty() else float(g.boss_hp) / g.boss_max_hp
	if fraction > 0:
		_rect(326, 51, 500 * fraction, 8, accent)
	for i in range(1, 10):
		_rect(326 + i * 50, 51, 1, 8, INK)
	_line(Vector2(42, 68), Vector2(1110, 68), LINE)
	_text("HULL", 42, 91, 12, DIM)
	for i in g.MAX_HP:
		_rect(42 + i * 22, 100, 17, 13, GREEN if i < g.hp else LINE)
	_rect(42, 120, 149, 3, LINE)
	_rect(42, 120, 149 * clampf(1.0 - g.dash_cd / g.DODGE_COOLDOWN, 0.0, 1.0), 3, PAPER)
	_text("Dodge", 207, 124, 10, DIM)
	var slot_color: Color = g.RULE_COLORS[g.player_rule]
	_text("YOUR RULE", 315, 91, 12, DIM)
	Icons.paint_rule(g, Vector2(325, 114), 0.85, slot_color, g.player_rule)
	_text(g.RULE_NAMES[g.player_rule], 344, 123, 26, slot_color, true, HORIZONTAL_ALIGNMENT_LEFT, 105, 28)
	var charge_label := "Y" if g.last_device == "pad" else "E"
	if g.player_rule != g.Rule.EMPTY:
		_text(Locale.text("[%s] READY") % charge_label if g.charge else "RECHARGING", 450, 113, 12, slot_color if g.charge else DIM)
	_text("SHIFT LINK", 692, 91, 12, DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	var link := "IN RANGE" if g.can_shift() else ("APPROACH" if g.state == "exposed" and g.boss_rule != g.Rule.EMPTY else "WAIT")
	_text(link, 692, 115, 18, GREEN if g.can_shift() else DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	if not g.route.kind.is_empty():
		var readout := "%d / %d" % [g.route.cursor, g.route.targets.size()]
		if g.route.limit > 0.0:
			readout = "%s   %0.1fs" % [readout, maxf(0, g.route.limit - g.route.clock)]
		_text("Checkpoints", 1110, 91, 12, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
		_text(readout, 1110, 123, 22, accent, true, HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		_text("BOSS RULE", 1110, 91, 12, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
		var tint: Color = g.RULE_COLORS[g.boss_rule]
		Icons.paint_rule(g, Vector2(1100, 113), 0.85, tint, g.boss_rule)
		_text(g.RULE_NAMES[g.boss_rule], 1082, 123, 26, tint, true, HORIZONTAL_ALIGNMENT_RIGHT, 234, 28)
	_rect(0, 568, W, 80, Color("#141f2d"))
	_rect(0, 569, 6, 79, accent)
	_line(Vector2(0, 568), Vector2(W, 568), LINE)
	var sub := Locale.text(_instruction())
	if g.last_device == "pad":
		sub = sub.replace(" / E", " / Y")
	_text(sub, 42, 596, 16, TEXT)
	var inputs := "STICK MOVE    A JUMP    X STRIKE    B DODGE    RB SHIFT    Y RULE" if g.last_device == "pad" else "A/D MOVE     SPACE JUMP     J STRIKE     K DODGE     SHIFT STEAL     E RULE"
	_text(inputs, 42, 627, 12, DIM, false, HORIZONTAL_ALIGNMENT_LEFT, 751)
	_text("M AUDIO  /  V MOTION  /  ESC PAUSE", 1110, 627, 11, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT, 300)
	var n := 0
	for id in g.effects:
		var x := 1108.0 - n * 85.0
		var tint: Color = g.equipment_color(id)
		_rect(x - 81, 541, 81, 24, _soft(INK, 0.93))
		_rect(x - 81, 563, clampf(g.effects[id] / Gear.ITEMS[id][2], 0.0, 1.0) * 81, 2, tint)
		Icons.paint(g, Vector2(x - 66, 553), 0.63, tint, id)
		_text("%.1fs" % g.effects[id], x - 32, 558, 12, tint, true, HORIZONTAL_ALIGNMENT_CENTER)
		n += 1
	if g.practice >= 0:
		_text("Practice", 576, 175, 22, GREEN, true, HORIZONTAL_ALIGNMENT_CENTER)
	elif g.state == "windup":
		var move_label: String = g.move_name
		if g.rail_return:
			move_label = "RETURN SWEEP"
		elif g.overclock_attack:
			move_label = Locale.text("OVERCLOCK") + " / " + Locale.text(move_label)
		_text(move_label, 576, 176, 25, RED, true, HORIZONTAL_ALIGNMENT_CENTER, 655)
	elif g.notice_time > 0.0:
		_text(g.notice, 576, 179, 35, g.wire_color if g.wire_time > 0.0 else PAPER, true, HORIZONTAL_ALIGNMENT_CENTER, 990, 38)
		_text(g.notice_sub, 576, 201, 13, TEXT, false, HORIZONTAL_ALIGNMENT_CENTER)
	elif g.state == "exposed" and g.boss_rule != g.Rule.EMPTY:
		var near_core := Locale.text("You gain %s   /   Boss gains %s") % [Locale.text(g.RULE_NAMES[g.boss_rule]), Locale.text(g.RULE_NAMES[g.player_rule])]
		_rect(288, 141, 576, 44, _soft(INK, 0.91))
		var ready := GREEN if g.can_shift() else DIM
		_rect(288, 182, 576, 2, ready)
		_text(near_core, 576, 170, 16, ready, false, HORIZONTAL_ALIGNMENT_CENTER, 552)
	if g.hit_flash > 0.0 and not g.reduced_motion:
		_rect(4, 139, W - 8, 424, _soft(RED, g.hit_flash * 0.9), false, 4.0)

func _instruction() -> String:
	if g.route.active():
		return Levels.GOALS[g.route.kind]
	if not g.boss_locks.is_empty():
		return "Lure the recorded strike onto each lock."
	if g.mission_sector and sec == 2 and g.state == "idle":
		return "Reflect with AEGIS or strike the right relay with RUSH."
	if g.practice >= 0:
		if g.notice_time > 0.0:
			return g.notice_sub
		return [
			"Run and jump to the right.", "Face the core and strike.", "Dodge as the charge reaches you.",
			"Approach the open core and press Shift.", "Face the core and press E to use RUSH.",
		][g.practice]
	if g.mode == "clear":
		return "Sector clear. Your rule carries into the next fight."
	if g.state == "exposed":
		if g.boss_rule == g.Rule.EMPTY:
			return "Reserve booting. Strike while the core is unprotected."
		if g.can_shift():
			return "Core open. Steal now, or keep your current rule and strike."
		return "Core open. Move in for SHIFT or a close strike."
	if g.state == "windup":
		match g.move_name:
			"RAIL CUT": return "Rail Cut: jump over the charge, or dodge through it."
			"SKY ANVIL": return "Sky Anvil: leave the target zone, then jump the shockwave."
			"PULSE LATTICE": return "Pulse Lattice: find a gap between the marked columns."
			_: return "Dead Circuit: jump its shockwave. The reserve rule is next."
	match g.player_rule:
		g.Rule.RUSH: return "RUSH / E: slash through the boss from range. Aim before firing."
		g.Rule.LIFT: return "LIFT / E: jet upward. Strike on the ascent to pierce armor."
		g.Rule.AEGIS: return "AEGIS / E: catch a hit near the boss to reflect 8 damage."
		_: return "Read the warning. Survive the attack. Take the open core."

func _briefing() -> void:
	_rect(0, 136, W, 432, _soft(INK, 0.70))
	var x := 244.0
	var y := 198.0
	var encounter: Dictionary = g.ENCOUNTERS[sec]
	_rect(x, y, 664, 296, INK)
	_rect(x, y, 664, 296, LINE, false)
	_rect(x, y, 4, 296, accent)
	_text(Locale.text("INTRUSION") + "  /  " + Locale.text(encounter.sector), x + 34, y + 41, 14, accent)
	_text(Levels.TABLE[g.sector_index][0] if g.mission_sector else encounter.name, x + 32, y + 113, 63, PAPER, true, HORIZONTAL_ALIGNMENT_LEFT, 604, 62)
	_text(Levels.GOALS[g.route.kind] if g.route.active() else encounter.call, x + 35, y + 153, 15, TEXT, false, HORIZONTAL_ALIGNMENT_LEFT, 600)
	if sec == 0 and not g.route.active():
		_text("Get close when the core opens. Press SHIFT or Q.", x + 35, y + 179, 15, TEXT, false, HORIZONTAL_ALIGNMENT_LEFT, 600)
	else:
		var loadout := Locale.text("Carried: %s   /   Hull %s of 7") % [Locale.text(g.RULE_NAMES[g.player_rule]), g.hp]
		_text(loadout, x + 35, y + 179, 15, TEXT, false, HORIZONTAL_ALIGNMENT_LEFT, 600)
	var enter := "START / A" if g.last_device == "pad" else "ENTER"
	_rect(x + 34, y + 239, 346, 34, GREEN)
	_text(enter + "   " + Locale.text("ENGAGE"), x + 47, y + 261, 14, INK, false, HORIZONTAL_ALIGNMENT_LEFT, 319)

func _title() -> void:
	g.draw_texture_rect(OVERLOOK, Rect2(0, 0, W, H), false)
	_rect(0, 0, W, H, Color("#0a142c25"))
	for i in 22:
		var t := float(i) / 21.0
		_rect(i * 21.0, 0, 22.0, H, _soft(INK, 0.43 * pow(1.0 - t, 1.6)))
	_rect(0, 0, W, 88, Color("#0d1728a5"))
	_line(Vector2(66, 88), Vector2(1095, 88), Color("#edd6ac45"))
	_text("Lobby", 66, 54, 22, PAPER, true)
	_line(Vector2(66, 169), Vector2(338, 169), Color("#e5b276"), 1.8)
	_text("STEAL THE", 65, 269, 96, PAPER, true)
	_text("RULES", 64, 363, 118, PAPER, true)
	_text("SHIFT  PROTOCOL", 68, 406, 24, Color("#f5c58d"), true)
	_rect(0, 565, W, 83, Color("#101a2bc9"))
	_line(Vector2(66, 566), Vector2(1096, 566), Color("#edd6ac47"))
	_text(_tally(), 68, 608, 17, PAPER, false)
	var count: float = float(g.campaign.records.size()) / Levels.TABLE.size()
	_rect(343, 601, 232, 4, Color("#657386"))
	_rect(343, 601, 232 * count, 4, Color("#f5c58d"))
	_text("v" + str(ProjectSettings.get_setting("application/config/version")), 1094, 608, 13, PAPER, false, HORIZONTAL_ALIGNMENT_RIGHT)

func _tally() -> String:
	return Locale.text("%d of %d sectors cleared") % [g.campaign.records.size(), Levels.TABLE.size()]
