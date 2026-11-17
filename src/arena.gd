extends Node2D
## One authoritative 120 Hz combat simulation. Rendering never mutates combat state.

const Art = preload("res://src/arena_art.gd")
const AudioRig = preload("res://src/sound.gd")
const SAVE = "user://shift_protocol.cfg"
const SIZE = Vector2(1152, 648)
const LEFT = 68.0
const RIGHT = 1084.0
const BASE = 488.0
const STEAL_RANGE = 186.0
const MAX_HP = 7
enum Rule { EMPTY, RUSH, LIFT, AEGIS }
const RULE_NAMES = ["EMPTY", "RUSH", "LIFT", "AEGIS"]
const RULE_COLORS = [Color("#a5b1bc"), Color("#ffab74"), Color("#80fbd2"), Color("#c8b2ff")]
const ENCOUNTERS = [
	{"name": "THE WARDEN", "sector": "01 / INTAKE", "call": "The doors only open from the inside.", "rules": [Rule.RUSH, Rule.AEGIS, Rule.LIFT], "hp": 36, "accent": Color("#ff995e")},
	{"name": "THE LATTICE", "sector": "02 / SUSPENSION", "call": "Take its lift. See what the floor is made of.", "rules": [Rule.LIFT, Rule.AEGIS, Rule.RUSH], "hp": 45, "accent": Color("#88e7d7")},
	{"name": "THE EXECUTOR", "sector": "03 / ROOT ACCESS", "call": "Whatever you hand over, it will learn to use.", "rules": [Rule.AEGIS, Rule.RUSH, Rule.LIFT], "hp": 57, "accent": Color("#d5b6ff")},
]

var art: RefCounted
var audio_rig: Node
var config := ConfigFile.new()
var save_path := SAVE
var mode := "title"
var resume_mode := "fight"
var stage := 0
var hp := MAX_HP
var boss_hp := 36
var player_rule := Rule.EMPTY
var boss_rule := Rule.RUSH
var reserve_rule := Rule.AEGIS
var floor_y := BASE
var floor_broken := false
var p := Vector2(208, BASE)
var v := Vector2.ZERO
var b := Vector2(827, BASE)
var facing := 1.0
var b_facing := -1.0
var grounded := true
var state := "idle"
var clock := 0.0
var run_time := 0.0
var state_time := 0.0
var state_total := 1.0
var freeze := 0.0
var shake := 0.0
var hit_flash := 0.0
var boss_flash := 0.0
var hurt_iframes := 0.0
var swing := 0.0
var swing_cd := 0.0
var dash := 0.0
var dash_speed := 705.0
var dash_cd := 0.0
var guard := 0.0
var lift := 0.0
var charge := true
var shift_lock := 0.0
var coyote := 0.0
var jump_buffer := 0.0
var target_x := 0.0
var attack_from := 0.0
var attack_to := 0.0
var move_name := ""
var zones: Array[Rect2] = []
var hazards: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var trails: Array[Dictionary] = []
var wire_from := Vector2.ZERO
var wire_to := Vector2.ZERO
var wire_time := 0.0
var wire_color := Color.WHITE
var notice := ""
var notice_sub := ""
var notice_time := 0.0
var steals := 0
var hits_taken := 0
var best_time := 0.0
var checkpoint := {"rule": Rule.EMPTY, "hp": MAX_HP, "time": 0.0, "steals": 0, "hits": 0}
var reduced_motion := false
var muted := false
var assist := false
var last_device := "keyboard"
var just: Dictionary = {}
var combat_rng := RandomNumberGenerator.new()

func _ready() -> void:
	Engine.physics_ticks_per_second = 120
	_bind(&"left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT])
	_bind(&"right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT])
	_bind(&"jump", [KEY_SPACE, KEY_W, KEY_UP], [JOY_BUTTON_A])
	_bind(&"strike", [KEY_J, KEY_Z], [JOY_BUTTON_X])
	_bind(&"rule", [KEY_E, KEY_L, KEY_C], [JOY_BUTTON_Y])
	_bind(&"dodge", [KEY_K, KEY_X], [JOY_BUTTON_B])
	_bind(&"steal", [KEY_SHIFT, KEY_Q], [JOY_BUTTON_RIGHT_SHOULDER])
	_bind(&"confirm", [KEY_ENTER, KEY_KP_ENTER], [JOY_BUTTON_START, JOY_BUTTON_A])
	_bind(&"pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_bind(&"retry", [KEY_R], [JOY_BUTTON_BACK])
	_bind(&"mute_game", [KEY_M], [])
	_bind(&"motion", [KEY_V], [])
	_bind(&"assist_mode", [KEY_H], [])
	_bind(&"quit_run", [KEY_T], [])
	_bind(&"full", [KEY_F11], [])
	config.load(SAVE)
	muted = config.get_value("settings", "mute", false)
	reduced_motion = config.get_value("settings", "reduced_motion", false)
	assist = config.get_value("settings", "assist", false)
	best_time = config.get_value("records", "clear_time", 0.0)
	combat_rng.randomize()
	art = Art.new()
	audio_rig = AudioRig.new()
	add_child(audio_rig)
	audio_rig.set_mute(muted)

func _bind(action: StringName, keys: Array, buttons: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		if key == KEY_SHIFT or key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_ESCAPE or key == KEY_F11:
			event.keycode = key
		else:
			event.physical_keycode = key
		InputMap.action_add_event(action, event)
	for button in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		last_device = "pad"
	elif event is InputEventKey and event.pressed and not event.echo:
		last_device = "keyboard"
		if event.keycode == KEY_SHIFT or event.physical_keycode == KEY_SHIFT:
			just[&"steal"] = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if (mode == "title" and Rect2(59, 456, 293, 49).has_point(event.position)) or (mode in ["brief", "clear", "paused", "lost", "win"] and Rect2(278, 437, 346, 34).has_point(event.position)):
			just[&"confirm"] = true
	for action in [&"confirm", &"pause", &"jump", &"dodge", &"rule", &"steal", &"retry", &"mute_game", &"motion", &"assist_mode", &"quit_run", &"full"]:
		if event.is_action_pressed(action):
			just[action] = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode in ["fight", "brief", "clear"]:
		resume_mode = mode
		mode = "paused"
		just.clear()

func _save() -> void:
	config.set_value("settings", "mute", muted)
	config.set_value("settings", "reduced_motion", reduced_motion)
	config.set_value("settings", "assist", assist)
	config.set_value("records", "clear_time", best_time)
	if not save_path.is_empty():
		config.save(save_path)

func _physics_process(dt: float) -> void:
	var pressed := just
	just = {}
	clock += dt
	if pressed.has("mute_game"):
		muted = not muted
		audio_rig.set_mute(muted)
		_save()
	if pressed.has("motion"):
		reduced_motion = not reduced_motion
		_save()
	if pressed.has("full") and not OS.has_feature("web"):
		var current := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if current == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if pressed.has("assist_mode") and mode == "title":
		assist = not assist
		_save()
	if mode == "title":
		if pressed.has("confirm"):
			_new_run()
	elif mode == "paused":
		if pressed.has("quit_run"):
			mode = "title"
		elif pressed.has("retry"):
			_retry()
		elif pressed.has("pause") or pressed.has("confirm"):
			mode = resume_mode
	elif mode == "brief":
		if pressed.has("pause") and not pressed.has("confirm"):
			resume_mode = mode
			mode = "paused"
		elif pressed.has("confirm"):
			mode = "fight"
			audio_rig.fire("start")
	elif mode == "lost":
		if pressed.has("confirm") or pressed.has("retry"):
			_retry()
		elif pressed.has("quit_run"):
			mode = "title"
	elif mode == "clear":
		if pressed.has("confirm"):
			_advance()
		elif pressed.has("pause"):
			resume_mode = mode
			mode = "paused"
	elif mode == "win":
		if pressed.has("confirm") or pressed.has("quit_run"):
			mode = "title"
	elif mode == "fight":
		if pressed.has("pause"):
			resume_mode = mode
			mode = "paused"
		elif pressed.has("retry"):
			_retry()
		else:
			var axis := Input.get_axis("left", "right")
			for device in Input.get_connected_joypads():
				var stick := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
				if absf(stick) > 0.22 and absf(stick) > absf(axis):
					axis = stick
			_tick_fight(dt, axis, pressed, Input.is_action_pressed("strike"))
	if mode != "paused":
		_tick_fx(dt)
	audio_rig.set_stage(stage if mode != "title" else -1, mode == "fight")
	queue_redraw()

func _new_run() -> void:
	stage = 0
	hp = MAX_HP
	run_time = 0.0
	steals = 0
	hits_taken = 0
	player_rule = Rule.EMPTY
	_load_arena()

func _advance() -> void:
	stage += 1
	hp = mini(MAX_HP, hp + 3)
	_load_arena()

func _retry() -> void:
	hp = checkpoint.hp
	player_rule = checkpoint.rule
	run_time = checkpoint.time
	steals = checkpoint.steals
	hits_taken = checkpoint.hits
	_load_arena()
	mode = "fight"
	audio_rig.fire("start")

func _load_arena() -> void:
	checkpoint = {"rule": player_rule, "hp": hp, "time": run_time, "steals": steals, "hits": hits_taken}
	boss_hp = ENCOUNTERS[stage].hp
	var candidates: Array = ENCOUNTERS[stage].rules.duplicate()
	candidates.erase(player_rule)
	boss_rule = candidates[0]
	reserve_rule = candidates[1]
	floor_y = BASE
	floor_broken = false
	p = Vector2(214, BASE)
	b = Vector2(819, BASE)
	v = Vector2.ZERO
	facing = 1.0
	b_facing = -1.0
	grounded = true
	hurt_iframes = 0.0
	swing = 0.0
	swing_cd = 0.0
	dash = 0.0
	dash_cd = 0.0
	guard = 0.0
	lift = 0.0
	shift_lock = 0.0
	charge = true
	coyote = 0.0
	jump_buffer = 0.0
	freeze = 0.0
	shake = 0.0
	hit_flash = 0.0
	boss_flash = 0.0
	wire_time = 0.0
	notice_time = 0.0
	hazards.clear()
	sparks.clear()
	rings.clear()
	trails.clear()
	zones.clear()
	_set_state("idle", 0.58)
	mode = "brief"

func _tick_fight(dt: float, axis: float, pressed: Dictionary, strike_held: bool) -> void:
	run_time += dt
	if pressed.has("jump"):
		jump_buffer = 0.12
	if freeze > 0.0:
		freeze -= dt
		# Preserve a button edge if it fell inside a hit stop.
		for action in [&"steal", &"dodge", &"rule"]:
			if pressed.has(action):
				just[action] = true
		return
	hurt_iframes = maxf(0.0, hurt_iframes - dt)
	shift_lock = maxf(0.0, shift_lock - dt)
	swing_cd = maxf(0.0, swing_cd - dt)
	swing = maxf(0.0, swing - dt)
	dash_cd = maxf(0.0, dash_cd - dt)
	dash = maxf(0.0, dash - dt)
	guard = maxf(0.0, guard - dt)
	lift = maxf(0.0, lift - dt)
	coyote = 0.10 if grounded else maxf(0.0, coyote - dt)
	jump_buffer = maxf(0.0, jump_buffer - dt)
	if absf(axis) > 0.05 and dash <= 0.0 and swing < 0.085:
		facing = signf(axis)
	if pressed.has("steal"):
		_try_shift()
		if mode != "fight":
			return
	if pressed.has("rule"):
		_use_rule()
		if mode != "fight":
			return
	if pressed.has("dodge") and dash_cd <= 0.0 and dash <= 0.0:
		if absf(axis) > 0.05:
			facing = signf(axis)
		dash = 0.15
		dash_speed = 705.0
		dash_cd = 0.72
		hurt_iframes = maxf(hurt_iframes, 0.16)
		audio_rig.fire("dodge")
	if jump_buffer > 0.0 and coyote > 0.0:
		v.y = -560.0
		grounded = false
		coyote = 0.0
		jump_buffer = 0.0
		_burst(p, Color("#abc9c4"), 7, 90.0)
		audio_rig.fire("jump")
	if dash > 0.0:
		v.x = facing * dash_speed
		v.y = move_toward(v.y, 0.0, dt * 2100.0)
		if trails.is_empty() or trails[-1].at.distance_to(p) > 17.0:
			trails.append({"at": p, "t": 0.20, "c": RULE_COLORS[player_rule]})
	else:
		var speed := 326.0 if player_rule != Rule.RUSH else 357.0
		var accel := 2780.0 if absf(axis) > 0.05 else 3560.0
		v.x = move_toward(v.x, axis * speed, accel * dt)
		v.y = minf(v.y + (300.0 if lift > 0.0 else 1660.0) * dt, 835.0)
	p += v * dt
	p.x = clampf(p.x, LEFT, RIGHT)
	if floor_broken:
		floor_y = move_toward(floor_y, BASE + 44.0, 213.0 * dt)
	if p.y >= floor_y:
		if not grounded and v.y > 385.0:
			_burst(p, Color("#719398"), 9, 120.0)
		p.y = floor_y
		v.y = 0.0
		grounded = true
	else:
		grounded = false
	if strike_held and swing_cd <= 0.0:
		_strike()
	if mode != "fight":
		return
	_tick_boss(dt)
	if mode == "fight":
		_tick_hazards(dt)

func core_pos() -> Vector2:
	return b + Vector2(0, -52)

func shift_distance() -> float:
	return (p - Vector2(0, 20)).distance_to(core_pos())

func can_shift() -> bool:
	return state == "exposed" and boss_rule != Rule.EMPTY and shift_lock <= 0.0 and shift_distance() <= STEAL_RANGE

func _try_shift() -> void:
	if not can_shift():
		if state == "exposed" and shift_distance() > STEAL_RANGE:
			_report("OUT OF REACH", "Get closer to the exposed core.", 0.95)
		elif shift_lock > 0.0:
			_report("LINK COOLING", "Read the next attack.", 0.8)
		else:
			_report("CORE SEALED", "SHIFT after an attack, when the core opens.", 1.05)
		audio_rig.fire("deny")
		return
	var old: int = player_rule
	player_rule = boss_rule
	boss_rule = old
	steals += 1
	charge = true
	shift_lock = 1.7
	wire_from = core_pos()
	wire_to = p - Vector2(0, 24)
	wire_time = 0.58
	wire_color = RULE_COLORS[player_rule]
	shake = 13.0
	freeze = 0.085
	boss_flash = 0.22
	hazards.clear()
	zones.clear()
	_burst(core_pos(), wire_color, 43, 340.0)
	_burst(wire_to, wire_color, 31, 260.0)
	rings.append({"at": wire_from, "t": 0.55, "c": wire_color, "r": 214.0})
	var consequence := "Boss stripped  /  reserve rule warming up"
	if boss_rule != Rule.EMPTY:
		consequence = "Boss inherited %s  /  its next attack changes" % RULE_NAMES[boss_rule]
	if player_rule == Rule.LIFT:
		consequence = "Boss loses flight  /  " + ("lower deck breached" if stage == 1 and not floor_broken else "heavy impact")
		if stage == 1:
			floor_broken = true
		grounded = false
		v.y = -260.0
	_set_state("reboot", 0.62)
	_report("%s TRANSFERRED" % RULE_NAMES[player_rule], consequence, 1.75)
	audio_rig.fire("steal")
	_damage_boss(4)

func _use_rule() -> void:
	if player_rule == Rule.EMPTY or not charge:
		audio_rig.fire("deny")
		return
	charge = false
	var color: Color = RULE_COLORS[player_rule]
	match player_rule:
		Rule.RUSH:
			dash = 0.24
			dash_speed = 1000.0
			dash_cd = 0.91
			hurt_iframes = maxf(hurt_iframes, 0.25)
			swing = 0.22
			swing_cd = 0.29
			var ahead := (b.x - p.x) * facing
			if ahead > -38.0 and ahead < 292.0 and absf(p.y - b.y) < 159.0:
				_damage_boss(7 if state in ["exposed", "reboot"] else 4)
		Rule.LIFT:
			lift = 0.66
			v.y = -440.0
			grounded = false
			coyote = 0.0
			jump_buffer = 0.0
		Rule.AEGIS:
			guard = 0.52 if not assist else 0.70
	rings.append({"at": p - Vector2(0, 18), "t": 0.42, "c": color, "r": 112.0})
	_burst(p - Vector2(0, 14), color, 16, 170.0)
	audio_rig.fire("rule")

func _strike() -> void:
	swing = 0.19
	swing_cd = 0.265
	audio_rig.fire("slash")
	var ahead := (b.x - p.x) * facing
	var reach := 115.0
	if ahead < -53.0 or ahead > reach or p.y > b.y + 33.0 or p.y < b.y - 138.0:
		return
	var damage := 3 if state in ["exposed", "reboot"] else 1
	if boss_rule == Rule.AEGIS and state in ["windup", "active"]:
		if lift <= 0.0:
			audio_rig.fire("deny")
			_burst(core_pos(), RULE_COLORS[Rule.AEGIS], 8, 120.0)
			return
	if lift > 0.0:
		damage += 4
		lift = 0.0
		v.y = minf(v.y, -90.0)
	_damage_boss(damage)

func _damage_boss(amount: int) -> void:
	if mode != "fight":
		return
	boss_hp = maxi(0, boss_hp - amount)
	boss_flash = 0.14
	shake = maxf(shake, 5.0 if amount < 4 else 8.0)
	freeze = maxf(freeze, 0.027 if amount < 4 else 0.05)
	_burst(core_pos(), Color("#ffe4bd"), 9 + amount, 183.0)
	audio_rig.fire("hit")
	if boss_hp == 0:
		_finish_arena()

func _finish_arena() -> void:
	hazards.clear()
	zones.clear()
	mode = "win" if stage == ENCOUNTERS.size() - 1 else "clear"
	_set_state("dead", 1.0)
	_burst(core_pos(), RULE_COLORS[player_rule], 72, 410.0)
	rings.append({"at": core_pos(), "t": 0.62, "c": RULE_COLORS[player_rule], "r": 365.0})
	audio_rig.fire("win")
	if mode == "win" and not assist and (best_time <= 0.0 or run_time < best_time):
		best_time = run_time
		_save()

func _set_state(next: String, duration: float) -> void:
	state = next
	state_time = duration
	state_total = duration

func _tick_boss(dt: float) -> void:
	state_time -= dt
	match state:
		"idle":
			if state_time <= 0.0:
				_windup()
		"windup":
			match move_name:
				"SKY ANVIL":
					b.y = move_toward(b.y, floor_y - 202.0, 470.0 * dt)
					b.x = move_toward(b.x, target_x, 602.0 * dt)
				"PULSE LATTICE":
					b.y = move_toward(b.y, floor_y - 48.0, 176.0 * dt)
				_:
					b.y = move_toward(b.y, floor_y, 400.0 * dt)
			if state_time <= 0.0:
				_commit_attack()
		"active":
			if move_name == "RAIL CUT":
				var progress := clampf(1.0 - state_time / state_total, 0.0, 1.0)
				b.x = lerpf(attack_from, attack_to, 1.0 - pow(1.0 - progress, 1.6))
				_check_hurt(Rect2(b.x - 48, floor_y - 61, 96, 70), b.x)
			elif move_name == "SKY ANVIL":
				b.x = move_toward(b.x, target_x, 840.0 * dt)
				b.y = move_toward(b.y, floor_y, 1820.0 * dt)
			if state_time <= 0.0 and mode == "fight":
				if move_name == "SKY ANVIL":
					b.y = floor_y
					b.x = target_x
					_shockwave(b.x, 1)
					_shockwave(b.x, -1)
					_impact(core_pos(), RULE_COLORS[Rule.LIFT])
				charge = true
				_set_state("exposed", (1.62 - stage * 0.11) + (0.45 if assist else 0.0))
				audio_rig.fire("open")
		"exposed":
			var recovery_y := floor_y - 64.0 if move_name == "SKY ANVIL" else floor_y
			b.y = move_toward(b.y, recovery_y, 340.0 * dt)
			if state_time <= 0.0:
				if boss_rule == Rule.EMPTY:
					boss_rule = reserve_rule
					reserve_rule = Rule.EMPTY
				_set_state("idle", 0.29)
		"reboot":
			b.y = move_toward(b.y, floor_y, 820.0 * dt)
			if state_time <= 0.0:
				if floor_broken and player_rule == Rule.LIFT:
					_impact(b, RULE_COLORS[Rule.LIFT])
				_set_state("idle", 0.21)

func _windup() -> void:
	zones.clear()
	target_x = clampf(p.x, LEFT + 86, RIGHT - 86)
	b_facing = 1.0 if p.x >= b.x else -1.0
	var t := 0.73 - stage * 0.065 + (0.18 if assist else 0.0)
	match boss_rule:
		Rule.RUSH:
			move_name = "RAIL CUT"
			attack_from = b.x
			attack_to = RIGHT - 58.0 if b_facing > 0 else LEFT + 58.0
			zones.append(Rect2(minf(attack_from, attack_to) - 43, floor_y - 61, absf(attack_to - attack_from) + 86, 61))
		Rule.LIFT:
			move_name = "SKY ANVIL"
			t += 0.23
			zones.append(Rect2(target_x - 101, floor_y - 146, 202, 146))
		Rule.AEGIS:
			move_name = "PULSE LATTICE"
			t += 0.14
			var w := 118.0 + stage * 17.0
			for x in [target_x, target_x - 276, target_x + 276]:
				if x + w * 0.5 > LEFT and x - w * 0.5 < RIGHT:
					var x0 := clampf(x - w * 0.5, LEFT, RIGHT)
					var x1 := clampf(x + w * 0.5, LEFT, RIGHT)
					zones.append(Rect2(x0, 153, x1 - x0, floor_y - 153))
		_:
			move_name = "DEAD CIRCUIT"
			t += 0.05
			zones.append(Rect2(b.x - 150, floor_y - 60, 300, 60))
	_set_state("windup", t)
	audio_rig.fire("warn")

func _commit_attack() -> void:
	var color: Color = ENCOUNTERS[stage].accent
	shake = maxf(shake, 6.0)
	match move_name:
		"RAIL CUT":
			_set_state("active", 0.45 - stage * 0.035)
			_burst(b - Vector2(0, 17), color, 29, 223.0)
		"SKY ANVIL":
			_set_state("active", 0.23)
			var impact := Rect2(target_x - 101, floor_y - 132, 202, 132)
			hazards.append({"box": impact, "t": 0.18, "delay": 0.115, "v": 0.0, "c": color})
		"PULSE LATTICE":
			_set_state("active", 0.31)
			for zone in zones:
				hazards.append({"box": zone, "t": 0.32, "delay": 0.0, "v": 0.0, "c": color})
			_impact(core_pos(), color)
		_:
			_set_state("active", 0.24)
			_shockwave(b.x, 1)
			_shockwave(b.x, -1)
			_impact(b, color)
	zones.clear()
	audio_rig.fire("slam")

func _shockwave(x: float, direction: int) -> void:
	hazards.append({"box": Rect2(x - 23.0, floor_y - 34.0, 46.0, 37.0), "t": 1.07, "delay": 0.0, "v": direction * (480.0 + stage * 48.0), "c": ENCOUNTERS[stage].accent})

func _tick_hazards(dt: float) -> void:
	for i in range(hazards.size() - 1, -1, -1):
		var hazard := hazards[i]
		hazard.delay -= dt
		if hazard.delay > 0.0:
			continue
		hazard.t -= dt
		var rect: Rect2 = hazard.box
		rect.position.x += hazard.v * dt
		hazard.box = rect
		if hazard.t <= 0.0 or rect.end.x < 0 or rect.position.x > SIZE.x:
			hazards.remove_at(i)
			continue
		_check_hurt(rect, rect.get_center().x)
		if mode != "fight":
			return

func _check_hurt(rect: Rect2, origin: float) -> void:
	var hurtbox := Rect2(p.x - 13.0, p.y - 37.0, 26.0, 34.0)
	if hurt_iframes > 0.0 or not rect.intersects(hurtbox) or mode != "fight":
		return
	if guard > 0.0:
		guard = 0.0
		hurt_iframes = 0.42
		_impact(p - Vector2(0, 22), RULE_COLORS[Rule.AEGIS])
		audio_rig.fire("parry")
		var reflected := absf(p.x - b.x) < 396.0
		_report("PULSE PARRIED", "Reflected to the core" if reflected else "Too far to reflect", 1.3)
		if reflected:
			_damage_boss(8)
		return
	hp -= 1
	hits_taken += 1
	hurt_iframes = 1.05 if assist else 0.74
	hit_flash = 0.32
	v = Vector2(410.0 if p.x >= origin else -410.0, -290.0)
	shake = 11.0
	freeze = 0.049
	_burst(p - Vector2(0, 20), Color("#ff826c"), 24, 240.0)
	audio_rig.fire("hurt")
	if hp <= 0:
		mode = "lost"
		hazards.clear()
		zones.clear()

func _impact(at: Vector2, color: Color) -> void:
	shake = maxf(shake, 9.0)
	_burst(at, color, 22, 275.0)
	rings.append({"at": at, "t": 0.38, "c": color, "r": 130.0})

func _report(line: String, sub: String, duration: float) -> void:
	notice = line
	notice_sub = sub
	notice_time = duration

func _burst(at: Vector2, color: Color, count: int, speed: float) -> void:
	for i in count:
		if sparks.size() >= 260:
			sparks.pop_front()
		var direction := Vector2.from_angle(combat_rng.randf_range(-PI, PI))
		var lifetime := combat_rng.randf_range(0.15, 0.58)
		sparks.append({"at": at, "v": direction * combat_rng.randf_range(speed * 0.24, speed), "t": lifetime, "max": lifetime, "c": color, "size": combat_rng.randf_range(1.8, 5.4)})

func _tick_fx(dt: float) -> void:
	shake = move_toward(shake, 0.0, 39.0 * dt)
	hit_flash = maxf(0.0, hit_flash - dt)
	boss_flash = maxf(0.0, boss_flash - dt)
	notice_time = maxf(0.0, notice_time - dt)
	wire_time = maxf(0.0, wire_time - dt)
	for i in range(sparks.size() - 1, -1, -1):
		var spark := sparks[i]
		spark.t -= dt
		if spark.t <= 0.0:
			sparks.remove_at(i)
		else:
			spark.at += spark.v * dt
			spark.v.y += 240.0 * dt
	for list in [rings, trails]:
		for i in range(list.size() - 1, -1, -1):
			list[i].t -= dt
			if list[i].t <= 0:
				list.remove_at(i)

func timecode(seconds: float) -> String:
	var whole := int(seconds)
	return "%02d:%02d.%02d" % [whole / 60, whole % 60, int(seconds * 100.0) % 100]

func _draw() -> void:
	if art != null:
		art.paint(self)
