extends SceneTree
## Run with the graphical Godot binary: --path . --windowed --resolution 1152x648 --script tools/record_demos.gd
## Records the real arena while driving its public keyboard input. No combat state is scripted.

const GAME := preload("res://main.tscn")
const RECORDINGS := ["move", "strike", "dodge", "steal", "rule"]
const STEP := 1.0 / 120.0

class InputSlate extends Node2D:
	const LABELS := {KEY_A: "A", KEY_D: "D", KEY_SPACE: "SPACE", KEY_J: "J", KEY_K: "K", KEY_SHIFT: "SHIFT", KEY_E: "E"}
	var keys: Array = []
	var active: Dictionary = {}
	var origin := Vector2.ZERO
	var dodge_ready := 1.0
	var rule_status := ""

	func _draw() -> void:
		var x := origin.x + 20.0
		var font := ThemeDB.fallback_font
		for key in keys:
			var size := 92.0 if key in [KEY_SHIFT, KEY_SPACE] else 54.0
			var at := Rect2(x, origin.y + 320.0, size, 36)
			var down: bool = Input.is_physical_key_pressed(key) or active.get(key, 0) > 0
			var fill := Color("#81fbd2") if down else Color("#18232b")
			var ink := Color("#0b131b") if down else Color("#f5e9cd")
			draw_rect(at, fill)
			draw_rect(at, Color("#8296a0"), false, 1.0)
			var label: String = LABELS[key]
			var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string(font, at.position + Vector2((size - width) * 0.5, 25), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, ink)
			x += size + 8.0
		if KEY_K in keys:
			draw_rect(Rect2(x, origin.y + 334.0, 116, 6), Color("#435561"))
			draw_rect(Rect2(x, origin.y + 334.0, 116 * dodge_ready, 6), Color("#81fbd2"))
		if KEY_SHIFT in keys:
			var badge := Rect2(origin + Vector2(20, 15), Vector2(284, 37))
			draw_rect(badge, Color("#122029"))
			draw_string(font, badge.position + Vector2(12, 25), rule_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#81fbd2"))

var game: Node2D
var failed := false
var slate: InputSlate

func _initialize() -> void:
	call_deferred("_record")

func _key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	event.shift_pressed = keycode == KEY_SHIFT and pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	if pressed:
		slate.active[keycode] = 24

func _record() -> void:
	game = GAME.instantiate()
	game.record_demo = true
	game.save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.title_menu.hide()
	game.title_menu.set_process(false)
	slate = InputSlate.new()
	root.add_child(slate)
	game.audio_rig.set_mute(true)
	game.reduced_motion = false
	game.assist = false
	game.combat_rng.seed = 26
	TranslationServer.set_locale("en")
	var requested := OS.get_cmdline_user_args()
	if requested.size() == 1 and requested[0].begins_with("--lesson="):
		var lesson := int(requested[0].get_slice("=", 1))
		if lesson == 13:
			await _shop_clip()
		else:
			await _context_clip(lesson)
	elif "--context" in requested:
		for lesson in range(game.Levels.LESSONS.size()):
			if lesson == 13:
				await _shop_clip()
			else:
				await _context_clip(lesson)
	elif "--supply" in OS.get_cmdline_user_args():
		await _context_clip(12)
		await _shop_clip()
	else:
		for recording in RECORDINGS:
			await _clip(recording)
	quit(1 if failed else 0)

func _clip(recording: String) -> void:
	var folder := "res://builds/recordings/" + recording
	DirAccess.make_dir_recursive_absolute(folder)
	var clips := {
		"move": [KEY_D, KEY_SPACE], "strike": [KEY_A, KEY_SPACE, KEY_J],
		"dodge": [KEY_K], "steal": [KEY_SPACE, KEY_A, KEY_SHIFT],
		"rule": [KEY_SHIFT, KEY_E],
	}
	slate.keys = clips[recording]
	slate.active.clear()
	var camera_x := 160.0
	_key(KEY_ENTER, true)
	game._physics_process(STEP)
	_key(KEY_ENTER, false)
	_key(KEY_ENTER, true)
	game._physics_process(STEP)
	_key(KEY_ENTER, false)
	var jump_seen := false
	var dodge_seen := false
	var strike_seen := false
	var ability_seen := false
	for tick in 480:
		for key in slate.active:
			slate.active[key] -= 1
		_play(recording, tick)
		var before: int = game.boss_hp
		game._physics_process(STEP)
		jump_seen = jump_seen or game.p.y < game.floor_y - 55.0
		dodge_seen = dodge_seen or (game.dash > 0.0 and game.dash_speed < 800.0)
		strike_seen = strike_seen or (game.swing > 0.0 and before > game.boss_hp)
		ability_seen = ability_seen or (game.dash > 0.0 and before > game.boss_hp and not game.charge)
		if tick % 8 == 0:
			var destination := clampf((game.p.x + game.b.x) * 0.5 - 410.0, 0.0, 332.0)
			camera_x = lerpf(camera_x, destination, 0.19)
			slate.origin = Vector2(roundf(camera_x), 188.0)
			slate.dodge_ready = clampf(1.0 - game.dash_cd / game.DODGE_COOLDOWN, 0.0, 1.0)
			slate.rule_status = "YOU: %s   BOSS: %s" % [game.RULE_NAMES[game.player_rule], game.RULE_NAMES[game.boss_rule]]
			slate.queue_redraw()
			await RenderingServer.frame_post_draw
			var frame := root.get_texture().get_image()
			if frame.get_size() != Vector2i(1152, 648):
				frame.resize(1152, 648, Image.INTERPOLATE_LANCZOS)
			var cropped := frame.get_region(Rect2i(int(slate.origin.x), 188, 820, 367))
			cropped.resize(576, 258, Image.INTERPOLATE_LANCZOS)
			if cropped.save_png("%s/%03d.png" % [folder, tick / 8]) != OK:
				failed = true
	var outcome: bool = {
		"move": jump_seen and game.p.x > 350.0,
		"strike": strike_seen and game.boss_hp < game.boss_max_hp,
		"dodge": dodge_seen and game.hits_taken == 0,
		"steal": game.steals == 1 and game.player_rule == game.Rule.RUSH,
		"rule": ability_seen and game.steals == 1,
	}[recording]
	if not outcome:
		failed = true
		push_error("%s recording failed its gameplay check (hull %s, boss HP %s, steals %s)." % [recording, game.hp, game.boss_hp, game.steals])
	print("%s: %s, hull %s, boss HP %s, steals %s" % [recording, "recorded" if outcome else "failed", game.hp, game.boss_hp, game.steals])
	game.mode = "title"
	game.just.clear()

func _context_clip(lesson: int) -> void:
	var training_sector: Array[int] = [0, 1, 3, 4, 6, 7, 9, 10, 14, 18, 23, 1, 1, -1, 24, 25, 27, 30, 29, 34]
	var index := training_sector[lesson]
	var folder := "res://builds/recordings/context-%02d" % lesson
	DirAccess.make_dir_recursive_absolute(folder)
	game.campaign.records.clear()
	for i in index:
		game.campaign.records.append({"entry_hp": 7, "entry_rule": 0, "seconds": 0, "stars": 1})
	game.campaign.next_rule = 0
	game.campaign.next_hull = 7
	game.campaign.reserved.clear()
	game.begin_sector(index)
	game.mode = "fight"
	game.record_demo = false
	game.title_menu.previous_mode = game.mode
	game.gear_rng.seed = 1
	slate.active.clear()
	slate.keys = [KEY_D, KEY_SPACE, KEY_J, KEY_K, KEY_SHIFT, KEY_E]
	var held := {}
	var focus := Vector2(game.p.x, 400)
	var success := false
	# Set a safe practice setup. The demonstration itself uses the shipped keyboard actions.
	match lesson:
		4, 9:
			game.p = game.route.socket if lesson == 4 else game.route.target()
		10:
			game.p.x = game.b.x - 74.0
			game.boss_hp = 1
			game._set_state("exposed", 5.0)
		11, 12:
			game.p.x = 389.0
			game.gear_rng.seed = _drop_seed(lesson == 12)
	for tick in 960:
		if game.mode == "fight":
			var desired := _context_input(lesson, tick)
			for key in slate.keys + [KEY_A]:
				var down: bool = desired.has(key)
				if down != held.has(key):
					_key(key, down)
					if down:
						held[key] = true
					else:
						held.erase(key)
			game._physics_process(STEP)
			if lesson == 3:
				success = success or game.route.cursor > 0
			elif lesson == 10:
				success = success or (game.evacuated and game.route.cursor > 0)
			elif lesson in [11, 12]:
				success = success or not game.effects.is_empty()
			else:
				success = success or game.route.cursor > 0
		if tick % 16 == 0:
			focus.x = lerpf(focus.x, game.p.x, 0.32)
			var camera_x := clampi(int(focus.x) - 410, 0, 332)
			slate.origin = Vector2(camera_x, 195.0)
			slate.rule_status = "YOU: %s" % game.RULE_NAMES[game.player_rule]
			slate.dodge_ready = clampf(1.0 - game.dash_cd / game.DODGE_COOLDOWN, 0.0, 1.0)
			for key in slate.active:
				slate.active[key] -= 16
			slate.queue_redraw()
			game.queue_redraw()
			await RenderingServer.frame_post_draw
			var frame := root.get_texture().get_image()
			if frame.get_size() != Vector2i(1152, 648):
				frame.resize(1152, 648, Image.INTERPOLATE_LANCZOS)
			var cropped := frame.get_region(Rect2i(camera_x, 195, 820, 367))
			cropped.resize(576, 258, Image.INTERPOLATE_LANCZOS)
			if cropped.save_png("%s/%03d.png" % [folder, tick / 16]) != OK:
				failed = true
	for key in held:
		_key(key, false)
	if not success:
		failed = true
		push_error("Context %02d failed its gameplay check (x %.0f, y %.0f; cursor %d; clock %.2f)." % [lesson, game.p.x, game.p.y, game.route.cursor, game.route.clock])
	else:
		print("Context %02d recorded" % lesson)
	game.mode = "title"
	game.just.clear()

func _drop_seed(negative: bool) -> int:
	var rng := RandomNumberGenerator.new()
	for seed_id in range(1, 1000):
		rng.seed = seed_id
		if rng.randf() < game.Gear.DROP_CHANCE and (rng.randf() < 0.24) == negative:
			return seed_id
	return 1

func _context_input(lesson: int, tick: int) -> Array:
	var route: RefCounted = game.route
	var keys := []
	if not route.active():
		return [KEY_J] if lesson == 10 else keys
	if lesson >= 14:
		return _extended_input(route, tick)
	var target: Vector2 = route.target()
	var phase := fmod(route.clock, 2.8)
	match lesson:
		0:
			return _extended_input(route, tick)
		4:
			if game.player_rule != game.Rule.AEGIS:
				return [KEY_SHIFT] if tick == 16 else []
			if absf(game.p.x - target.x) > 25:
				keys.append(KEY_D)
			if phase >= 2.18 and phase < 2.22:
				keys.append(KEY_E)
		9:
			if not route.echo.is_zero_approx() and phase < 2.65:
				keys.append(KEY_D)
			elif absf(game.p.x - target.x) > 30:
				keys.append(KEY_D if game.p.x < target.x else KEY_A)
		11, 12:
			if tick >= 19:
				keys.append(KEY_J)
			if tick >= 35:
				keys.append(KEY_D)
		_:
			if route.kind == "lift" and game.player_rule != game.Rule.LIFT:
				return [KEY_D] if game.p.x < 224 else ([KEY_SHIFT] if tick % 10 < 2 else [])
			if absf(game.p.x - target.x) > 22:
				keys.append(KEY_D if game.p.x < target.x else KEY_A)
			if lesson in [1, 7, 8]:
				keys.append(KEY_J)
			if lesson in [2, 3, 6] and game.p.x < 336 and tick % 40 == 24:
				keys.append(KEY_SHIFT)
			if lesson == 3 and game.charge and game.p.y > target.y and absf(game.p.x - target.x) < 172 and tick % 14 < 2:
				keys.append(KEY_E)
			elif ((lesson in [0, 2, 6] and tick % 84 < 4 and game.p.x > 350) or (target.y < game.BASE and absf(game.p.x - target.x) < 168)) and game.grounded and tick % 12 < 3:
				keys.append(KEY_SPACE)
			if lesson == 5 and absf(game.p.x - target.x) < 100 and tick % 24 < 4:
				keys.append(KEY_SHIFT)
			if lesson == 2 and tick % 29 < 3 and game.charge and game.player_rule == game.Rule.RUSH:
				keys.append(KEY_E)
			if lesson == 6 and tick % 57 < 4 and game.p.x > 315:
				keys.append(KEY_K)
	return keys

func _extended_input(route: RefCounted, tick: int) -> Array:
	var keys := []
	var target: Vector2 = route.target()
	var aim := target
	match route.kind:
		"ferry":
			if not route.ridden:
				aim = Vector2(route.ferry.get_center().x, route.ferry.position.y)
		"combo":
			keys.append(KEY_J)
		"key":
			if game.player_rule != route.required_rule:
				aim = route.socket
				if route.near(game.p, aim, 84.0) and tick % 18 < 3:
					keys.append(KEY_SHIFT)
			elif route.near(game.p, target, 88.0, 55.0) and tick % 18 < 3:
				keys.append(KEY_E)
		"evade":
			if route.near(game.p, target, 73.0) and route.pulse_phase() >= 2.22 and route.pulse_phase() < 2.25:
				aim.x += 105.0 if game.p.x <= target.x else -105.0
				keys.append(KEY_K)
		"hold":
			if route.echo != Vector2.ZERO:
				aim.x += 102.0
	if absf(aim.x - game.p.x) > 18.0:
		keys.append(KEY_D if aim.x > game.p.x else KEY_A)
	if (aim.y < game.p.y - 20.0 and absf(aim.x - game.p.x) < 142.0) and game.grounded and tick % 10 < 4:
		keys.append(KEY_SPACE)
	var box: Rect2 = route.hazard()
	if route.kind == "sensor" and box.grow(45).has_point(game.p - Vector2(0, 26)) and game.grounded and tick % 10 < 4:
		keys.append(KEY_SPACE)
	return keys

func _shop_clip() -> void:
	var folder := "res://builds/recordings/context-13"
	DirAccess.make_dir_recursive_absolute(folder)
	game.mode = "title"
	game.record_demo = false
	slate.hide()
	game.title_menu.show()
	game.title_menu.onboarding = false
	game.set_fullscreen(false)
	game.campaign.coins = 18000
	game.title_menu._open("")
	await process_frame
	await process_frame
	for index in 60:
		match index:
			6: _mouse(Vector2(949, 46))
			24: _mouse(Vector2(486, 201))
			40: _mouse(Vector2(950, 207))
		await process_frame
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		frame.resize(576, 324, Image.INTERPOLATE_LANCZOS)
		var cropped := frame.get_region(Rect2i(0, 22, 576, 258))
		if cropped.save_png("%s/%03d.png" % [folder, index]) != OK:
			failed = true
	if game.campaign.reserved.size() != 2 or game.campaign.coins != 6000:
		failed = true
		push_error("Catalog recording did not buy two items through the shop.")
	else:
		print("Context 13 recorded")

func _mouse(at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func _play(recording: String, tick: int) -> void:
	if recording == "move":
		match tick:
			16: _key(KEY_D, true)
			138: _key(KEY_SPACE, true)
			140: _key(KEY_SPACE, false)
			155: _key(KEY_D, false)
		return
	if recording == "dodge":
		match tick:
			189: _key(KEY_K, true)
			192: _key(KEY_K, false)
		return
	match tick:
		142: _key(KEY_SPACE, true)
		145: _key(KEY_SPACE, false)
		218: _key(KEY_A, true)
		231: _key(KEY_A, false)
	if recording == "strike":
		match tick:
			226: _key(KEY_J, true)
			398: _key(KEY_J, false)
	else:
		match tick:
			237: _key(KEY_SHIFT, true)
			240: _key(KEY_SHIFT, false)
			277:
				if recording == "rule":
					_key(KEY_E, true)
			280: _key(KEY_E, false)
