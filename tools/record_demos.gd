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
	slate = InputSlate.new()
	root.add_child(slate)
	game.audio_rig.set_mute(true)
	game.reduced_motion = false
	game.assist = false
	game.combat_rng.seed = 26
	TranslationServer.set_locale("en")
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
		"strike": strike_seen and game.boss_hp < 30,
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
