extends SceneTree
## Run with the graphical Godot binary: --path . --windowed --resolution 1152x648 --script tools/record_demos.gd
## Records the real arena while driving its public keyboard input. No combat state is scripted.

const GAME := preload("res://main.tscn")
const RECORDINGS := ["move", "strike", "dodge", "steal", "rule"]
const STEP := 1.0 / 120.0

var game: Node2D
var failed := false

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

func _record() -> void:
	game = GAME.instantiate()
	game.record_demo = true
	game.save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.title_menu.hide()
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
		_play(recording, tick)
		var before: int = game.boss_hp
		game._physics_process(STEP)
		jump_seen = jump_seen or game.p.y < game.floor_y - 55.0
		dodge_seen = dodge_seen or (game.dash > 0.0 and game.dash_speed < 800.0)
		strike_seen = strike_seen or (game.swing > 0.0 and before > game.boss_hp)
		ability_seen = ability_seen or (game.dash > 0.0 and before > game.boss_hp and not game.charge)
		if tick % 12 == 0:
			await RenderingServer.frame_post_draw
			var frame := root.get_texture().get_image()
			if frame.get_size() != Vector2i(1152, 648):
				frame.resize(1152, 648, Image.INTERPOLATE_LANCZOS)
			var cropped := frame.get_region(Rect2i(0, 135, 1152, 432))
			cropped.resize(480, 180, Image.INTERPOLATE_LANCZOS)
			if cropped.save_png("%s/%03d.png" % [folder, tick / 12]) != OK:
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
