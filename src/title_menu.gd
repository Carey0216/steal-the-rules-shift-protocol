extends CanvasLayer

const Locale = preload("res://src/locale.gd")
const INK := Color("#0b131b")
const PANEL := Color("#101b23")
const LINE := Color("#435561")
const PAPER := Color("#f5e9cd")
const DIM := Color("#b0bfc4")
const GREEN := Color("#81fbd2")
const SCALES := [1.0, 1.15, 1.3]
const SIZES := [Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900)]
const DEMOS := [
	["move", "Move & jump", "A/D + SPACE", "STICK + A", "Run toward the boss and jump over low attacks."],
	["strike", "Strike", "J / Z", "X", "Hold the strike button to keep swinging. An open core takes more damage."],
	["dodge", "Dodge", "K / X", "B", "Dodge through an attack just before it hits you."],
	["steal", "Steal a rule", "SHIFT / Q", "RB", "After an attack, approach the open core and press Shift. The boss takes your old rule."],
	["rule", "Use your rule", "E / C", "Y", "Use your current rule once per attack cycle. The recording shows RUSH, a forward dash strike."],
]
const FRAME_SIZE := Vector2i(480, 180)
const FRAMES_PER_SHEET := 20
const FRAME_COUNT := 40
const FPS := 10.0

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
	_draw_page()
	previous_mode = game.mode

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
	demo_sheets.clear()
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	if game.mode != "title":
		return
	match page:
		"language": _language()
		"settings": _settings()
		"guide": _guide()
		_: _title_controls()

func _title_controls() -> void:
	_button(ui, "Infiltrate", Rect2(59, 456, 293, 49), game._new_run, true)
	_button(ui, "Settings", Rect2(882, 25, 154, 44), _open.bind("settings"))
	var help := _button(ui, "?", Rect2(1047, 25, 48, 44), _open.bind("guide"))
	help.tooltip_text = _t("Controls guide")

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
				_option(panel, ["Windowed", "Fullscreen"], int(fills_screen), row, _change_display)
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
	_button(panel, "Done", Rect2(475, 462, 205, 46), back, true)
	selected_language.grab_focus()

func _change_language(index: int) -> void:
	game.set_language(index)
	_draw_page.call_deferred()

func _change_display(index: int) -> void:
	game.set_fullscreen(index == 1)
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
	var panel := _modal("Controls guide", Rect2(77, 42, 998, 564))
	var active: Button
	for i in DEMOS.size():
		var button := _button(panel, DEMOS[i][1], Rect2(28, 96 + i * 53, 238, 44), _choose_demo.bind(i), false, i == chapter)
		if i == chapter:
			active = button
	active.grab_focus()
	var demo: Array = DEMOS[chapter]
	_panel(panel, Rect2(281, 92, 689, 261), INK)
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(preview, panel, Rect2(282, 93, 687, 259))
	_label(panel, "Gameplay recording", Rect2(29, 371, 248, 30), 13, DIM)
	_label(panel, _t(demo[2]) + "    /    " + _t(demo[3]), Rect2(283, 366, 484, 35), 18, GREEN)
	_label(panel, demo[4], Rect2(283, 406, 687, 68), 16, PAPER, false, true)
	_panel(panel, Rect2(28, 484, 942, 1), LINE, LINE)
	demo_toggle = _button(panel, "Pause demo", Rect2(749, 359, 221, 42), _toggle_demo)
	_button(panel, "Done", Rect2(765, 502, 205, 42), back, true)
	demo_progress = ProgressBar.new()
	demo_progress.show_percentage = false
	demo_progress.max_value = FRAME_COUNT - 1
	demo_progress.add_theme_stylebox_override("background", _style(INK, INK, 0))
	demo_progress.add_theme_stylebox_override("fill", _style(GREEN, GREEN, 0))
	demo_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(demo_progress, panel, Rect2(282, 349, 687, 3))
	demo_texture = AtlasTexture.new()
	demo_texture.filter_clip = true
	preview.texture = demo_texture
	for i in 2:
		var path := "res://assets/demos/%s-%s.webp" % [demo[0], i]
		if ResourceLoader.exists(path):
			demo_sheets.append(load(path))
	if demo_sheets.size() != 2:
		_label(panel, "Demo unavailable", Rect2(326, 194, 530, 32), 17, DIM)
		demo_toggle.disabled = true
		return
	is_playing = not game.reduced_motion
	demo_toggle.text = _t("Pause demo" if is_playing else "Play")
	demo_time = 0.0 if is_playing else 2.2
	demo_frame = -1
	_show_frame()
	set_process(is_playing)

func _choose_demo(index: int) -> void:
	chapter = index
	_draw_page.call_deferred()

func _toggle_demo() -> void:
	is_playing = not is_playing
	demo_toggle.text = _t("Pause demo" if is_playing else "Play")
	set_process(is_playing)

func _process(delta: float) -> void:
	demo_time = fposmod(demo_time + delta, FRAME_COUNT / FPS)
	_show_frame()

func _show_frame() -> void:
	var frame := mini(FRAME_COUNT - 1, int(demo_time * FPS))
	if frame == demo_frame:
		return
	var local := frame % FRAMES_PER_SHEET
	var sheet := demo_sheets[frame / FRAMES_PER_SHEET]
	if demo_texture.atlas != sheet:
		demo_texture.atlas = sheet
	demo_texture.region = Rect2(Vector2i(local % 4, local / 4) * FRAME_SIZE, FRAME_SIZE)
	demo_frame = frame
	demo_progress.value = frame

func back() -> void:
	if page == "language":
		return
	if onboarding and page == "guide":
		onboarding = false
		game.guide_seen = true
		game._save()
	_open("")
