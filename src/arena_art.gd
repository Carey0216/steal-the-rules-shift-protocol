extends RefCounted

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
var headline: Font
var mono: Font
var accent: Color
var sec := 0

func _init() -> void:
	headline = _font("res://assets/BarlowCondensed-ExtraBold.ttf")
	mono = _font("res://assets/SpaceMono-Regular.ttf")

func _font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return ThemeDB.fallback_font

func paint(game: Node2D) -> void:
	g = game
	sec = g.stage if g.mode != "title" else 0
	accent = g.ENCOUNTERS[sec].accent
	if g.mode == "title":
		_title()
		return
	var shift := Vector2.ZERO
	if not g.reduced_motion:
		shift = Vector2(sin(g.clock * 142.0), cos(g.clock * 173.0) * 0.58) * g.shake
	_background(g.floor_y, g.clock)
	g.draw_set_transform(shift)
	_floor(g.floor_y)
	_warnings()
	_world_fx(false)
	_boss(g.b, g.b_facing, 1.0, g.boss_rule, false)
	_player(g.p, g.facing, 1.0)
	_world_fx(true)
	g.draw_set_transform(Vector2.ZERO)
	_hud()
	if g.mode in ["brief", "clear", "paused", "lost", "win"]:
		_overlay()

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

func _text(message: String, x: float, y: float, size: int, color: Color, big := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := headline if big else mono
	var width := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
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
	elif sec == 2:
		for i in 6:
			var x := 55.0 + i * 218.0
			_rect(x, 152, 92, 10, _soft(accent, 0.20))
			_rect(x + 8, 164, 3, 256, _soft(accent, 0.13))
			_rect(x + 84, 164, 3, 256, _soft(accent, 0.13))
	for i in 72:
		var x := fposmod(i * 337.1 + (age * (5.0 + i % 4) if not g.reduced_motion else 0.0), W)
		var y := 146.0 + fposmod(i * 69.7 - (age * (9 + i % 3) if not g.reduced_motion else 0.0), 365.0)
		_rect(x, y, 1 + i % 3, 1, _soft(accent, 0.10 + (i % 5) * 0.035))
	for i in 115:
		_rect(0, 4 + i * 5.0, W, 1, _soft(INK, 0.14))
	_text("SUBLEVEL  /  " + str(sec + 1).pad_zeros(2), 59, 176, 12, _soft(DIM, 0.52))
	_text("AUTHORIZED MACHINES ONLY", 1093, 176, 12, _soft(DIM, 0.52), false, HORIZONTAL_ALIGNMENT_RIGHT)

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
		for x in [279, 584, 867]:
			_poly([Vector2(x - 30, y - 2), Vector2(x + 33, y - 2), Vector2(x + 10, y + 14), Vector2(x + 17, y + 28), Vector2(x - 14, y + 16)], INK)
			_line(Vector2(x - 14, y + 16), Vector2(x + 17, y + 28), accent, 2.0)

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
	if g.swing > 0:
		var hand := at + Vector2(9 * face, -24) * scale
		var end := hand + Vector2(face * (62 + g.swing * 85), -14 - g.swing * 60) * scale
		_line(hand, end, _soft(color, 0.33), 14.0 * scale)
		_line(hand, end, color, 3.0 * scale)
		var angle := 0.0 if face > 0 else PI
		g.draw_arc(hand, 66 * scale, angle - 0.63, angle + 0.49, 32, _soft(color, g.swing * 3.5), 2.0, true)

func _warnings() -> void:
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
	_rect(0, 0, W, 136, INK)
	_rect(0, 135, W, 1, LINE)
	_rect(0, 0, W, 3, accent)
	_text("SHIFT PROTOCOL", 42, 32, 27, PAPER, true)
	_text("SECTOR " + g.ENCOUNTERS[sec].sector, 42, 55, 12, DIM)
	_text(g.timecode(g.run_time), 1110, 34, 19, TEXT, false, HORIZONTAL_ALIGNMENT_RIGHT)
	_text("RUN CLOCK", 1110, 55, 11, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(g.ENCOUNTERS[sec].name, 576, 38, 32, PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
	_rect(326, 51, 500, 8, LINE)
	var fraction: float = float(g.boss_hp) / g.ENCOUNTERS[sec].hp
	if fraction > 0:
		_rect(326, 51, 500 * fraction, 8, accent)
	for i in range(1, 10):
		_rect(326 + i * 50, 51, 1, 8, INK)
	_line(Vector2(42, 68), Vector2(1110, 68), LINE)
	_text("HULL", 42, 91, 12, DIM)
	for i in g.MAX_HP:
		_rect(42 + i * 22, 100, 17, 13, GREEN if i < g.hp else LINE)
	var slot_color: Color = g.RULE_COLORS[g.player_rule]
	_text("YOUR RULE", 315, 91, 12, DIM)
	_text(g.RULE_NAMES[g.player_rule], 313, 119, 28, slot_color, true)
	var charge_label := "Y" if g.last_device == "pad" else "E"
	if g.player_rule != g.Rule.EMPTY:
		_text("[" + charge_label + "] READY" if g.charge else "RECHARGING", 430, 113, 12, slot_color if g.charge else DIM)
	_text("SHIFT LINK", 692, 91, 12, DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	var link := "IN RANGE" if g.can_shift() else ("APPROACH" if g.state == "exposed" and g.boss_rule != g.Rule.EMPTY else "WAIT")
	_text(link, 692, 115, 18, GREEN if g.can_shift() else DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	_text("BOSS RULE", 1110, 91, 12, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(g.RULE_NAMES[g.boss_rule], 1110, 119, 28, g.RULE_COLORS[g.boss_rule], true, HORIZONTAL_ALIGNMENT_RIGHT)
	_rect(0, 568, W, 80, INK)
	_line(Vector2(0, 568), Vector2(W, 568), LINE)
	var sub := _instruction()
	_text(sub, 42, 596, 16, TEXT)
	var inputs := "STICK MOVE    A JUMP    X STRIKE    B DODGE    RB SHIFT    Y RULE" if g.last_device == "pad" else "A/D MOVE     SPACE JUMP     J STRIKE     K DODGE     SHIFT STEAL     E RULE"
	_text(inputs, 42, 627, 12, DIM)
	_text("M AUDIO  /  V MOTION  /  ESC PAUSE", 1110, 627, 11, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
	if g.state == "windup":
		_text(g.move_name, 576, 176, 25, RED, true, HORIZONTAL_ALIGNMENT_CENTER)
	elif g.notice_time > 0.0:
		_text(g.notice, 576, 179, 35, g.wire_color if g.notice.ends_with("TRANSFERRED") else PAPER, true, HORIZONTAL_ALIGNMENT_CENTER)
		_text(g.notice_sub, 576, 201, 13, TEXT, false, HORIZONTAL_ALIGNMENT_CENTER)
	if g.hit_flash > 0.0 and not g.reduced_motion:
		_rect(4, 139, W - 8, 424, _soft(RED, g.hit_flash * 0.9), false, 4.0)

func _instruction() -> String:
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

func _overlay() -> void:
	_rect(0, 136, W, 432, _soft(INK, 0.70))
	var x := 244.0
	var y := 198.0
	var w := 664.0
	var h := 296.0
	_rect(x + 6, y + 8, w, h, _soft(Color.BLACK, 0.60))
	_rect(x, y, w, h, INK)
	_rect(x, y, w, h, LINE, false)
	_rect(x, y, 4, h, accent)
	var kicker := ""
	var title := ""
	var lines: Array[String] = []
	var cta := ""
	var enter := "START / A" if g.last_device == "pad" else "ENTER"
	match g.mode:
		"brief":
			kicker = "INTRUSION  /  " + g.ENCOUNTERS[sec].sector
			title = g.ENCOUNTERS[sec].name
			lines.append(g.ENCOUNTERS[sec].call)
			if sec == 0:
				lines.append("Get close when the core opens. Press SHIFT or Q.")
				lines.append("One slot. Each swap hands your old rule to the boss.")
			else:
				lines.append("Carried: " + g.RULE_NAMES[g.player_rule] + "   /   Hull " + str(g.hp) + " of 7")
				lines.append("Reboots restore this sector's starting loadout.")
			cta = enter + "   ENGAGE"
		"clear":
			kicker = "SECTOR " + str(sec + 1).pad_zeros(2) + " / 03"
			title = "GATE UNLOCKED"
			lines.append("Carry " + g.RULE_NAMES[g.player_rule] + " into the next sector.")
			lines.append("Repair up to three hull points on entry.")
			cta = enter + "   DESCEND"
		"paused":
			kicker = "LOCAL TERMINAL  /  STANDBY"
			title = "LINK PAUSED"
			lines.append("M  Audio: " + ("OFF" if g.muted else "ON") + "    V  Reduced motion: " + ("ON" if g.reduced_motion else "OFF"))
			lines.append("R  Reboot sector   /   T  Return to title")
			cta = enter + "   RESUME"
		"lost":
			kicker = "SECTOR " + str(sec + 1).pad_zeros(2) + "  /  LINK LOST"
			title = "HULL BREACHED"
			lines.append("Reboot from this sector with your entry loadout.")
			lines.append("Dodge through danger. Strike when the core opens.")
			cta = enter + "   REBOOT"
		"win":
			kicker = "ROOT ACCESS GRANTED   //   03 / 03"
			title = "RULES REWRITTEN"
			lines.append("%s    /    %s transfers    /    %s hits" % [g.timecode(g.run_time), g.steals, g.hits_taken])
			lines.append("Assist run complete." if g.assist else "Personal best: " + g.timecode(g.best_time))
			cta = enter + "   BACK TO TITLE"
	_text(kicker, x + 34, y + 41, 14, accent)
	_text(title, x + 32, y + 113, 63, PAPER, true)
	for i in lines.size():
		_text(lines[i], x + 35, y + 153 + i * 26, 15, TEXT)
	_rect(x + 34, y + 239, 346, 34, GREEN)
	_text(cta, x + 47, y + 261, 14, INK)
	_columns(x + w - 106, 72, y + 243, 22, _soft(accent, 0.42))

func _title() -> void:
	_background(510, g.clock)
	_floor(510)
	_boss(Vector2(877, 505), -1, 2.32, g.Rule.RUSH, true)
	_player(Vector2(633, 507), 1, 1.25)
	_rect(0, 0, 646, H, _soft(INK, 0.90))
	for i in 26:
		_rect(646 + 4 * i, 0, 4, H, _soft(INK, 0.83 * (1.0 - i / 26.0)))
	_rect(0, 0, W, 5, RED)
	_line(Vector2(57, 83), Vector2(1095, 83), LINE)
	_text("GAME OFF 2026", 58, 60, 14, PAPER)
	_text("INTRUSION MANUAL  /  VOL. 01", 1095, 60, 14, PAPER, false, HORIZONTAL_ALIGNMENT_RIGHT)
	_text("01    /    ROOT ACCESS PROHIBITED", 59, 136, 13, RED)
	_text("STEAL THE", 53, 250, 113, PAPER, true)
	_text("RULES", 53, 347, 113, PAPER, true)
	_text("S H I F T   P R O T O C O L", 61, 390, 19, GREEN)
	_text("One slot. Three machines. Their rules are yours.", 60, 428, 15, TEXT)
	_rect(59, 456, 293, 49, GREEN)
	_text(("START / A" if g.last_device == "pad" else "ENTER") + "  /  INFILTRATE", 75, 486, 16, INK)
	_text("H  ASSIST: " + ("ON" if g.assist else "OFF") + "    M  AUDIO: " + ("OFF" if g.muted else "ON") + "    V  LOW MOTION: " + ("ON" if g.reduced_motion else "OFF"), 59, 542, 12, DIM)
	_rect(0, 568, W, 80, INK)
	_line(Vector2(0, 568), Vector2(W, 568), LINE)
	_text("DON'T FIGHT THE RULES. TAKE THEM.", 58, 610, 16, PAPER)
	if g.best_time > 0.0:
		_text("PB  " + g.timecode(g.best_time), 844, 610, 14, GREEN, false, HORIZONTAL_ALIGNMENT_RIGHT)
	_columns(902, 190, 596, 19, _soft(RED, 0.72))
