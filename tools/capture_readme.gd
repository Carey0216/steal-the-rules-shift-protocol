extends SceneTree
## Use graphical Godot: --path . --windowed --resolution 1152x648 --script tools/capture_readme.gd
## Writes real UI screenshots to builds/screens/readme without touching a player save.

const GAME := preload("res://main.tscn")
const Locale := preload("res://src/locale.gd")
const OUTPUT := "res://builds/screens/readme"

var game: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	game = GAME.instantiate()
	game.save_path = ""
	root.add_child(game)
	game.set_physics_process(false)
	game.set_fullscreen(false)
	game.audio_rig.set_mute(true)
	game.guide_seen = true
	game.title_menu.onboarding = false
	for index in 11:
		game.campaign.records.append({"entry_hp": 7, "entry_rule": 0, "seconds": 20.0, "stars": 2 + index % 2})
	game.campaign.coins = 18000
	game.title_menu.map_region = 1
	game.title_menu.map_focus = 11
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for index in Locale.CODES.size():
		game.set_language(index)
		var code: String = Locale.CODES[index].replace("_", "-")
		game.return_to_lobby()
		await _shot(code, "lobby")
		game.return_to_lobby("map")
		await _shot(code, "map")
		game.title_menu._open_shop(-1)
		await _shot(code, "equipment")
		game.title_menu._replay_context(14)
		game.title_menu.set_process(false)
		game.title_menu.demo_time = 2.5
		game.title_menu._show_frame()
		await _shot(code, "guide")
	quit(1 if failed else 0)

func _shot(code: String, view: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if frame.get_size() != Vector2i(1152, 648):
		frame.resize(1152, 648, Image.INTERPOLATE_LANCZOS)
	var path := "%s/%s-%s.png" % [OUTPUT, view, code]
	var result := frame.save_png(path)
	failed = failed or result != OK
	if result != OK:
		push_error("Screenshot failed: " + path)
