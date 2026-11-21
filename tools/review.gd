extends SceneTree
## Launch an isolated QA profile; never touches the player's normal save.
const GAME := preload("res://main.tscn")
func _initialize() -> void:
	call_deferred("_start")
func _start() -> void:
	var game := GAME.instantiate()
	game.save_path = "user://release-review.cfg"
	root.add_child(game)
	game.set_fullscreen(false)
