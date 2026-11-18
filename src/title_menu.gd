extends CanvasLayer

const Locale = preload("res://src/locale.gd")
const Levels = preload("res://src/levels.gd")
const Gear = preload("res://src/gear.gd")
const Icons = preload("res://src/equipment_icons.gd")
const INK := Color("#101822")
const PANEL := Color("#18232f")
const LINE := Color("#4a5968")
const PAPER := Color("#f7efdc")
const DIM := Color("#bcc9d4")
const GREEN := Color("#a9dfcd")
const AMBER := Color("#f1cc90")
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
var sector_pending := -1
var gear_page := 0
var dossier := 0
var lesson_pending: Array[int] = []
var active_lesson := -1
var money_clicks := 0
var money_deadline := 0
var money_authorized := false
var map_region := -1
var map_focus := -1
var last_view := ""
var opening_page := false
var painted_region := -1
var demo_rate := 1.0
var demo_speed: Button

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
	if game.boot_time > 0.0:
		var intro := CanvasLayer.new()
		intro.layer = 8
		add_child(intro)
		var cover := ColorRect.new()
		cover.color = INK
		cover.size = Vector2(1152, 648)
		cover.mouse_filter = Control.MOUSE_FILTER_STOP
		intro.add_child(cover)
		var emblem := TextureRect.new()
		emblem.texture = preload("res://assets/icon.svg")
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(emblem, cover, Rect2(526, 156, 100, 100))
		var mark := _label(cover, "SHIFT PROTOCOL", Rect2(216, 274, 720, 78), 48, PAPER, true)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.modulate.a = 0.0
		var beam := _panel(cover, Rect2(138, 375, 1, 2), GREEN, GREEN)
		var animation := create_tween()
		animation.tween_property(beam, "size:x", 876.0, 0.48).set_trans(Tween.TRANS_CUBIC)
		animation.parallel().tween_property(mark, "modulate:a", 1.0, 0.35).set_delay(0.09)
		animation.tween_property(cover, "modulate:a", 0.0, 0.30)
		animation.tween_callback(intro.queue_free)

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
	box.set_corner_radius_all(9)
	box.corner_detail = 6
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
	var surface := AMBER if primary else (Color("#354352") if selected else Color("#23303d"))
	var normal := _style(surface, AMBER if primary else LINE)
	if selected:
		normal.border_color = AMBER
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _style(surface.lightened(0.13), AMBER))
	button.add_theme_stylebox_override("pressed", _style(surface.darkened(0.13), AMBER))
	button.add_theme_stylebox_override("disabled", _style(INK, LINE.darkened(0.4)))
	var focus := _style(Color.TRANSPARENT, AMBER, 2)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func():
		game.audio_rig.fire("ui_confirm")
		callback.call()
	)
	button.focus_entered.connect(func(): game.audio_rig.fire("ui_focus"))
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
	dim.color = Color("#060b14b5")
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_place(dim, ui, Rect2(0, 0, 1152, 648))
	var panel := _panel(ui, at, PANEL, Color("#6f675e"))
	var skin := panel.get_theme_stylebox("panel") as StyleBoxFlat
	skin.set_corner_radius_all(16)
	skin.shadow_color = Color("#03061198")
	skin.shadow_size = 18
	skin.shadow_offset = Vector2(0, 8)
	_label(panel, title, Rect2(28, 19, at.size.x - 104, 52), 34, PAPER, true)
	if opening_page and not game.reduced_motion and not game.save_path.is_empty():
		dim.modulate.a = 0.0
		panel.modulate.a = 0.0
		panel.pivot_offset = at.size / 2.0
		panel.scale = Vector2(0.982, 0.982)
		panel.position.y += 10.0
		var entrance := panel.create_tween().set_parallel(true)
		entrance.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		entrance.tween_property(dim, "modulate:a", 1.0, 0.18)
		entrance.tween_property(panel, "modulate:a", 1.0, 0.19)
		entrance.tween_property(panel, "position:y", at.position.y, 0.25)
		entrance.tween_property(panel, "scale", Vector2.ONE, 0.25)
	return panel

func _draw_page() -> void:
	set_process(false)
	var view: String = game.mode + ":" + page
	opening_page = view != last_view
	last_view = view
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
		"shop": _shop()
		"archive": _archive()
		"new_lesson": _new_lesson()
		"reset": _reset()
		"money": _money()
		_: _title_controls()

func _title_controls() -> void:
	var open_map := _button(ui, "Sector map", Rect2(66, 457, 279, 56), _open_map, true)
	open_map.grab_focus()
	var gear := _button(ui, "", Rect2(987, 25, 48, 44), _open.bind("settings"))
	gear.tooltip_text = _t("Settings")
	gear.draw.connect(_draw_gear.bind(gear))
	var help := _button(ui, "?", Rect2(1047, 25, 48, 44), _open_archive.bind(0))
	help.tooltip_text = _t("Controls guide")
	var wallet := _button(ui, "", Rect2(719, 25, 188, 44), _wallet_pressed)
	wallet.focus_mode = Control.FOCUS_NONE
	wallet.tooltip_text = _t("Coins")
	_label(wallet, str(game.campaign.coins), Rect2(51, 3, 132, 37), 17, AMBER)
	wallet.draw.connect(_currency_icon.bind(wallet, false))
	var shop := _button(ui, "", Rect2(925, 25, 48, 44), _open_shop.bind(-1))
	shop.tooltip_text = _t("Equipment shop")
	shop.draw.connect(_currency_icon.bind(shop, true))

func _open_map() -> void:
	map_region = -1
	painted_region = -1
	map_focus = -1
	_open("map")

func _back_arrow(parent: Control, at: Rect2, callback: Callable, tip := "Return to lobby") -> Button:
	var button := _button(parent, "", at, callback)
	button.tooltip_text = _t(tip)
	button.draw.connect(func():
		var c := button.size / 2.0
		var tint := AMBER if button.is_hovered() or button.has_focus() else PAPER
		button.draw_polyline(PackedVector2Array([c + Vector2(-1, -8), c + Vector2(-9, 0), c + Vector2(-1, 8)]), tint, 1.9, true)
		button.draw_line(c + Vector2(-8, 0), c + Vector2(10, 0), tint, 1.9, true)
	)
	return button

func _currency_icon(button: Button, cart: bool) -> void:
	var center := Vector2(25, 22)
	var color := GREEN if button.is_hovered() else AMBER
	if cart:
		var outline := PackedVector2Array([center + Vector2(-14, -9), center + Vector2(-10, -9), center + Vector2(-6, 4), center + Vector2(8, 4), center + Vector2(12, -5), center + Vector2(-8, -5)])
		button.draw_polyline(outline, color, 1.6, true)
		button.draw_circle(center + Vector2(-3, 9), 2, color)
		button.draw_circle(center + Vector2(7, 9), 2, color)
	else:
		button.draw_circle(center, 11.0, color, false, 1.8, true)
		button.draw_arc(center, 7.0, 0.07, TAU - 0.07, 26, color.darkened(0.12), 1.2, true)
		button.draw_line(center + Vector2(0, -4), center + Vector2(0, 4), color, 1.8, true)

func _wallet_pressed() -> void:
	var now := Time.get_ticks_msec()
	money_clicks = money_clicks + 1 if now <= money_deadline else 1
	if money_clicks == 1:
		money_deadline = now + 2400
	if money_clicks == 5:
		money_clicks = 0
		money_authorized = false
		_open.call_deferred("money")

func _money() -> void:
	var panel := _modal("", Rect2(341, 245, 470, 138))
	var entry := LineEdit.new()
	entry.max_length = 9
	entry.secret = not money_authorized
	_place(entry, panel, Rect2(22, 39, 303, 49))
	var submit := func(value: String):
		if not money_authorized:
			if value == "MONEY":
				money_authorized = true
				_draw_page.call_deferred()
		elif value.is_valid_int() and int(value) >= 0 and int(value) <= Gear.MAX_COINS:
			var previous: int = game.campaign.coins
			game.campaign.coins = int(value)
			if game._save() == OK:
				money_authorized = false
				_open.call_deferred("")
			else:
				game.campaign.coins = previous
	entry.text_submitted.connect(submit)
	_button(panel, "Confirm", Rect2(340, 39, 108, 49), func(): submit.call(entry.text), true)
	entry.grab_focus()

func _draw_gear(gear: Button) -> void:
	var center := gear.size * 0.5
	var tint := GREEN if gear.is_hovered() else PAPER
	for i in 8:
		var ray := Vector2.from_angle(i * TAU / 8.0)
		gear.draw_line(center + ray * 8.0, center + ray * 11.5, tint, 3.0, true)
	gear.draw_circle(center, 8.0, tint, false, 2.0, true)
	gear.draw_circle(center, 3.2, tint, false, 1.6, true)

func _open(next: String) -> void:
	if next != "money":
		money_clicks = 0
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
	_button(panel, exit_label, Rect2(28, 462, 193, 46), game.save_and_quit)
	_button(panel, "Clear save", Rect2(235, 462, 220, 46), _open.bind("reset"))
	_button(panel, "Done", Rect2(475, 462, 205, 46), back, true)
	_show_save_notice(panel, Rect2(28, 419, 650, 32))
	selected_language.grab_focus()

func _reset() -> void:
	var panel := _modal("Clear save", Rect2(248, 201, 656, 246))
	_label(panel, "Erase sector records, stars, coins and purchased equipment?", Rect2(28, 79, 596, 60), 18, AMBER, false, true)
	var cancel := _button(panel, "Cancel", Rect2(28, 157, 280, 52), _open.bind("settings"), true)
	_button(panel, "Erase progress", Rect2(335, 157, 289, 52), func(): game.reset_progress(); _open("settings"))
	cancel.grab_focus()

func show_save_error() -> void:
	game.save_error = true
	_draw_page.call_deferred()

func _show_save_notice(parent: Control, at: Rect2) -> void:
	if game.save_error:
		_label(parent, "Could not save. Try again before closing.", at, 13, AMBER)

func _map() -> void:
	var panel := _modal("Sector map", Rect2(49, 38, 1054, 572))
	_back_arrow(panel, Rect2(982, 24, 44, 42), back)
	var cleared: int = game.campaign.records.size()
	if map_region < 0:
		map_region = mini(Levels.REGIONS.size() - 1, cleared / 6)
	var tint: Color = Levels.TINTS[map_region]
	var offset := map_region * 6
	if map_focus < 0:
		map_focus = clampi(cleared, offset, offset + 5)
	for i in Levels.REGIONS.size():
		var y := 89.0 + i * 53.0
		var tab := _button(panel, "", Rect2(27, y, 216, 45), _select_region.bind(i), false, map_region == i)
		var shade: Color = Levels.TINTS[i] if cleared >= i * 6 else DIM
		_label(tab, "%02d" % (i + 1), Rect2(12, 3, 32, 39), 12, shade)
		_label(tab, Levels.REGIONS[i], Rect2(50, 2, 155, 41), 15, PAPER if cleared >= i * 6 else DIM, true)

	var map := _panel(panel, Rect2(265, 85, 761, 325), Color("#13202b"), tint.darkened(0.61))
	map.clip_contents = true
	if painted_region >= 0 and painted_region != map_region and not game.reduced_motion and not game.save_path.is_empty():
		map.modulate.a = 0.15
		map.create_tween().tween_property(map, "modulate:a", 1.0, 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	painted_region = map_region
	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://assets/gate-overlook.webp")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(tint.lightened(0.48), 0.23)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(backdrop, map, Rect2(0, 0, 761, 325))
	_label(map, Levels.REGIONS[map_region], Rect2(27, 12, 550, 44), 28, tint, true)
	_label(map, _t("%d of %d sectors cleared") % [cleared, Levels.TABLE.size()], Rect2(542, 15, 200, 40), 13, DIM)
	var points := [Vector2(139, 111), Vector2(375, 109), Vector2(614, 121), Vector2(614, 239), Vector2(375, 248), Vector2(139, 225)]
	map.draw.connect(func():
		for i in range(5):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			map.draw_line(a, b, tint.darkened(0.55) if cleared > offset + i else LINE, 3.0, true)
	)
	var focused: Button
	for i in range(6):
		var index := offset + i
		var point: Vector2 = points[i]
		var done := index < cleared
		var available := index <= cleared
		var tile := _button(map, "", Rect2(point - Vector2(91, 35), Vector2(182, 71)), _focus_sector.bind(index), false, map_focus == index)
		tile.disabled = not available
		var ink := tint if available else DIM.darkened(0.13)
		_label(tile, "%02d" % (index + 1), Rect2(12, 4, 41, 27), 13, ink)
		_label(tile, Levels.TABLE[index][0], Rect2(12, 30, 160, 33), 15, PAPER if available else DIM, true, true).max_lines_visible = 2
		if done:
			for star_index in 3:
				_star(tile, Vector2(47 + star_index * 14, 17), 5.2, tint if star_index < game.campaign.records[index].stars else LINE)
		if map_focus == index and available:
			focused = tile
	var detail := _panel(panel, Rect2(265, 426, 761, 117), Color("#202f3b"))
	var selected: Array = Levels.TABLE[map_focus]
	_label(detail, selected[0], Rect2(19, 6, 463, 41), 25, tint, true)
	_label(detail, Levels.GOALS[selected[2]], Rect2(19, 47, 490, 54), 15, PAPER, false, true)
	var go := _button(detail, "Start sector" if map_focus <= cleared else "Locked", Rect2(521, 37, 216, 48), prepare_sector.bind(map_focus), map_focus <= cleared)
	go.disabled = map_focus > cleared
	_show_save_notice(panel, Rect2(272, 543, 718, 24))
	if focused != null:
		focused.grab_focus()

func _select_region(region: int) -> void:
	map_region = region
	map_focus = -1
	_draw_page.call_deferred()

func _focus_sector(index: int) -> void:
	if map_focus == index:
		prepare_sector(index)
	else:
		map_focus = index
		_draw_page.call_deferred()

func prepare_sector(index: int) -> void:
	if not game.campaign.selectable(index, Levels.TABLE.size()):
		return
	_open_shop(index)

func _open_shop(index: int) -> void:
	sector_pending = index
	gear_page = 0
	_open("shop")

func _shop() -> void:
	var panel := _modal("Equipment shop", Rect2(91, 40, 970, 568))
	var reserved: Array = game.campaign.reserved
	var stock := Gear.stock(game.campaign.records.size(), true)
	var count := ceili(stock.size() / 6.0)
	var heading := _t("Equip up to 3 items for the next attempt.")
	if sector_pending >= 0:
		heading = "%02d / %s   ·   %s" % [sector_pending + 1, _t(Levels.TABLE[sector_pending][0]), _t("Equip up to 3 items for the next attempt.")]
	_label(panel, heading, Rect2(28, 69, 907, 41), 16, DIM, false, true)
	_label(panel, _t("%d coins  ·  %d / 3 equipped") % [game.campaign.coins, reserved.size()], Rect2(514, 23, 286, 44), 15, AMBER)
	for i in Gear.MAX_LOADOUT:
		var at := Rect2(807 + i * 45, 21, 40, 43)
		if i < reserved.size():
			_gear_badge(panel, at, reserved[i], true)
		else:
			var empty := _panel(panel, at, INK)
			_label(empty, "+", Rect2(14, 7, 14, 27), 15, DIM)
	for i in range(gear_page * 6, mini(gear_page * 6 + 6, stock.size())):
		var id := stock[i]
		var item: Array = Gear.ITEMS[id]
		var slot := i % 6
		var at := Rect2(28 + slot % 2 * 464, 120 + (slot / 2) * 110, 447, 101)
		var card := _panel(panel, at, INK, GREEN.darkened(0.45) if id in reserved else LINE)
		_gear_badge(card, Rect2(12, 24, 50, 50), id)
		_label(card, item[0], Rect2(73, 6, 211, 36), 20, PAPER, true)
		_label(card, item[1], Rect2(73, 42, 207, 31), 13, DIM, false, true)
		_label(card, _t("Effect lasts %d seconds") % int(item[2]), Rect2(73, 73, 215, 22), 12, game.equipment_color(id))
		var buy := _button(card, "Equipped" if id in reserved else str(item[3]), Rect2(297, 26, 136, 47), _buy.bind(id))
		buy.tooltip_text = _t("Buy for next attempt")
		buy.disabled = id in reserved or reserved.size() >= Gear.MAX_LOADOUT or game.campaign.coins < item[3]
	var prior := _button(panel, "‹", Rect2(28, 475, 44, 45), _shop_page.bind(-1))
	var more := _button(panel, "›", Rect2(123, 475, 44, 45), _shop_page.bind(1))
	prior.disabled = gear_page == 0
	more.disabled = gear_page >= count - 1
	_label(panel, "%d/%d" % [gear_page + 1, count], Rect2(78, 476, 43, 42), 15, DIM)
	_back_arrow(panel, Rect2(193, 475, 51, 45), back, "Back")
	if sector_pending >= 0:
		var start := _button(panel, "Start without equipment" if reserved.is_empty() else "Start sector", Rect2(592, 474, 350, 48), _start_selected, true)
		start.grab_focus()
	else:
		_button(panel, "Equipment index", Rect2(642, 474, 300, 48), _open_archive.bind(1), true)
	if game.save_error:
		_show_save_notice(panel, Rect2(28, 525, 910, 28))
	else:
		_label(panel, "Equipment timers start when the fight begins.", Rect2(29, 521, 610, 26), 13, DIM)
		if sector_pending >= 0:
			var level: Array = Levels.TABLE[sector_pending]
			_label(panel, "%s   /   %s" % [_t("Time ≤ %ds") % int(level[5]), _t("Hits ≤ %d") % (1 if level[2] == "boss" else 0)], Rect2(660, 521, 283, 29), 13, AMBER)

func _gear_badge(parent: Control, at: Rect2, id: int, interactive := false) -> void:
	var tint: Color = game.equipment_color(id)
	var badge := _panel(parent, at, Color("#14202c"), tint.darkened(0.43))
	badge.draw.connect(func():
		var c := badge.size * 0.5
		var r := at.size.x * 0.38
		var plane := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, -r * 0.45), c + Vector2(r, r * 0.45), c + Vector2(0, r), c + Vector2(-r, r * 0.45), c + Vector2(-r, -r * 0.45)])
		badge.draw_colored_polygon(plane, tint.darkened(0.79))
		badge.draw_line(plane[0], plane[1], Color(tint, 0.48), 1.1, true)
		badge.draw_line(plane[5], plane[0], Color(tint, 0.34), 1.1, true)
		Icons.paint(badge, c + Vector2(0, 1.15), at.size.x / 31.0, Color("#08131f"), id)
		Icons.paint(badge, c, at.size.x / 31.0, tint.lerp(PAPER, 0.22), id)
	)
	if interactive:
		badge.mouse_filter = Control.MOUSE_FILTER_PASS
		badge.tooltip_text = _t(Gear.ITEMS[id][0])

func _shop_page(direction: int) -> void:
	gear_page += direction
	_draw_page.call_deferred()

func _buy(id: int) -> void:
	game.buy_gear(id)
	_draw_page.call_deferred()

func _start_selected() -> void:
	lesson_pending.clear()
	for id in Levels.lessons_at(sector_pending):
		if id not in game.campaign.lessons:
			lesson_pending.append(id)
	_next_context_lesson()

func _next_context_lesson() -> void:
	if lesson_pending.is_empty():
		game.begin_sector(sector_pending)
	else:
		active_lesson = lesson_pending.pop_front()
		_open("new_lesson")

func _open_archive(tab: int) -> void:
	dossier = tab
	gear_page = 0
	_open("archive")

func _archive() -> void:
	var panel := _modal("Field archive", Rect2(62, 38, 1028, 572))
	_button(panel, "Controls guide", Rect2(28, 77, 212, 44), _open.bind("guide"))
	_button(panel, "Mechanics", Rect2(256, 77, 212, 44), _open_archive.bind(0), false, dossier == 0)
	_button(panel, "Equipment index", Rect2(483, 77, 240, 44), _open_archive.bind(1), false, dossier == 1)
	_back_arrow(panel, Rect2(950, 27, 48, 42), back)
	var total := Levels.LESSONS.size() if dossier == 0 else Gear.ITEMS.size()
	var progress: int = game.campaign.records.size()
	for i in range(gear_page * 8, mini(total, (gear_page + 1) * 8)):
		var slot := i % 8
		var at := Rect2(28 + slot % 2 * 489, 145 + (slot / 2) * 82, 474, 75)
		if dossier == 0:
			var known := Levels.unlocked_lesson(i, progress)
			var tile := _button(panel, Levels.LESSONS[i][0] if known else "???", at, _replay_context.bind(i))
			tile.disabled = not known
		else:
			var item: Array = Gear.ITEMS[i]
			var known: bool = progress >= item[4]
			var card := _panel(panel, at, INK)
			if known:
				_gear_badge(card, Rect2(12, 12, 48, 48), i)
			_label(card, item[0] if known else "???", Rect2(74, 4, 390, 30), 17, game.equipment_color(i) if known else DIM, true)
			if known:
				_label(card, "%s  ·  %s  ·  %s" % [_t(item[1]), _t("Effect lasts %d seconds") % item[2], str(item[3]) if item[3] > 0 else _t("Drop only")], Rect2(74, 34, 383, 36), 13, DIM, false, true)
	_button(panel, "Previous", Rect2(28, 498, 185, 43), _archive_page.bind(-1)).disabled = gear_page == 0
	_button(panel, "Next", Rect2(813, 498, 185, 43), _archive_page.bind(1)).disabled = (gear_page + 1) * 8 >= total

func _archive_page(direction: int) -> void:
	gear_page += direction
	_draw_page.call_deferred()

func _replay_context(id: int) -> void:
	sector_pending = -1
	active_lesson = id
	_open("new_lesson")

func _new_lesson() -> void:
	var panel := _modal(Levels.LESSONS[active_lesson][0], Rect2(62, 38, 1028, 572))
	_panel(panel, Rect2(28, 117, 604, 273), INK)
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(preview, panel, Rect2(29, 118, 602, 271))
	_label(panel, Levels.LESSONS[active_lesson][1], Rect2(659, 120, 335, 210), 17, PAPER, false, true)
	if active_lesson < 11:
		_label(panel, "Pad: A jump · X strike · B dodge · RB swap · Y rule", Rect2(659, 339, 335, 77), 13, DIM, false, true)
	demo_toggle = _button(panel, "Pause demo", Rect2(29, 407, 218, 45), _toggle_demo)
	_demo_transport(panel, 407.0)
	_label(panel, "Gameplay recording", Rect2(29, 466, 370, 33), 13, DIM)
	next_step_button = _button(panel, "Continue" if sector_pending >= 0 else "Back", Rect2(714, 490, 281, 48), _acknowledge_lesson, true)
	_prepare_preview("context-%02d" % active_lesson, panel, 389)
	next_step_button.disabled = sector_pending >= 0 and is_playing
	if next_step_button.disabled:
		demo_toggle.grab_focus()
	else:
		next_step_button.grab_focus()

func _acknowledge_lesson() -> void:
	if sector_pending < 0:
		_open("archive")
		return
	if active_lesson not in game.campaign.lessons:
		game.campaign.lessons.append(active_lesson)
		game._save()
	_next_context_lesson()

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
		_back_arrow(panel, Rect2(28, 239, 51, 44), game.return_to_lobby)
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
		if game.mission_sector:
			_campaign_result(title, text_line, score)
			return
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
		_back_arrow(panel, Rect2(343, 202, 56, 52), game.return_to_lobby)
	proceed.grab_focus()

func _campaign_result(title: String, summary: String, score: Dictionary) -> void:
	# Replace the small arcade result with the campaign report.
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	var panel := _modal(title, Rect2(200, 135, 752, 378))
	_label(panel, "%02d / %s" % [game.sector_index + 1, _t(Levels.TABLE[game.sector_index][0])], Rect2(29, 72, 690, 32), 16, DIM)
	var score_tray := _panel(panel, Rect2(29, 117, 694, 98), INK, AMBER.darkened(0.54))
	for i in 3:
		var rank := Control.new()
		rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(rank, score_tray, Rect2(24 + i * 51, 29, 40, 40))
		_star(rank, Vector2(20, 20), 19.0, AMBER if i < score.get("stars", 1) else LINE)
		if opening_page and i < score.get("stars", 1) and not game.reduced_motion and not game.save_path.is_empty():
			rank.modulate.a = 0.13
			rank.pivot_offset = Vector2(20, 20)
			rank.scale = Vector2(0.70, 0.70)
			var award := rank.create_tween().set_parallel(true)
			award.tween_property(rank, "modulate:a", 1.0, 0.20).set_delay(0.17 + i * 0.09)
			award.tween_property(rank, "scale", Vector2.ONE, 0.25).set_delay(0.17 + i * 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_label(panel, _t("+%d coins") % score.get("coins", 0), Rect2(259, 129, 450, 48), 27, AMBER, true)
	_label(panel, summary, Rect2(259, 175, 450, 33), 14, DIM)
	var clock_target: float = Levels.TABLE[game.sector_index][5]
	var hit_target := 1 if Levels.TABLE[game.sector_index][2] == "boss" else 0
	_label(panel, _t("Time ≤ %ds") % int(clock_target), Rect2(29, 225, 330, 34), 15, GREEN if score.get("fast") else DIM)
	_label(panel, _t("Hits ≤ %d") % hit_target, Rect2(383, 225, 330, 34), 15, GREEN if score.get("clean") else DIM)
	_show_save_notice(panel, Rect2(29, 266, 690, 33))
	_button(panel, "Retry", Rect2(29, 307, 185, 48), _retry_from_results)
	_back_arrow(panel, Rect2(229, 307, 56, 48), game.return_to_lobby)
	var last: bool = game.sector_index == Levels.TABLE.size() - 1
	var next := _button(panel, "Sector map" if last else "Next sector", Rect2(431, 307, 292, 48), game.continue_after_clear, true)
	next.grab_focus()

func _star(parent: Control, center: Vector2, radius: float, color: Color) -> void:
	parent.draw.connect(func():
		var points := PackedVector2Array()
		for i in 10:
			points.append(center + Vector2.from_angle(-PI / 2.0 + i * TAU / 10.0) * radius * (1.0 if i % 2 == 0 else 0.46))
		parent.draw_colored_polygon(points, color)
	)

func _retry_from_results() -> void:
	game.return_to_lobby("map")
	prepare_sector(game.sector_index)

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
	_demo_transport(panel, 433.0)
	_button(panel, "Try it", Rect2(659, 433, 337, 43), game.begin_practice.bind(chapter, "guide"))
	_panel(panel, Rect2(28, 490, 969, 1), LINE, LINE)
	if chapter > 0:
		_button(panel, "Previous", Rect2(28, 509, 198, 44), _choose_demo.bind(chapter - 1))
	if not onboarding:
		_button(panel, "Field archive", Rect2(239 if chapter > 0 else 28, 509, 235, 44), _open_archive.bind(0))
	var last := chapter == DEMOS.size() - 1
	next_step_button = _button(panel, ("Enter lobby" if onboarding else "Done") if last else "Next lesson", Rect2(756, 508, 240, 46), _next_lesson, true)
	next_step_button.disabled = onboarding and not lesson_watched.has(chapter) and not game.reduced_motion
	_prepare_preview(demo[0], panel, 419)
	if next_step_button.disabled:
		demo_toggle.grab_focus()
	else:
		next_step_button.grab_focus()

func _prepare_preview(filename: String, panel: Panel, bar_y: float) -> void:
	demo_rate = 1.0
	demo_progress = ProgressBar.new()
	demo_progress.show_percentage = false
	demo_progress.max_value = FRAME_COUNT - 1
	demo_progress.add_theme_stylebox_override("background", _style(INK, INK, 0))
	demo_progress.add_theme_stylebox_override("fill", _style(GREEN, GREEN, 0))
	demo_progress.mouse_filter = Control.MOUSE_FILTER_STOP
	demo_progress.tooltip_text = _t("Seek in recording")
	demo_progress.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_seek_demo(demo_duration() * clampf(event.position.x / demo_progress.size.x, 0.0, 1.0))
	)
	_place(demo_progress, panel, Rect2(29, bar_y - 3.0, 602, 7))
	demo_texture = AtlasTexture.new()
	demo_texture.filter_clip = true
	preview.texture = demo_texture
	for i in range(ceili(float(FRAME_COUNT) / FRAMES_PER_SHEET)):
		var path := "res://assets/demos/%s-%s.webp" % [filename, i]
		if ResourceLoader.exists(path):
			demo_sheets.append(load(path))
	if demo_sheets.size() != ceili(float(FRAME_COUNT) / FRAMES_PER_SHEET):
		_label(panel, "Demo unavailable", Rect2(58, 252, 525, 38), 17, DIM)
		is_playing = false
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
	if not is_playing and demo_time >= demo_duration():
		demo_time = 0.0
		_show_frame()
	is_playing = not is_playing
	demo_toggle.text = _t("Pause demo" if is_playing else "Play")
	set_process(is_playing)

func _process(delta: float) -> void:
	demo_time = minf(demo_time + delta * demo_rate, demo_duration())
	_show_frame()
	if demo_time >= demo_duration():
		is_playing = false
		set_process(false)
		demo_toggle.text = _t("Replay demo")
		_mark_lesson_watched()

func _mark_lesson_watched() -> void:
	if page != "new_lesson":
		lesson_watched[chapter] = true
	next_step_button.disabled = false
	if onboarding and get_viewport().gui_get_focus_owner() == demo_toggle:
		next_step_button.grab_focus()

func _show_frame() -> void:
	if demo_sheets.is_empty() or demo_texture == null:
		return
	var frame := mini(FRAME_COUNT - 1, int(demo_time / demo_duration() * FRAME_COUNT))
	if frame == demo_frame:
		return
	var local := frame % FRAMES_PER_SHEET
	var sheet := demo_sheets[frame / FRAMES_PER_SHEET]
	if demo_texture.atlas != sheet:
		demo_texture.atlas = sheet
	demo_texture.region = Rect2(Vector2i(local % 3, local / 3) * FRAME_SIZE, FRAME_SIZE)
	demo_frame = frame
	demo_progress.value = frame

func demo_duration() -> float:
	return 8.0 if page == "new_lesson" else 6.0

func _demo_transport(panel: Panel, y: float) -> void:
	var rewind := _button(panel, "−1s", Rect2(265, y, 65, 44), func(): _seek_demo(demo_time - 1.0))
	rewind.tooltip_text = _t("Back one second")
	var forward := _button(panel, "+1s", Rect2(340, y, 65, 44), func(): _seek_demo(demo_time + 1.0))
	forward.tooltip_text = _t("Forward one second")
	demo_speed = _button(panel, "1×", Rect2(418, y, 88, 44), _change_demo_rate)
	demo_speed.tooltip_text = _t("Playback speed")

func _change_demo_rate() -> void:
	demo_rate = 0.5 if demo_rate == 1.0 else 1.0
	demo_speed.text = "0.5×" if demo_rate == 0.5 else "1×"

func _seek_demo(at: float) -> void:
	if demo_sheets.size() != FRAME_COUNT / FRAMES_PER_SHEET:
		return
	demo_time = clampf(at, 0.0, demo_duration())
	is_playing = false
	set_process(false)
	demo_toggle.text = _t("Play")
	_show_frame()

func play_arena_reveal() -> void:
	if game.reduced_motion or game.save_path.is_empty():
		return
	var screen := CanvasLayer.new()
	screen.layer = 6
	add_child(screen)
	var cover := ColorRect.new()
	cover.color = Color("#172334c7")
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.size = Vector2(1152, 648)
	screen.add_child(cover)
	var reveal := screen.create_tween()
	reveal.tween_property(cover, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reveal.tween_callback(screen.queue_free)

func back() -> void:
	if page == "language":
		return
	if onboarding and page == "guide":
		if chapter > 0:
			_choose_demo(chapter - 1)
		return
	if page == "new_lesson":
		if sector_pending >= 0:
			_open("shop")
		else:
			_open("archive")
		return
	if page == "shop" and sector_pending >= 0:
		_open("map")
		return
	if page == "reset":
		_open("settings")
		return
	chapter = 0
	_open("")
