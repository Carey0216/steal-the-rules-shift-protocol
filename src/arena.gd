extends Node2D
## One authoritative 120 Hz combat simulation. Rendering never mutates combat state.

const Art = preload("res://src/arena_art.gd")
const AudioRig = preload("res://src/sound.gd")
const Locale = preload("res://src/locale.gd")
const Menu = preload("res://src/title_menu.gd")
const Campaign = preload("res://src/campaign.gd")
const Levels = preload("res://src/levels.gd")
const Gear = preload("res://src/gear.gd")
const Route = preload("res://src/route.gd")
const SAVE = "user://shift_protocol.cfg"
const SIZE = Vector2(1152, 648)
const LEFT = 68.0
const RIGHT = 1084.0
const BASE = 488.0
const STEAL_RANGE = 186.0
const MAX_HP = 7
const DODGE_TIME := 0.23
const DODGE_PROTECTION := 0.27
const DODGE_COOLDOWN := 0.59
const DECK_LEFT := 404.0
const DECK_RIGHT := 748.0
enum Rule { EMPTY, RUSH, LIFT, AEGIS }
const RULE_NAMES = ["EMPTY", "RUSH", "LIFT", "AEGIS"]
const RULE_COLORS = [Color("#a5b1bc"), Color("#ffab74"), Color("#80fbd2"), Color("#c8b2ff")]
const ENCOUNTERS = [
	{"name": "THE WARDEN", "sector": "01 / INTAKE", "call": "The doors only open from the inside.", "rules": [Rule.RUSH, Rule.AEGIS, Rule.LIFT], "hp": 36, "accent": Color("#ff995e")},
	{"name": "THE LATTICE", "sector": "02 / SUSPENSION", "call": "Take its lift. See what the floor is made of.", "rules": [Rule.LIFT, Rule.AEGIS, Rule.RUSH], "hp": 45, "accent": Color("#88e7d7")},
	{"name": "CAPACITOR", "sector": "03 / POWER", "call": "The live conduits alternate. Cross on the dark side.", "rules": [Rule.AEGIS, Rule.LIFT, Rule.RUSH], "hp": 49, "accent": Color("#f0ca73")},
	{"name": "THE FURNACE", "sector": "04 / FORGE", "call": "When the vents flare, get off the floor.", "rules": [Rule.RUSH, Rule.LIFT, Rule.AEGIS], "hp": 54, "accent": Color("#ff795e")},
	{"name": "THE MIRROR", "sector": "05 / REFLECTION", "call": "The mirror marks where you were. Keep moving.", "rules": [Rule.LIFT, Rule.RUSH, Rule.AEGIS], "hp": 58, "accent": Color("#a1cff8")},
	{"name": "THE EXECUTOR", "sector": "06 / ROOT ACCESS", "call": "An inherited rule comes back stronger.", "rules": [Rule.AEGIS, Rule.RUSH, Rule.LIFT], "hp": 70, "accent": Color("#d5b6ff")},
]

var art: RefCounted
var audio_rig: Node
var title_menu: CanvasLayer
var config := ConfigFile.new()
var campaign := Campaign.new()
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
var sector_time := 0.0
var sector_retries := 0
var sector_result: Dictionary = {}
var replay := false
var practice := -1
var practice_origin := 0.0
var practice_return := ""
var practice_clear := false
var practice_hit := false
var mission_sector := false
var save_error := false
var dodge_buffer := 0.0
var steal_buffer := 0.0
var dodge_protection := 0.0
var overclock_pending := false
var overclock_attack := false
var rail_return := false
var echo_target := 576.0
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
var language_index := -1
var guide_seen := false
var fullscreen := false
var text_size_index := 0
var window_size_index := 0
var record_demo := false
var last_device := "keyboard"
var just: Dictionary = {}
var combat_rng := RandomNumberGenerator.new()
var gear_rng := RandomNumberGenerator.new()
var route := Route.new()
var sector_index := 0
var boss_max_hp := 49
var starter: Array[int] = []
var effects := {}
var drop := {}
var drop_cooldown := 0.0
var cell_cooldown := 0.0
var evacuated := false
var boss_locks: Array[Vector2] = []
var capacitor_power := 0.0
var boot_time := 0.0

func _ready() -> void:
	Locale.install()
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
	if not save_path.is_empty() and config.load(save_path) != OK:
		config.load(save_path + ".backup")
	campaign.load_from(config, Levels.TABLE.size())
	get_tree().auto_accept_quit = false
	muted = config.get_value("settings", "mute", false)
	reduced_motion = config.get_value("settings", "reduced_motion", false)
	assist = config.get_value("settings", "assist", false)
	language_index = Locale.CODES.find(config.get_value("settings", "language", ""))
	guide_seen = config.get_value("settings", "guide_seen", false)
	text_size_index = clampi(int(config.get_value("settings", "text_size", 0)), 0, Menu.SCALES.size() - 1)
	window_size_index = clampi(int(config.get_value("settings", "window_size", 0)), 0, Menu.SIZES.size() - 1)
	var locale := TranslationServer.standardize_locale(OS.get_locale())
	var initial := language_index
	if initial < 0:
		initial = Locale.CODES.find(locale)
		if initial < 0:
			if locale.begins_with("zh"):
				initial = 2 if locale.begins_with("zh_Hant") or locale.contains("_HK") or locale.contains("_MO") else 1
			else:
				initial = clampi(Locale.CODES.find(locale.get_slice("_", 0)), 0, Locale.CODES.size() - 1)
	TranslationServer.set_locale(Locale.CODES[initial])
	if DisplayServer.get_name() != "headless" and not OS.has_feature("editor") and not OS.has_feature("web"):
		_apply_display(config.get_value("settings", "fullscreen", true))
	best_time = config.get_value("records", "clear_time", 0.0)
	combat_rng.randomize()
	gear_rng.randomize()
	boot_time = 0.82 if not save_path.is_empty() and not reduced_motion and DisplayServer.get_name() != "headless" else 0.0
	art = Art.new()
	audio_rig = AudioRig.new()
	add_child(audio_rig)
	audio_rig.set_mute(muted)
	title_menu = Menu.new()
	title_menu.game = self
	add_child(title_menu)

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
	if title_menu != null and not record_demo:
		if event.is_action_pressed(&"full"):
			set_fullscreen(not _display_is_fullscreen())
			if title_menu.page == "settings":
				title_menu._draw_page.call_deferred()
			get_viewport().set_input_as_handled()
			return
		if mode == "title" and not title_menu.page.is_empty():
			return
		if event.is_action_pressed(&"confirm") and get_viewport().gui_get_focus_owner() != null:
			return
	if event is InputEventJoypadButton and event.pressed:
		last_device = "pad"
	elif event is InputEventKey and event.pressed and not event.echo:
		last_device = "keyboard"
		if event.keycode == KEY_SHIFT or event.physical_keycode == KEY_SHIFT:
			just[&"steal"] = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode == "brief" and Rect2(278, 437, 346, 34).has_point(event.position):
			just[&"confirm"] = true
	for action in [&"confirm", &"pause", &"jump", &"dodge", &"rule", &"steal", &"retry", &"mute_game", &"motion", &"assist_mode", &"quit_run"]:
		if event.is_action_pressed(action):
			just[action] = true

func _unhandled_input(event: InputEvent) -> void:
	if mode == "title" and title_menu != null and not title_menu.page.is_empty() and event.is_action_pressed("ui_cancel"):
		title_menu.back()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_and_quit()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not record_demo and mode in ["fight", "brief", "clear"]:
		resume_mode = mode
		mode = "paused"
		just.clear()

func _save() -> Error:
	config.set_value("settings", "mute", muted)
	config.set_value("settings", "reduced_motion", reduced_motion)
	config.set_value("settings", "assist", assist)
	if language_index >= 0:
		config.set_value("settings", "language", Locale.CODES[language_index])
	config.set_value("settings", "guide_seen", guide_seen)
	config.set_value("settings", "text_size", text_size_index)
	config.set_value("settings", "window_size", window_size_index)
	if not OS.has_feature("web"):
		config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("records", "clear_time", best_time)
	campaign.write_to(config)
	if save_path.is_empty():
		return OK
	var temporary := save_path + ".next"
	var result := config.save(temporary)
	if result != OK:
		return result
	if FileAccess.file_exists(save_path):
		result = DirAccess.copy_absolute(save_path, save_path + ".backup")
		if result != OK:
			return result
	return DirAccess.rename_absolute(temporary, save_path)

func save_and_quit() -> void:
	if _save() != OK:
		title_menu.show_save_error()
		return
	if OS.has_feature("web"):
		return_to_lobby()
	else:
		get_tree().quit()

func return_to_lobby(next_page := "") -> void:
	if practice >= 0:
		if title_menu.onboarding:
			next_page = "guide"
		practice = -1
	mode = "title"
	just.clear()
	save_error = _save() != OK
	if title_menu != null:
		title_menu.previous_mode = mode
		title_menu._open(next_page)

func return_from_practice() -> void:
	return_to_lobby(practice_return)

func begin_sector(index: int) -> void:
	if not campaign.selectable(index, Levels.TABLE.size()):
		return
	starter.assign(campaign.reserved)
	campaign.reserved.clear()
	if _save() != OK:
		campaign.reserved.assign(starter)
		save_error = true
		title_menu.show_save_error()
		return
	save_error = false
	var entry: Dictionary = campaign.entry(index)
	sector_index = index
	stage = Levels.TABLE[index][3]
	hp = entry.hp
	player_rule = entry.rule
	replay = index < campaign.records.size()
	mission_sector = true
	practice = -1
	run_time = 0.0
	steals = 0
	hits_taken = 0
	sector_retries = 0
	_load_arena()

func buy_gear(id: int) -> bool:
	if id not in Gear.stock(campaign.records.size(), true) or id in campaign.reserved or campaign.reserved.size() >= Gear.MAX_LOADOUT:
		return false
	var price: int = Gear.ITEMS[id][3]
	if campaign.coins < price:
		return false
	campaign.coins -= price
	campaign.reserved.append(id)
	if _save() == OK:
		return true
	campaign.coins += price
	campaign.reserved.erase(id)
	title_menu.show_save_error()
	return false

func reset_progress() -> void:
	var previous := campaign
	var legacy := {}
	if config.has_section("campaign"):
		for key in config.get_section_keys("campaign"):
			legacy[key] = config.get_value("campaign", key)
	var old_best := best_time
	campaign = Campaign.new()
	best_time = 0.0
	if config.has_section("campaign"):
		config.erase_section("campaign")
	if _save() != OK:
		campaign = previous
		best_time = old_best
		for key in legacy:
			config.set_value("campaign", key, legacy[key])
		title_menu.show_save_error()
		return
	if not save_path.is_empty() and FileAccess.file_exists(save_path + ".backup"):
		DirAccess.remove_absolute(save_path + ".backup")
	save_error = false

func set_language(index: int) -> void:
	language_index = index
	TranslationServer.set_locale(Locale.CODES[index])
	_save()
	queue_redraw()

func _display_is_fullscreen() -> bool:
	if OS.has_feature("web"):
		var browser = Engine.get_singleton("JavaScriptBridge")
		return browser.get_interface("document").fullscreenElement != null
	return get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]

func set_fullscreen(enabled: bool) -> void:
	_apply_display(enabled)
	_save()

func _apply_display(enabled: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	window.mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED
	fullscreen = enabled
	if not enabled and not OS.has_feature("web"):
		var screen := DisplayServer.screen_get_usable_rect(window.current_screen)
		var available := (screen.size - Vector2i(48, 80)).max(Vector2i(640, 360))
		var chosen: Vector2i = Menu.SIZES[window_size_index]
		var fit := minf(1.0, minf(float(available.x) / chosen.x, float(available.y) / chosen.y))
		window.size = Vector2i(Vector2(chosen) * fit)
		window.position = screen.position + (screen.size - window.size) / 2

func _physics_process(dt: float) -> void:
	var pressed := just
	just = {}
	clock += dt
	boot_time = maxf(0.0, boot_time - dt)
	if pressed.has("mute_game"):
		muted = not muted
		audio_rig.set_mute(muted)
		_save()
	if pressed.has("motion"):
		reduced_motion = not reduced_motion
		_save()
	if pressed.has("assist_mode") and mode == "title":
		assist = not assist
		_save()
	if mode == "title":
		if pressed.has("confirm"):
			if record_demo:
				_new_run()
			else:
				title_menu._open("map")
	elif mode == "paused":
		if pressed.has("quit_run"):
			return_to_lobby()
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
			if title_menu != null and not record_demo:
				title_menu.play_arena_reveal()
	elif mode == "lost":
		if pressed.has("confirm") or pressed.has("retry"):
			_retry()
		elif pressed.has("quit_run"):
			return_to_lobby()
	elif mode == "clear":
		if pressed.has("confirm") and not mission_sector:
			continue_after_clear()
		elif pressed.has("pause"):
			resume_mode = mode
			mode = "paused"
	elif mode == "win":
		if pressed.has("confirm") or pressed.has("quit_run"):
			return_to_lobby("map")
	elif mode == "practice_done":
		if pressed.has("confirm"):
			return_from_practice()
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
	if title_menu != null and not record_demo:
		title_menu.sync_mode()
	queue_redraw()

func _new_run() -> void:
	mission_sector = false
	replay = false
	practice = -1
	sector_retries = 0
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
	sector_retries = 0
	_load_arena()

func continue_after_clear() -> void:
	if mission_sector:
		if sector_index < Levels.TABLE.size() - 1:
			return_to_lobby("map")
			title_menu.prepare_sector(sector_index + 1)
		else:
			return_to_lobby("map")
	else:
		_advance()

func _retry() -> void:
	if mission_sector and (mode in ["clear", "win"] or (mode == "paused" and resume_mode in ["clear", "win"])):
		title_menu._retry_from_results()
		return
	sector_retries += 1
	if practice >= 0:
		begin_practice(practice, practice_return)
		return
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
	boss_max_hp = roundi(float(ENCOUNTERS[stage].hp) * 1.35)
	boss_hp = boss_max_hp
	route.load_level(Levels.TABLE[sector_index] if mission_sector else Levels.TABLE[2])
	evacuated = false
	capacitor_power = 0.0
	boss_locks.clear()
	if mission_sector and stage == 4 and not route.active():
		boss_locks = [Vector2(440, BASE), Vector2(840, BASE)]
	effects.clear()
	drop.clear()
	drop_cooldown = 0.0
	cell_cooldown = 0.0
	if mission_sector:
		for id in starter:
			_equip(id)
	var candidates: Array = ENCOUNTERS[stage].rules.duplicate()
	if mission_sector and sector_index >= 24 and not route.active():
		candidates.push_back(candidates.pop_front())
	candidates.erase(player_rule)
	boss_rule = candidates[0]
	reserve_rule = candidates[1]
	floor_y = BASE
	floor_broken = false
	sector_time = 0.0
	dodge_buffer = 0.0
	steal_buffer = 0.0
	dodge_protection = 0.0
	overclock_pending = false
	overclock_attack = false
	rail_return = false
	echo_target = 576.0
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
	resume_mode = "brief"
	mode = "brief"

func begin_practice(lesson: int, return_page := "guide") -> void:
	stage = 0
	hp = MAX_HP
	player_rule = Rule.EMPTY
	mission_sector = false
	run_time = 0.0
	steals = 0
	hits_taken = 0
	regenerate_practice(lesson)
	practice_return = return_page

func regenerate_practice(lesson: int) -> void:
	practice = lesson
	practice_clear = false
	practice_hit = false
	_load_arena()
	p = Vector2(250, BASE)
	b = Vector2(520, BASE)
	practice_origin = p.x
	match practice:
		0:
			b.x = 925
		1:
			b.x = 344
			_set_state("exposed", 60.0)
		2:
			b.x = 770
		3:
			b.x = 484
			_set_state("exposed", 60.0)
		4:
			b.x = 435
			player_rule = Rule.RUSH
			_set_state("exposed", 60.0)
	mode = "fight"

func _finish_practice() -> void:
	practice_clear = false
	mode = "practice_done"
	hazards.clear()
	zones.clear()
	audio_rig.fire("open")

func _tick_fight(dt: float, axis: float, pressed: Dictionary, strike_held: bool) -> void:
	run_time += dt
	sector_time += dt
	capacitor_power = maxf(0.0, capacitor_power - dt)
	_tick_equipment(dt)
	if pressed.has("jump"):
		jump_buffer = 0.12
	if pressed.has("dodge"):
		dodge_buffer = 0.15
	if pressed.has("steal"):
		steal_buffer = 0.14
	if freeze > 0.0:
		freeze -= dt
		# Preserve a button edge if it fell inside a hit stop.
		for action in [&"steal", &"dodge", &"rule"]:
			if pressed.has(action):
				just[action] = true
		return
	hurt_iframes = maxf(0.0, hurt_iframes - dt)
	dodge_protection = maxf(0.0, dodge_protection - dt)
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
	if steal_buffer > 0.0 and route.active():
		route.steal(self)
		steal_buffer = 0.0
		if mode != "fight":
			return
	if steal_buffer > 0.0:
		steal_buffer = maxf(0.0, steal_buffer - dt)
		if can_shift() or steal_buffer <= 0.0:
			steal_buffer = 0.0
			_try_shift()
		if mode != "fight":
			return
	if pressed.has("rule"):
		_use_rule()
		if mode != "fight":
			return
	if dodge_buffer > 0.0 and dash_cd <= 0.0 and dash <= 0.0:
		if absf(axis) > 0.05:
			facing = signf(axis)
		dodge_buffer = 0.0
		dash = DODGE_TIME
		dash_speed = 493.5 if effects.has(19) else 705.0
		dash_cd = DODGE_COOLDOWN * _factor(2, 0.68, 12, 1.5)
		dodge_protection = DODGE_PROTECTION + (0.06 if assist else 0.0) + (0.14 if effects.has(7) else 0.0)
		audio_rig.fire("dodge")
	else:
		dodge_buffer = maxf(0.0, dodge_buffer - dt)
	if jump_buffer > 0.0 and coyote > 0.0:
		v.y = -560.0 * _factor(3, 1.2, 13, 0.78)
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
		speed *= _factor(1, 1.2, 11, 0.70) * (0.85 if effects.has(9) else 1.0)
		v.x = move_toward(v.x, axis * speed, accel * dt)
		v.y = minf(v.y + (300.0 if lift > 0.0 else 1660.0) * dt, 835.0)
	var previous_y := p.y
	if route.active():
		route.carry_platform(self, dt)
		previous_y = p.y
	p += v * dt
	p.x = clampf(p.x, LEFT, RIGHT)
	if floor_broken:
		floor_y = move_toward(floor_y, BASE + 64.0, 213.0 * dt)
	var surface := floor_y
	if route.active() and v.y >= 0.0:
		surface = route.surface(p, previous_y, surface)
	if floor_broken and (p.x <= DECK_LEFT or p.x >= DECK_RIGHT) and previous_y <= BASE + 0.5 and v.y >= 0.0:
		surface = BASE
	if p.y >= surface:
		if not grounded and v.y > 385.0:
			_burst(p, Color("#719398"), 9, 120.0)
		p.y = surface
		v.y = 0.0
		grounded = true
	else:
		grounded = false
	if strike_held and swing_cd <= 0.0:
		_strike()
	if mode != "fight":
		return
	if practice >= 0:
		_tick_practice(dt)
		return
	if route.active():
		route.tick(self, dt)
		return
	_tick_boss(dt)
	if mode == "fight":
		_tick_hazards(dt)
		for zone in environmental_zones():
			if zone.live:
				for lock in boss_locks.duplicate():
					if absf(lock.x - zone.box.get_center().x) <= 68.0:
						boss_locks.erase(lock)
						_impact(lock - Vector2(0, 24), Color("#badfff"))
				_check_hurt(zone.box, zone.box.get_center().x, stage in [1, 2, 3])
			if mode != "fight":
				break

func _tick_practice(dt: float) -> void:
	match practice:
		0:
			practice_clear = p.x - practice_origin >= 110.0 and p.y < BASE - 40.0
		1:
			practice_clear = boss_hp < boss_max_hp
		2:
			_tick_boss(dt)
			if state == "exposed" and not practice_clear:
				regenerate_practice(2)
				_report("Try again", "Dodge as the charge reaches you.", 2.0)
		3:
			practice_clear = steals > 0
		4:
			practice_clear = boss_hp < boss_max_hp and not charge
	if practice_clear:
		_finish_practice()

func environmental_zones() -> Array[Dictionary]:
	var zones_out: Array[Dictionary] = []
	if floor_broken:
		var cycle := fposmod(sector_time, 4.3)
		if cycle >= 2.1 and cycle < 3.58:
			zones_out.append({"box": Rect2(DECK_LEFT, floor_y - 22.0, DECK_RIGHT - DECK_LEFT, 25.0), "live": cycle >= 2.85, "color": Color("#89dce6")})
	elif stage == 2 and sector_time >= 2.0:
		var cycle := fposmod(sector_time - 2.0, 4.6)
		if cycle < 1.4:
			var offset := 0.0 if int((sector_time - 2.0) / 4.6) % 2 == 0 else 245.0
			for x in [218.0, 708.0]:
				zones_out.append({"box": Rect2(x + offset, 158, 96, BASE - 158), "live": cycle > 0.95, "color": Color("#f0ca73")})
	elif stage == 3 and sector_time >= 1.7:
		var cycle := fposmod(sector_time - 1.7, 4.8)
		if cycle < 1.23:
			var start := LEFT if int((sector_time - 1.7) / 4.8) % 2 == 0 else 571.0
			zones_out.append({"box": Rect2(start, BASE - 22, 513, 25), "live": cycle > 0.78, "color": Color("#ff795e")})
	elif stage == 4 and state == "exposed" and state_total - state_time > 0.12 and state_total - state_time < 1.05:
		var elapsed := state_total - state_time
		zones_out.append({"box": Rect2(echo_target - 68, 173, 136, BASE - 173), "live": elapsed >= 0.80, "color": Color("#a1cff8")})
	return zones_out

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
	if stage == ENCOUNTERS.size() - 1 and boss_rule != Rule.EMPTY:
		overclock_pending = true
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
	var consequence := Locale.text("Boss stripped  /  reserve rule warming up")
	if boss_rule != Rule.EMPTY:
		consequence = Locale.text("Boss inherited %s  /  its next attack changes") % Locale.text(RULE_NAMES[boss_rule])
	if player_rule == Rule.LIFT:
		consequence = Locale.text("Boss loses flight  /  lower deck breached" if stage == 1 and not floor_broken else "Boss loses flight  /  heavy impact")
		if stage == 1:
			floor_broken = true
		grounded = false
		v.y = -260.0
	_set_state("reboot", 0.62)
	_report(Locale.text("%s TRANSFERRED") % Locale.text(RULE_NAMES[player_rule]), consequence, 1.75)
	audio_rig.fire("steal")
	_damage_boss(4)

func _use_rule() -> void:
	if player_rule == Rule.EMPTY or not charge or effects.has(18):
		audio_rig.fire("deny")
		return
	charge = false
	if route.use_at_gate(self):
		audio_rig.fire("rule")
		return
	if effects.has(8):
		cell_cooldown = 2.0
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
			if route.active():
				route.strike(self)
			elif mission_sector and stage == 2 and absf(p.x - 952.0) < 155.0:
				_open_capacitor(2.15)
			elif ahead > -38.0 and ahead < 292.0 and absf(p.y - b.y) < 159.0:
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
	swing_cd = 0.265 * _factor(4, 0.72, 14, 1.4)
	audio_rig.fire("slash")
	if route.active():
		route.strike(self)
		return
	if mission_sector and stage == 2 and player_rule == Rule.RUSH and absf(p.x - 952.0) < 90.0:
		_open_capacitor(2.15)
	var ahead := (b.x - p.x) * facing
	var reach := 115.0 * _factor(5, 1.35, 15, 0.75)
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
	if mode != "fight" or not boss_locks.is_empty():
		return
	if mission_sector and stage == 2 and capacitor_power <= 0.0 and not state in ["reboot", "exposed"]:
		return
	if mission_sector:
		var bonus := _factor(0, 1.5, 10, 0.65) * (1.8 if effects.has(9) else 1.0)
		var exact := amount * bonus
		amount = floori(exact) + int(gear_rng.randf() < fposmod(exact, 1.0)) if not is_equal_approx(bonus, 1.0) else amount
		if amount <= 0:
			return
		_roll_drop(core_pos())
	boss_hp = maxi(0, boss_hp - amount)
	boss_flash = 0.14
	shake = maxf(shake, 5.0 if amount < 4 else 8.0)
	freeze = maxf(freeze, 0.027 if amount < 4 else 0.05)
	_burst(core_pos(), Color("#ffe4bd"), 9 + amount, 183.0)
	audio_rig.fire("hit")
	if boss_hp == 0:
		if mission_sector and stage == 5 and not evacuated:
			evacuated = true
			hazards.clear()
			zones.clear()
			p.x = 218.0
			p.y = BASE
			route.evacuation()
			_set_state("dead", 1.0)
			_report("Evacuate", Levels.GOALS.chase, 3.0)
		else:
			_finish_arena()

func _open_capacitor(duration: float) -> void:
	if capacitor_power > 0.0:
		return
	capacitor_power = duration
	zones.clear()
	_set_state("exposed", duration)
	_impact(core_pos(), RULE_COLORS[Rule.AEGIS])

func _factor(positive: int, gain: float, negative: int, loss: float) -> float:
	return (gain if effects.has(positive) else 1.0) * (loss if effects.has(negative) else 1.0)

func _roll_drop(at: Vector2) -> void:
	if not mission_sector or not drop.is_empty() or drop_cooldown > 0.0 or gear_rng.randf() >= Gear.DROP_CHANCE:
		return
	var stock := Gear.stock(campaign.records.size(), gear_rng.randf() >= 0.24)
	var id := stock[gear_rng.randi_range(0, stock.size() - 1)]
	var spot := Vector2(clampf(at.x, LEFT + 20.0, RIGHT - 20.0), clampf(at.y, 205.0, floor_y - 18.0))
	if absf(spot.x - p.x) < 67.0:
		spot.x = clampf(p.x + (84.0 if p.x < 576.0 else -84.0), LEFT, RIGHT)
	drop = {"id": id, "at": spot, "time": Gear.DROP_LIFETIME}
	drop_cooldown = 2.0
	_burst(spot, equipment_color(id), 13, 121.0)

func equipment_color(id: int) -> Color:
	return Color("#94efd0") if Gear.ITEMS[id][3] > 0 else Color("#ff947f")

func _equip(id: int) -> void:
	effects[id] = Gear.ITEMS[id][2]

func _tick_equipment(dt: float) -> void:
	drop_cooldown = maxf(0.0, drop_cooldown - dt)
	for id in effects.keys():
		if id == 16 and effects[id] > 4.0 and effects[id] - dt <= 4.0:
			hp = mini(MAX_HP, hp + 1)
			audio_rig.fire("rule")
		effects[id] -= dt
		if effects[id] <= 0.0:
			effects.erase(id)
	if cell_cooldown > 0.0:
		cell_cooldown -= dt
		if cell_cooldown <= 0.0 and effects.has(8):
			charge = true
	if drop.is_empty():
		return
	drop.time -= dt
	drop.at.y = move_toward(drop.at.y, route.surface(drop.at, drop.at.y, floor_y) - 21.0, dt * 145.0)
	if drop.time <= 0.0:
		drop.clear()
	elif (p - Vector2(0, 24)).distance_to(drop.at) <= 39.0:
		var id: int = drop.id
		_equip(id)
		_impact(drop.at, equipment_color(id))
		_report(Gear.ITEMS[id][0], Gear.ITEMS[id][1], 1.5)
		drop.clear()
		audio_rig.fire("pickup" if Gear.ITEMS[id][3] > 0 else "penalty")

func _finish_arena() -> void:
	if mode != "fight":
		return
	hazards.clear()
	zones.clear()
	mode = "win" if (sector_index == Levels.TABLE.size() - 1 if mission_sector else stage == ENCOUNTERS.size() - 1) else "clear"
	sector_result = {"seconds": sector_time, "hits": hits_taken - int(checkpoint.hits), "retries": sector_retries}
	if mission_sector:
		var fast: bool = sector_time <= Levels.TABLE[sector_index][5]
		var clean: bool = sector_result.hits <= (1 if Levels.TABLE[sector_index][2] == "boss" else 0)
		sector_result.stars = 1 + int(fast) + int(clean)
		sector_result.coins = sector_result.stars * 1000
		sector_result.fast = fast
		sector_result.clean = clean
		campaign.coins = mini(Gear.MAX_COINS, campaign.coins + sector_result.coins)
		campaign.complete(sector_index, checkpoint, sector_result, hp, player_rule)
		save_error = _save() != OK
	_set_state("dead", 1.0)
	_burst(core_pos(), RULE_COLORS[player_rule], 72, 410.0)
	rings.append({"at": core_pos(), "t": 0.62, "c": RULE_COLORS[player_rule], "r": 365.0})
	audio_rig.fire("win")
	if not mission_sector and mode == "win" and not assist and (best_time <= 0.0 or run_time < best_time):
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
				if move_name == "RAIL CUT" and overclock_attack and not rail_return:
					rail_return = true
					var previous_start := attack_from
					attack_from = b.x
					attack_to = previous_start
					b_facing = signf(attack_to - attack_from)
					zones.assign([Rect2(minf(attack_from, attack_to) - 43, floor_y - 61, absf(attack_to - attack_from) + 86, 61)])
					_set_state("windup", 0.45 + (0.12 if assist else 0.0))
					audio_rig.fire("warn")
					return
				if move_name == "SKY ANVIL":
					b.y = floor_y
					b.x = target_x
					_shockwave(b.x, 1)
					_shockwave(b.x, -1)
					if overclock_attack:
						_shockwave(b.x, 1, 0.28)
						_shockwave(b.x, -1, 0.28)
					_impact(core_pos(), RULE_COLORS[Rule.LIFT])
				charge = true
				echo_target = p.x
				_set_state("exposed", maxf(1.27, 1.62 - stage * 0.09) + (0.45 if assist else 0.0))
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
	overclock_attack = overclock_pending or (mission_sector and sector_index >= 24 and sector_time > 14.0 and boss_hp < boss_max_hp * 0.62)
	overclock_pending = false
	rail_return = false
	target_x = clampf(p.x, LEFT + 86, RIGHT - 86)
	b_facing = 1.0 if p.x >= b.x else -1.0
	var t := maxf(0.51, 0.73 - stage * 0.05) + (0.18 if assist else 0.0)
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
			var w := 118.0 + stage * 9.0 + (26.0 if overclock_attack else 0.0)
			var intervals := [0, -276, 276, -552, 552] if overclock_attack else [0, -276, 276]
			for offset in intervals:
				var x: float = target_x + offset
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

func _shockwave(x: float, direction: int, delay := 0.0) -> void:
	hazards.append({"box": Rect2(x - 23.0, floor_y - 34.0, 46.0, 37.0), "t": 1.07, "delay": delay, "v": direction * (480.0 + stage * 38.0), "c": ENCOUNTERS[stage].accent})

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

func _check_hurt(rect: Rect2, origin: float, floor_trap := false) -> void:
	var hurtbox := Rect2(p.x - 13.0, p.y - 37.0, 26.0, 34.0)
	if not rect.intersects(hurtbox) or mode != "fight":
		return
	if floor_trap and effects.has(17):
		return
	if dodge_protection > 0.0:
		if practice == 2:
			practice_clear = true
		return
	if hurt_iframes > 0.0:
		return
	if practice >= 0:
		practice_hit = true
		hurt_iframes = 0.6
		audio_rig.fire("hurt")
		return
	if guard > 0.0:
		guard = 0.0
		hurt_iframes = 0.42
		_impact(p - Vector2(0, 22), RULE_COLORS[Rule.AEGIS])
		audio_rig.fire("parry")
		if route.active():
			return
		var reflected := absf(p.x - b.x) < 396.0
		_report("PULSE PARRIED", "Reflected to the core" if reflected else "Too far to reflect", 1.3)
		if reflected:
			if mission_sector and stage == 2:
				_open_capacitor(3.0)
			_damage_boss(8)
		return
	if effects.has(6):
		effects.erase(6)
		hurt_iframes = 0.45
		_impact(p - Vector2(0, 22), equipment_color(6))
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
