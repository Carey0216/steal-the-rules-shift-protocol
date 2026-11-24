extends "res://tests/smoke.gd"
## Exercise actual guide buttons, modal actions, cancellation and deployment.

func _run() -> void:
	g = GAME.instantiate()
	g.save_path = ""
	root.add_child(g)
	g.set_physics_process(false)
	g.audio_rig.set_mute(true)
	g.set_language(0)
	g.campaign = Campaign.new()
	var menu = g.title_menu
	menu.onboarding = true
	menu.lesson_watched.clear()
	menu.chapter = 0
	menu._open("guide")
	_check(not menu.skip_button.disabled and menu.next_step_button.disabled, "Skip is available before watching the clip.")
	menu.skip_button.pressed.emit()
	_check(is_instance_valid(menu.skip_dialog) and menu.chapter == 0, "A sequence offers the two skip scopes before changing lessons.")
	var elapsed: float = menu.demo_time
	_check(not menu.is_processing(), "The recording pauses while choosing the skip scope.")
	menu.skip_dialog.canceled.emit()
	_check(not is_instance_valid(menu.skip_dialog) and menu.demo_time == elapsed and menu.is_processing(), "Cancellation resumes the same recording without losing its position.")
	menu.skip_button.pressed.emit()
	menu.back()
	_check(menu.chapter == 0 and not is_instance_valid(menu.skip_dialog), "Back closes only the skip dialog.")
	menu.skip_button.pressed.emit()
	menu.skip_dialog.confirmed.emit()
	await process_frame
	_check(menu.chapter == 1 and menu.page == "guide" and g.mode == "title", "Skip current advances exactly one basic lesson.")
	menu.skip_button.pressed.emit()
	# Locate the custom action by its translated label, independent of OS button order.
	var all_button := _find_button(menu.skip_dialog, Locale.text("Skip all this time"))
	_check(all_button != null, "The modal exposes a distinct skip-all action.")
	if all_button != null:
		all_button.pressed.emit()
	menu.sync_mode()
	_check(g.mode == "fight" and g.sector_index == 0 and g.guide_seen and not menu.onboarding, "Skipping all onboarding lessons begins a playable sector immediately.")
	_check(not menu.is_processing() and menu.ui.get_child_count() == 0, "No tutorial controls or playback remain over combat.")
	_check(g.campaign.lessons.is_empty(), "Skipping onboarding does not mark campaign mechanics watched.")
	g.return_to_lobby()
	# Sector 2 has several contextual lessons; make only that frontier selectable.
	g.campaign.records.append({"entry_hp": 7, "entry_rule": 0})
	menu._prepare_from_lobby(1)
	menu._start_selected()
	var active: int = menu.active_lesson
	var remaining: int = menu.lesson_pending.size()
	_check(remaining > 0, "The context fixture contains more than one lesson.")
	menu.skip_button.pressed.emit()
	menu.skip_dialog.confirmed.emit()
	_check(menu.active_lesson != active and menu.lesson_pending.size() == remaining - 1 and g.mode == "title", "Skip current advances one contextual lesson without deployment.")
	menu.skip_button.pressed.emit()
	menu._skip_lessons(true)
	menu.sync_mode()
	_check(g.mode == "fight" and g.sector_index == 1 and menu.lesson_pending.is_empty(), "Skip all contextual lessons enters the selected sector.")
	_check(g.campaign.lessons.is_empty(), "Context skips remain limited to this deployment.")
	g.return_to_lobby()
	menu._prepare_from_lobby(1)
	menu._start_selected()
	_check(menu.active_lesson == active, "Skipped mechanics remain eligible on another deployment.")
	g.return_to_lobby()
	menu._prepare_from_lobby(0)
	menu._start_selected()
	_check(menu.lesson_pending.is_empty(), "The single-lesson fixture has no subsequent clip.")
	menu.skip_button.pressed.emit()
	_check(g.mode == "fight" and not is_instance_valid(menu.skip_dialog), "One contextual lesson skips directly without a scope dialog.")
	g.return_to_lobby()
	menu.chapter = 4
	menu.onboarding = true
	menu._open("guide")
	menu.skip_button.pressed.emit()
	_check(g.mode == "fight" and not is_instance_valid(menu.skip_dialog), "The final onboarding lesson skips directly into gameplay.")
	g.return_to_lobby()
	menu.onboarding = false
	menu.chapter = 4
	menu._open("guide")
	menu.skip_button.pressed.emit()
	_check(menu.page == "archive" and g.mode == "title", "A voluntary archive replay returns to the archive.")
	menu._replay_context(0)
	menu.skip_button.pressed.emit()
	_check(menu.page == "archive" and not is_instance_valid(menu.skip_dialog), "A standalone mechanic replay closes directly.")
	for language in Locale.CODES.size():
		g.set_language(language)
		g.text_size_index = 2
		menu.chapter = 0
		menu._open("guide")
		menu.skip_button.pressed.emit()
		_check(menu.skip_dialog.get_ok_button().text == Locale.text("Skip current"), "Skip actions use the chosen language at 130% text.")
		menu.skip_dialog.canceled.emit()
		menu._toggle_demo()
		menu.skip_button.pressed.emit()
		menu.skip_dialog.canceled.emit()
		_check(not menu.is_processing(), "Cancel preserves a manually paused recording.")
		menu._open("archive")
	g.text_size_index = 0
	await process_frame
	print("Guide skip result: ", failed, " failures")
	quit(1 if failed else 0)

func _find_button(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children(true):
		var found := _find_button(child, label)
		if found != null:
			return found
	return null
