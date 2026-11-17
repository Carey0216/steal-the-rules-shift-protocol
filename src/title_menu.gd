extends CanvasLayer

const Locale = preload("res://src/locale.gd")
const INK := Color("#0b131b")
const PANEL := Color("#101b23")
const LINE := Color("#435561")
const PAPER := Color("#f5e9cd")
const DIM := Color("#b0bfc4")
const GREEN := Color("#81fbd2")
const AMBER := Color("#f4c57b")
const SCALES := [1.0, 1.15, 1.3]
const SIZES := [Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900)]
const DEMOS := [
	["move", "Move & jump", "A/D + SPACE", "STICK + A", "Move toward the boss. When a warning hugs the floor, jump as the attack approaches. Land close enough to counter."],
	["strike", "Strike", "J / Z", "X", "Face the boss and move within blade reach. Hold the strike button to keep swinging. The open core takes more damage."],
	["dodge", "Dodge", "K / X", "B", "Dodge through the charge as it reaches you. The outline shows protection. Wait for the dodge bar to refill."],
	["steal", "Steal a rule", "SHIFT / Q", "RB", "Survive the attack and approach the open core. Check what each side gains before pressing Shift."],
	["rule", "Use your rule", "E / C", "Y", "Face the boss and press E when the rule is ready. RUSH cuts forward, LIFT lifts you, and AEGIS reflects a nearby hit."],
]
const FRAME_SIZE := Vector2i(576, 258)
const FRAMES_PER_SHEET := 15
const FRAME_COUNT := 60
const FPS := 15.0

var game: Node2D
var ui: Control
var page := ""
var pending_locale := 0
var onboarding := false
var chapter := 0
var is_playing := false
var demo_time := 0.0
var demo_frame := -1
var demo_sheets: Array[Texture2D] = []
var demo_texture: AtlasTexture
var demo_progress: ProgressBar
var demo_toggle: Button
var preview: TextureRect
var previous_mode := ""
var display_picker: OptionButton
var web_document
var fullscreen_listener
var next_step_button: Button
var lesson_watched := {}

func _ready() -> void:
	layer = 4
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	set_process(false)
	if game.language_index < 0:
		page = "language"
		pending_locale = Locale.current()
		onboarding = true
	elif not game.guide_seen:
		page = "guide"
		onboarding = true
	if OS.has_feature("web"):
		var browser = Engine.get_singleton("JavaScriptBridge")
		web_document = browser.get_interface("document")
		fullscreen_listener = browser.create_callback(_sync_web_display)
		web_document.addEventListener("fullscreenchange", fullscreen_listener)
	_draw_page()
	previous_mode = game.mode

func _exit_tree() -> void:
	if web_document != null:
		web_document.removeEventListener("fullscreenchange", fullscreen_listener)

func _sync_web_display(_args: Array) -> void:
	if page == "settings" and is_instance_valid(display_picker):
		display_picker.select(int(game._display_is_fullscreen()))

func sync_mode() -> void:
	if game.mode == previous_mode:
		return
	previous_mode = game.mode
	_draw_page()

func _t(key: String) -> String:
	return Locale.text(key)

func _text_size(value: int) -> int:
	return roundi(value * SCALES[game.text_size_index])

func _style(fill: Color, border: Color, width := 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	return box

func _place(node: Control, parent: Control, at: Rect2) -> void:
	parent.add_child(node)
	node.position = at.position
	node.size = at.size

func _label(parent: Control, key: String, at: Rect2, size: int, shade := PAPER, large := false, wrap := false) -> Label:
	var label := Label.new()
	label.text = _t(key)
	label.add_theme_font_override("font", Locale.face(Locale.current(), large))
	label.add_theme_font_size_override("font_size", _text_size(size))
	label.add_theme_color_override("font_color", shade)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(label, parent, at)
	return label

func _panel(parent: Control, at: Rect2, fill: Color, border := LINE) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, border))
	_place(panel, parent, at)
	return panel

func _button(parent: Control, key: String, at: Rect2, callback: Callable, primary := false, selected := false) -> Button:
	var button := Button.new()
	button.text = _t(key)
	button.clip_text = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", Locale.face(Locale.current()))
	button.add_theme_font_size_override("font_size", _text_size(16))
	button.add_theme_color_override("font_color", INK if primary else PAPER)
	button.add_theme_color_override("font_hover_color", INK if primary else GREEN)
	button.add_theme_color_override("font_pressed_color", INK if primary else GREEN)
	button.add_theme_color_override("font_focus_color", INK if primary else PAPER)
	var surface := GREEN if primary else (Color("#23343e") if selected else PANEL)
	var normal := _style(surface, GREEN if primary else LINE)
	if selected:
		normal.border_color = GREEN
		normal.border_width_left = 3
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _style(surface.lightened(0.08), GREEN))
	button.add_theme_stylebox_override("pressed", _style(surface.darkened(0.06), GREEN))
	var focus := _style(Color.TRANSPARENT, GREEN, 2)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	_place(button, parent, at)
	return button

func _option(parent: Control, items: Array, chosen: int, at: Rect2, callback: Callable) -> OptionButton:
	var option := OptionButton.new()
	option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var font := Locale.face(Locale.current())
	if items == Locale.NAMES:
		var multilingual := FontVariation.new()
		multilingual.base_font = font
		multilingual.fallbacks = [Locale.face(1), Locale.face(2), Locale.face(3), Locale.face(4)]
		font = multilingual
	option.add_theme_font_override("font", font)
	option.add_theme_font_size_override("font_size", _text_size(17))
	option.add_theme_color_override("font_color", PAPER)
	option.add_theme_color_override("font_hover_color", GREEN)
	option.add_theme_color_override("font_focus_color", PAPER)
	for state in ["normal", "hover", "pressed"]:
		var chrome := _style(PANEL.lightened(0.07) if state == "hover" else PANEL, LINE if state == "normal" else GREEN)
		chrome.content_margin_left = 12
		chrome.content_margin_right = 10
		option.add_theme_stylebox_override(state, chrome)
	var focus := _style(Color.TRANSPARENT, GREEN, 2)
	focus.draw_center = false
	option.add_theme_stylebox_override("focus", focus)
	for item in items:
		option.add_item(_t(item))
	option.select(chosen)
	option.item_selected.connect(callback)
	var list := option.get_popup()
	list.add_theme_font_override("font", font)
	list.add_theme_font_size_override("font_size", _text_size(17))
	list.add_theme_stylebox_override("panel", _style(PANEL, LINE))
	_place(option, parent, at)
	return option

func _modal(title: String, at: Rect2) -> Panel:
	var dim := ColorRect.new()
	dim.color = Color("#070d15c9")
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_place(dim, ui, Rect2(0, 0, 1152, 648))
	var panel := _panel(ui, at, PANEL)
	_panel(panel, Rect2(0, 0, at.size.x, 2), GREEN, GREEN)
	_label(panel, title, Rect2(28, 21, at.size.x - 56, 45), 31, PAPER, true)
	return panel

func _draw_page() -> void:
	set_process(false)
	display_picker = null
	demo_sheets.clear()
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	match game.mode:
		"paused":
			_pause()
			return
		"clear", "win", "lost", "practice_done":
			_result()
			return
	if game.mode != "title":
		return
	match page:
		"language": _language()
		"settings": _settings()
		"guide": _guide()
		"map": _map()
		_: _title_controls()

func _title_controls() -> void:
	var open_map := _button(ui, "Sector map", Rect2(59, 465, 266, 54), _open.bind("map"), true)
	open_map.grab_focus()
	var gear := _button(ui, "", Rect2(987, 25, 48, 44), _open.bind("settings"))
	gear.tooltip_text = _t("Settings")
	gear.draw.connect(_draw_gear.bind(gear))
	var help := _button(ui, "?", Rect2(1047, 25, 48, 44), _open.bind("guide"))
	help.tooltip_text = _t("Controls guide")

func _draw_gear(gear: Button) -> void:
	var center := gear.size * 0.5
	var tint := GREEN if gear.is_hovered() else PAPER
	for i in 8:
		var ray := Vector2.from_angle(i * TAU / 8.0)
		gear.draw_line(center + ray * 8.0, center + ray * 11.5, tint, 3.0, true)
	gear.draw_circle(center, 8.0, tint, false, 2.0, true)
	gear.draw_circle(center, 3.2, tint, false, 1.6, true)

func _open(next: String) -> void:
	page = next
	_draw_page()

func _language() -> void:
	var panel := _modal("Select a language", Rect2(303, 63, 546, 522))
	_label(panel, "You can change this anytime in Settings.", Rect2(28, 72, 490, 32), 15, DIM)
	var selected_button: Button
	for i in Locale.NAMES.size():
		var button := _button(panel, Locale.NAMES[i], Rect2(28, 123 + i * 55, 490, 45), _select_first_language.bind(i), false, pending_locale == i)
		button.add_theme_font_override("font", Locale.face(i))
		if pending_locale == i:
			selected_button = button
	_button(panel, "Continue to guide", Rect2(28, 429, 490, 50), _confirm_language, true)
	selected_button.grab_focus()

func _select_first_language(index: int) -> void:
	pending_locale = index
	TranslationServer.set_locale(Locale.CODES[index])
	_draw_page.call_deferred()

func _confirm_language() -> void:
	game.set_language(pending_locale)
	chapter = 0
	_open("guide")

func _settings() -> void:
	var panel := _modal("Settings", Rect2(222, 56, 708, 536))
	var names := ["Language", "Display mode", "Window size", "Text size", "Audio", "Reduced motion", "Assist mode"]
	var selected_language: OptionButton
	var is_web := OS.has_feature("web")
	var fills_screen: bool = game._display_is_fullscreen()
	for i in names.size():
		var y := 84 + i * 50
		_panel(panel, Rect2(28, y - 5, 652, 1), LINE, LINE)
		_label(panel, names[i], Rect2(31, y + 5, 320, 31), 17)
		var row := Rect2(351, y, 329, 38)
		match names[i]:
			"Language":
				selected_language = _option(panel, Locale.NAMES, Locale.current(), row, _change_language)
			"Display mode":
				display_picker = _option(panel, ["Windowed", "Fullscreen"], int(fills_screen), row, _change_display)
				if is_web:
					display_picker.disabled = not web_document.fullscreenEnabled
			"Window size":
				var choice := _option(panel, ["1152 × 648", "1280 × 720", "1600 × 900"], game.window_size_index, row, _change_window_size)
				choice.disabled = is_web or fills_screen
			"Text size":
				_option(panel, ["100%", "115%", "130%"], game.text_size_index, row, _change_text_size)
			"Audio":
				_option(panel, ["Off", "On"], int(not game.muted), row, _change_audio)
			"Reduced motion":
				_option(panel, ["Off", "On"], int(game.reduced_motion), row, _change_motion)
			"Assist mode":
				var assist_option := _option(panel, ["Off", "On"], int(game.assist), row, _change_assist)
				assist_option.tooltip_text = _t("Larger timing windows for steals and dodges.")
	var exit_label := "Save and return" if is_web else "Save and quit"
	_button(panel, exit_label, Rect2(28, 462, 260, 46), game.save_and_quit)
	_button(panel, "Done", Rect2(475, 462, 205, 46), back, true)
	_show_save_notice(panel, Rect2(28, 419, 650, 32))
	selected_language.grab_focus()

func show_save_error() -> void:
	game.save_error = true
	_draw_page.call_deferred()

func _show_save_notice(parent: Control, at: Rect2) -> void:
	if game.save_error:
		_label(parent, "Could not save. Try again before closing.", at, 13, AMBER)

func _map() -> void:
	var panel := _modal("Sector map", Rect2(66, 40, 1020, 568))
	var completed: int = game.campaign.records.size()
	var total: int = game.ENCOUNTERS.size()
	_label(panel, _t("%d of %d sectors cleared") % [completed, total], Rect2(29, 71, 720, 35), 15, DIM)
	_button(panel, "Lobby", Rect2(816, 24, 176, 46), back)
	var focused: Button
	for index in total:
		var row := index / 3
		var col := index % 3 if row == 0 else 2 - index % 3
		var x := 28.0 + col * 329.0
		var y := 135.0 + row * 173.0
		var lit := index < completed
		var next := index == completed
		if index < total - 1:
			var rail := GREEN.darkened(0.4) if index < completed else LINE
			if index == 2:
				_panel(panel, Rect2(x + 152, y + 119, 2, 54), rail, rail)
			else:
				var edge := x + 304.0 if row == 0 else x - 25.0
				_panel(panel, Rect2(edge, y + 55, 25, 2), rail, rail)
		var tile := _button(panel, "", Rect2(x, y, 304, 119), game.begin_sector.bind(index), false, next)
		tile.disabled = not lit and not next
		var status := "Cleared" if lit else ("Next sector" if next else "Locked")
		var tone := GREEN if lit else (AMBER if next else DIM)
		_panel(tile, Rect2(0, 0, 304, 3), tone.darkened(0.33 if lit or next else 0.65), tone)
		_label(tile, "%02d  /  %s" % [index + 1, _t(status)], Rect2(14, 9, 270, 28), 13, tone)
		_label(tile, game.ENCOUNTERS[index].name, Rect2(14, 36, 271, 42), 27, PAPER if lit or next else DIM, true)
		if lit:
			var result: Dictionary = game.campaign.records[index]
			_label(tile, _t("%s  /  %s hits  /  %s retries") % [game.timecode(result.seconds), result.hits, result.retries], Rect2(14, 84, 275, 26), 11, DIM)
		if next or (completed == total and index == total - 1):
			focused = tile
	_label(panel, "Select a cleared sector to replay it.", Rect2(29, 499, 700, 36), 14, DIM)
	_show_save_notice(panel, Rect2(560, 499, 440, 36))
	if focused != null:
		focused.grab_focus()

func _pause() -> void:
	var panel := _modal("LINK PAUSED", Rect2(317, 163, 518, 322))
	if game.save_error:
		_show_save_notice(panel, Rect2(29, 75, 458, 44))
	else:
		_label(panel, "Your cleared sectors are saved.", Rect2(29, 75, 458, 44), 15, DIM, false, true)
	var resume := _button(panel, "RESUME", Rect2(28, 126, 462, 48), _resume, true)
	_button(panel, "Restart sector", Rect2(28, 185, 462, 44), game._retry)
	if game.practice >= 0 and onboarding:
		_button(panel, "Return to guide", Rect2(28, 239, 462, 44), game.return_from_practice)
	else:
		_button(panel, "Return to lobby", Rect2(28, 239, 462, 44), game.return_to_lobby)
	resume.grab_focus()

func _resume() -> void:
	game.mode = game.resume_mode

func _result() -> void:
	var title: String = {
		"lost": "HULL BREACHED", "practice_done": "Practice complete",
		"win": "RULES REWRITTEN", "clear": "Sector secured",
	}[game.mode]
	var panel := _modal(title, Rect2(251, 172, 650, 304))
	var text_line := "You can try another action from the guide."
	var action := "Return to guide"
	var callback: Callable = game.return_from_practice
	if game.mode in ["clear", "win"]:
		var score: Dictionary = game.sector_result
		text_line = _t("%s  /  %s hits  /  %s retries") % [game.timecode(score.get("seconds", 0.0)), score.get("hits", 0), score.get("retries", 0)]
		action = "Sector map"
		callback = game.return_to_lobby.bind("map")
	elif game.mode == "lost":
		text_line = "Reboot from this sector with your entry loadout."
		action = "REBOOT"
		callback = game._retry
	_label(panel, text_line, Rect2(29, 83, 590, 75), 17, DIM, false, true)
	_show_save_notice(panel, Rect2(29, 154, 590, 32))
	var proceed := _button(panel, action, Rect2(28, 202, 298, 52), callback, true)
	if game.mode in ["lost", "clear", "win"]:
		_button(panel, "Return to lobby", Rect2(343, 202, 278, 52), game.return_to_lobby)
	proceed.grab_focus()

func _change_language(index: int) -> void:
	game.set_language(index)
	_draw_page.call_deferred()

func _change_display(index: int) -> void:
	game.set_fullscreen(index == 1)
	if not OS.has_feature("web"):
		_draw_page.call_deferred()

func _change_window_size(index: int) -> void:
	game.window_size_index = index
	game.set_fullscreen(false)

func _change_text_size(index: int) -> void:
	game.text_size_index = index
	game._save()
	_draw_page.call_deferred()

func _change_audio(index: int) -> void:
	game.muted = index == 0
	game.audio_rig.set_mute(game.muted)
	game._save()

func _change_motion(index: int) -> void:
	game.reduced_motion = index == 1
	game._save()

func _change_assist(index: int) -> void:
	game.assist = index == 1
	game._save()

func _guide() -> void:
	var panel := _modal("Controls guide", Rect2(62, 38, 1028, 572))
	_label(panel, _t("Lesson %d of %d") % [chapter + 1, DEMOS.size()], Rect2(776, 26, 222, 37), 14, DIM)
	for i in DEMOS.size():
		var name := "%d   %s" % [i + 1, _t(DEMOS[i][1])]
		var tab := _button(panel, name, Rect2(28 + i * 196, 83, 186, 42), _choose_demo.bind(i), false, i == chapter)
		tab.add_theme_font_size_override("font_size", _text_size(13))
		tab.disabled = onboarding and i > chapter and not lesson_watched.has(i - 1)
	var demo: Array = DEMOS[chapter]
	_panel(panel, Rect2(28, 150, 604, 273), INK)
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(preview, panel, Rect2(29, 151, 602, 271))
	_label(panel, demo[1], Rect2(659, 148, 339, 44), 28, PAPER, true)
	_label(panel, _t(demo[2]) + "  /  " + _t(demo[3]), Rect2(660, 203, 334, 38), 17, GREEN)
	_label(panel, demo[4], Rect2(659, 251, 335, 154), 15, PAPER, false, true)
	demo_toggle = _button(panel, "Pause demo", Rect2(29, 433, 218, 43), _toggle_demo)
	_label(panel, "Gameplay recording", Rect2(261, 440, 370, 32), 12, DIM)
	_button(panel, "Try it", Rect2(659, 433, 337, 43), game.begin_practice.bind(chapter, "guide"))
	_panel(panel, Rect2(28, 490, 969, 1), LINE, LINE)
	if chapter > 0:
		_button(panel, "Previous", Rect2(28, 509, 198, 44), _choose_demo.bind(chapter - 1))
	if not onboarding:
		_button(panel, "Lobby", Rect2(239 if chapter > 0 else 28, 509, 174, 44), back)
	var last := chapter == DEMOS.size() - 1
	next_step_button = _button(panel, ("Enter lobby" if onboarding else "Done") if last else "Next lesson", Rect2(756, 508, 240, 46), _next_lesson, true)
	next_step_button.disabled = onboarding and not lesson_watched.has(chapter) and not game.reduced_motion
	demo_progress = ProgressBar.new()
	demo_progress.show_percentage = false
	demo_progress.max_value = FRAME_COUNT - 1
	demo_progress.add_theme_stylebox_override("background", _style(INK, INK, 0))
	demo_progress.add_theme_stylebox_override("fill", _style(GREEN, GREEN, 0))
	demo_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(demo_progress, panel, Rect2(29, 419, 602, 3))
	demo_texture = AtlasTexture.new()
	demo_texture.filter_clip = true
	preview.texture = demo_texture
	for i in range(ceili(float(FRAME_COUNT) / FRAMES_PER_SHEET)):
		var path := "res://assets/demos/%s-%s.webp" % [demo[0], i]
		if ResourceLoader.exists(path):
			demo_sheets.append(load(path))
	if demo_sheets.size() != ceili(float(FRAME_COUNT) / FRAMES_PER_SHEET):
		_label(panel, "Demo unavailable", Rect2(58, 252, 525, 38), 17, DIM)
		demo_toggle.disabled = true
		_mark_lesson_watched()
	else:
		is_playing = not game.reduced_motion
		demo_toggle.text = _t("Pause demo" if is_playing else "Play")
		demo_time = 0.0 if is_playing else 2.3
		demo_frame = -1
		_show_frame()
		set_process(is_playing)
		if game.reduced_motion:
			_mark_lesson_watched()
	if next_step_button.disabled:
		demo_toggle.grab_focus()
	else:
		next_step_button.grab_focus()

func _choose_demo(index: int) -> void:
	if onboarding and index > chapter and not lesson_watched.has(index - 1):
		return
	chapter = index
	_draw_page.call_deferred()

func _next_lesson() -> void:
	if onboarding and not lesson_watched.has(chapter):
		return
	if chapter < DEMOS.size() - 1:
		_choose_demo(chapter + 1)
	else:
		_finish_guide()

func _finish_guide() -> void:
	onboarding = false
	game.guide_seen = true
	game._save()
	chapter = 0
	_open("")

func _toggle_demo() -> void:
	if not is_playing and demo_time >= FRAME_COUNT / FPS:
		demo_time = 0.0
		_show_frame()
	is_playing = not is_playing
	demo_toggle.text = _t("Pause demo" if is_playing else "Play")
	set_process(is_playing)

func _process(delta: float) -> void:
	demo_time = minf(demo_time + delta, FRAME_COUNT / FPS)
	_show_frame()
	if demo_time >= FRAME_COUNT / FPS:
		is_playing = false
		set_process(false)
		demo_toggle.text = _t("Replay demo")
		_mark_lesson_watched()

func _mark_lesson_watched() -> void:
	lesson_watched[chapter] = true
	next_step_button.disabled = false
	if onboarding and get_viewport().gui_get_focus_owner() == demo_toggle:
		next_step_button.grab_focus()

func _show_frame() -> void:
	var frame := mini(FRAME_COUNT - 1, int(demo_time * FPS))
	if frame == demo_frame:
		return
	var local := frame % FRAMES_PER_SHEET
	var sheet := demo_sheets[frame / FRAMES_PER_SHEET]
	if demo_texture.atlas != sheet:
		demo_texture.atlas = sheet
	demo_texture.region = Rect2(Vector2i(local % 3, local / 3) * FRAME_SIZE, FRAME_SIZE)
	demo_frame = frame
	demo_progress.value = frame

func back() -> void:
	if page == "language":
		return
	if onboarding and page == "guide":
		if chapter > 0:
			_choose_demo(chapter - 1)
		return
	chapter = 0
	_open("")
