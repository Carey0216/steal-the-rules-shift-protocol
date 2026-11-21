extends CanvasLayer

const Locale = preload("res://src/locale.gd")
const Levels = preload("res://src/levels.gd")
const Gear = preload("res://src/gear.gd")
const Icons = preload("res://src/equipment_icons.gd")
const MetalSkin = preload("res://src/ui_skin.gd")
const MotionButton = preload("res://src/motion_button.gd")
const INK := Color("#0c2028")
const PANEL := Color("#172e36")
const LINE := Color("#48646b")
const PAPER := Color("#f6edda")
const DIM := Color("#bdc3c5")
const GREEN := Color("#a2ddd3")
const AMBER := Color("#dcb777")
const DANGER := Color("#ffa993")
const SCALES := [1.0, 1.15, 1.3]
const SIZES := [Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900)]
const DEMOS := [
	["move", "Move & jump", "A/D + SPACE", "STICK + A", "Move toward the boss. When a warning hugs the floor, jump as the attack approaches. Land close enough to counter."],
	["strike", "Strike", "J", "X", "Face the boss and move within blade reach. Hold the strike button to keep swinging. The open core takes more damage."],
	["dodge", "Dodge", "K", "B", "Dodge through the charge as it reaches you. The outline shows protection. Wait for the dodge bar to refill."],
	["steal", "Steal a rule", "SHIFT", "RB", "RUSH exchanges positions. LIFT grounds the boss. AEGIS breaks its armor."],
	["rule", "Use your rule", "E", "Y", "Face the boss and press E when the rule is ready. RUSH cuts forward, LIFT lifts you, and AEGIS reflects a nearby hit."],
]
const LESSON_KEYS := [
	["A / D", "SPACE"], ["J", "K"], ["A / D", "SPACE"], ["SHIFT", "E"], ["SHIFT", "E"],
	["SHIFT"], ["K", "SPACE"], ["J"], ["J"], ["A / D"],
	["J", "SPACE"], [], [], [], ["SPACE"], ["J"], ["SHIFT", "E"], ["K", "SPACE"], ["A / D"], ["K"],
	["SHIFT", "SPACE"], ["SHIFT"], ["K", "J"], ["K", "SHIFT", "J"],
]
const PAD_KEYS := {"A / D": "STICK", "SPACE": "A", "J": "X", "K": "B", "SHIFT": "RB", "E": "Y"}
const FRAME_SIZE := Vector2i(640, 360)
const GUIDE_FRAME := Rect2(48, 135, 704, 396)
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
var practice_demo_time := -1.0
var mission_return := ""
var shop_return := ""
var archive_return := ""
var arena_reveal: CanvasLayer
var settings_tab := 0
var binding_index := -1
var binding_note := ""
var focus_memory := {}
var purchased_id := -1
var page_animation: Tween

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
		emblem.pivot_offset = Vector2(50, 50)
		emblem.rotation = -0.22
		emblem.scale = Vector2(0.78, 0.78)
		var stamp := emblem.create_tween().set_parallel()
		stamp.tween_property(emblem, "rotation", 0.0, 0.49).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		stamp.tween_property(emblem, "scale", Vector2.ONE, 0.49).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		cover.draw.connect(func():
			for radius in [81, 90, 127]:
				cover.draw_arc(Vector2(576, 206), radius, -2.8, 2.8, 60, Color(AMBER, 0.22), 1.0, true)
		)
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

func capture_binding(event: InputEvent) -> bool:
	if binding_index < 0:
		return false
	if not event is InputEventKey or not event.pressed or event.echo:
		return true
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not game.controls.rebind(binding_index, key):
		binding_note = "This key is reserved. Choose another."
	else:
		binding_index = -1
		binding_note = ""
		game._save()
	_draw_page.call_deferred()
	return true

func _style(fill: Color, border: Color, width := 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(3)
	box.corner_detail = 3
	return box

func _place(node: Control, parent: Control, at: Rect2) -> void:
	parent.add_child(node)
	node.position = at.position
	node.size = at.size

func _label(parent: Control, key: String, at: Rect2, size: int, shade := PAPER, large := false, wrap := false) -> Label:
	var label := Label.new()
	label.text = _t(key)
	var font := Locale.face(Locale.current(), large)
	var scaled_size := _text_size(size)
	label.add_theme_font_override("font", font)
	if wrap and at.size.x > 0.0 and at.size.y > 0.0:
		while scaled_size > 12 and font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, at.size.x, scaled_size).y > at.size.y:
			scaled_size -= 1
	if not wrap and at.size.x > 0:
		var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled_size).x
		if width > at.size.x:
			scaled_size = maxi(size, floori(scaled_size * at.size.x / width))
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", scaled_size)
	label.add_theme_color_override("font_color", shade)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if Locale.current() in [1, 2, 3]:
			for mark in ["。", "、", "，", "；", "！", "？"]:
				label.text = label.text.replace(mark, "\u2060" + mark)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(label, parent, at)
	return label

func _panel(parent: Control, at: Rect2, fill: Color, border := LINE) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, border))
	_place(panel, parent, at)
	return panel

func _button(parent: Control, key: String, at: Rect2, callback: Callable, primary := false, selected := false, danger := false) -> Button:
	var button := MotionButton.new()
	button.motion = not game.reduced_motion
	button.gold = primary
	button.text = _t(key)
	button.clip_text = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", Locale.face(Locale.current()))
	var font := button.get_theme_font("font")
	var size := _text_size(16)
	var text_width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if text_width > at.size.x - 24.0:
		size = maxi(14, floori(size * (at.size.x - 24.0) / text_width))
	button.add_theme_font_size_override("font_size", size)
	var text_color := INK if primary else (DANGER if danger else PAPER)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color("#8d969b"))
	var surface := AMBER if primary else (Color("#31515a") if selected else Color("#1b3540"))
	var edge := AMBER if selected or primary else (DANGER.darkened(0.44) if danger else LINE)
	var normal := _button_skin(surface, edge, primary)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _button_skin(surface.lightened(0.09), AMBER, primary, true))
	button.add_theme_stylebox_override("pressed", _button_skin(surface.darkened(0.12), PAPER, primary, true))
	var disabled_skin := _button_skin(INK, LINE.darkened(0.25))
	disabled_skin.disabled = true
	button.add_theme_stylebox_override("disabled", disabled_skin)
	var focus := _button_skin(Color.TRANSPARENT, PAPER, false, true)
	focus.focus_only = true
	button.add_theme_stylebox_override("focus", focus)
	# Compact lesson selectors still need room for their number at every text scale.
	if at.size.x < 60:
		for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			var compact := button.get_theme_stylebox(state_name).duplicate()
			compact.content_margin_left = 3.0
			compact.content_margin_right = 3.0
			compact.content_margin_top = 1.0
			compact.content_margin_bottom = 1.0
			button.add_theme_stylebox_override(state_name, compact)
	button.pressed.connect(func():
		game.audio_rig.fire("ui_confirm")
		callback.call()
	)
	button.focus_entered.connect(func(): game.audio_rig.fire("ui_focus"))
	_place(button, parent, at)
	return button

func _button_skin(fill: Color, border: Color, primary := false, lit := false) -> StyleBox:
	var skin := MetalSkin.new()
	skin.fill = fill
	skin.edge = border
	skin.primary = primary
	skin.lit = lit
	skin.content_margin_left = 15
	skin.content_margin_right = 26 if primary else 15
	return skin

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
	var panel := _panel(ui, at, PANEL, LINE)
	panel.add_theme_stylebox_override("panel", _button_skin(PANEL, LINE))
	_label(panel, title, Rect2(28, 19, at.size.x - 104, 52), 33, AMBER, true)
	_panel(panel, Rect2(28, 72, at.size.x - 56, 1), LINE, LINE)
	if opening_page and not game.reduced_motion and not game.save_path.is_empty():
		dim.modulate.a = 0.0
		panel.modulate.a = 0.0
		panel.position.y += 14.0
		var entrance := panel.create_tween().set_parallel(true)
		entrance.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		entrance.tween_property(dim, "modulate:a", 1.0, 0.18)
		entrance.tween_property(panel, "modulate:a", 1.0, 0.19)
		entrance.tween_property(panel, "position:y", at.position.y, 0.25)
	return panel

func _screen(heading: String, tone := AMBER, shade := 0.86) -> Control:
	var screen := Control.new()
	_place(screen, ui, Rect2(0, 0, 1152, 648))
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	var cover := ColorRect.new()
	cover.color = Color(Color("#0c2029"), maxf(0.96, shade))
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(cover, screen, Rect2(0, 0, 1152, 648))
	var crown := ColorRect.new()
	crown.color = Color("#081a24")
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(crown, screen, Rect2(0, 0, 1152, 104))
	screen.draw.connect(func():
		var center := Vector2(1044, 354)
		for radius in [150, 177, 235, 280, 305]:
			screen.draw_arc(center, radius, -2.8, 1.2, 60, Color(tone, 0.045), 1.0, true)
		for ray in 18:
			var direction := Vector2.from_angle(ray * TAU / 18)
			screen.draw_line(center + direction * 272, center + direction * 280, Color(tone, 0.09), 1.0, true)
	)
	var line := ColorRect.new()
	line.color = Color(tone, 0.46)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(line, screen, Rect2(48, 103, 1056, 1))
	_panel(screen, Rect2(48, 103, 80, 2), tone, tone)
	_label(screen, heading, Rect2(113, 28, 655, 62), 35, AMBER, true)
	if opening_page and not game.reduced_motion and not game.save_path.is_empty():
		screen.modulate.a = 0.68
		screen.position.x = 13.0
		var enter := screen.create_tween().set_parallel()
		enter.tween_property(screen, "modulate:a", 1.0, 0.17)
		enter.tween_property(screen, "position:x", 0.0, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return screen

func _text_action(parent: Control, text: String, at: Rect2, action: Callable, enabled := true) -> Button:
	var button := _button(parent, text, at, action)
	button.add_theme_stylebox_override("normal", _style(Color.TRANSPARENT, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("hover", _style(Color("#2b3847"), Color("#596878")))
	button.disabled = not enabled
	return button

func _draw_page() -> void:
	set_process(false)
	if is_instance_valid(page_animation):
		page_animation.kill()
		page_animation = null
	ui.modulate = Color.WHITE
	ui.position = Vector2.ZERO
	var view: String = game.mode + ":" + page
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and focused is Button and is_ancestor_of(focused):
		focus_memory[last_view] = focused.text
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
		"protocol": _protocol()
		"language": _language()
		"settings": _settings()
		"guide": _guide()
		"map": _map()
		"mission": _mission()
		"shop": _shop()
		"archive": _archive()
		"new_lesson": _new_lesson()
		"reset": _reset()
		"money": _money()
		_: _title_controls()
	if page != "money" and focus_memory.has(view):
		_restore_focus.call_deferred(ui, focus_memory[view])

func _restore_focus(parent: Node, text: String) -> void:
	if not is_instance_valid(parent):
		return
	for child in parent.get_children():
		if child is Button and child.text == text and not child.disabled and not text.is_empty():
			child.grab_focus()
			return
		_restore_focus(child, text)

func _title_controls() -> void:
	var cleared: int = game.campaign.records.size()
	var frontier := mini(cleared, Levels.TABLE.size() - 1)
	var level: Array = Levels.TABLE[frontier]
	var in_campaign := cleared < Levels.TABLE.size()
	var action := "Start operation" if cleared == 0 else "Continue operation"
	var play := _button(ui, "Protocol run", Rect2(64, 272, 264, 52), _open.bind("protocol"), true)
	_button(ui, action if in_campaign else "Sector map", Rect2(64, 336, 264, 45), _prepare_from_lobby.bind(frontier) if in_campaign else _open_map)
	if in_campaign:
		_button(ui, "Sector map", Rect2(64, 393, 264, 45), _open_map)
	_button(ui, "Equipment shop", Rect2(64, 450, 264, 45), _open_shop.bind(-1))
	_button(ui, "Field archive", Rect2(64, 507, 264, 45), _open_archive.bind(0))
	var dispatch := _panel(ui, Rect2(858, 227, 244, 309), Color("#0b202bea"), Color("#526c6e"))
	_label(dispatch, "Next sector", Rect2(19, 13, 206, 31), 14, AMBER)
	_label(dispatch, "%02d" % (frontier + 1), Rect2(19, 51, 206, 54), 40, GREEN, true)
	_label(dispatch, level[0], Rect2(19, 112, 206, 67), 25, PAPER, true, true)
	_label(dispatch, Levels.REGIONS[level[1]], Rect2(19, 197, 206, 43), 15, DIM, false, true)
	_label(dispatch, "Guardian intercept" if Levels.has_guardian(frontier) else ("Boss encounter" if level[2] == "boss" else "Checkpoint route"), Rect2(19, 250, 206, 46), 14, AMBER, false, true)
	play.grab_focus()
	var gear := _button(ui, "", Rect2(987, 25, 48, 44), _open.bind("settings"))
	gear.tooltip_text = _t("Settings")
	gear.draw.connect(_draw_gear.bind(gear))
	var help := _button(ui, "?", Rect2(1047, 25, 48, 44), _open_archive.bind(0))
	help.tooltip_text = _t("Controls guide")
	var wallet := _button(ui, "", Rect2(719, 25, 195, 44), _wallet_pressed)
	wallet.focus_mode = Control.FOCUS_NONE
	wallet.tooltip_text = _t("Coins")
	var balance := _label(wallet, str(game.campaign.coins), Rect2(51, 3, 123, 37), 17, AMBER)
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wallet.draw.connect(_currency_icon.bind(wallet, false))
	var shop := _button(ui, "", Rect2(925, 25, 48, 44), _open_shop.bind(-1))
	shop.tooltip_text = _t("Equipment shop")
	shop.draw.connect(_currency_icon.bind(shop, true))
	if game.save_recovered:
		_label(ui, "Backup save restored", Rect2(858, 541, 244, 26), 13, AMBER)

func _protocol() -> void:
	var panel := _modal("Protocol run", Rect2(184, 112, 784, 424))
	_label(panel, "Six bosses. One rule slot. Rewrite the system.", Rect2(30, 73, 724, 61), 27, PAPER, true, true)
	_label(panel, "Dodge the marked attack. Approach the open core. SHIFT takes its rule and gives it yours. E uses your stolen rule.", Rect2(30, 145, 724, 92), 18, DIM, false, true)
	_label(panel, "Each boss escalates through three protocols. Your rule carries forward; each clear repairs 3 hull. Retry the current boss freely.", Rect2(30, 245, 724, 73), 16, DIM, false, true)
	var start := _button(panel, "Begin protocol", Rect2(30, 340, 352, 53), _launch_protocol, true)
	_button(panel, "Field archive", Rect2(400, 340, 354, 53), _open_archive.bind(0))
	start.grab_focus()

func _launch_protocol() -> void:
	_open("")
	game._new_run()
	game.engage_sector()

func _open_map() -> void:
	map_region = -1
	painted_region = -1
	map_focus = -1
	_open("map")

func _prepare_from_lobby(index: int) -> void:
	_prepare_mission(index, "")

func _back_arrow(parent: Control, at: Rect2, callback: Callable, tip := "Return to lobby", right := false) -> Button:
	var button := _button(parent, "", at, callback)
	button.tooltip_text = _t(tip)
	button.draw.connect(func():
		var c := button.size / 2.0
		if button.size.x > 100:
			c.x = 25
		var tint := DIM.darkened(0.51) if button.disabled else (AMBER if button.is_hovered() or button.has_focus() else PAPER)
		var direction := -1.0 if right else 1.0
		button.draw_polyline(PackedVector2Array([c + Vector2(-direction, -8), c + Vector2(-9 * direction, 0), c + Vector2(-direction, 8)]), tint, 1.9, true)
		button.draw_line(c + Vector2(-8 * direction, 0), c + Vector2(10 * direction, 0), tint, 1.9, true)
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
	var previous := page
	page = next
	if game.save_path.is_empty() or game.reduced_motion or next == previous or game.mode != "title":
		_draw_page()
		return
	if is_instance_valid(page_animation):
		page_animation.kill()
	var blocker := Control.new()
	_place(blocker, ui, Rect2(0, 0, 1152, 648))
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	page_animation = create_tween()
	page_animation.tween_property(ui, "modulate:a", 0.0, 0.085).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	page_animation.tween_callback(func():
		page_animation = null
		_draw_page()
	)

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
	var screen := _screen("Settings", AMBER, 0.98)
	_back_arrow(screen, Rect2(48, 35, 44, 43), back, "Back")
	var tabs := ["Display and access", "Sound and feedback", "Keyboard controls"]
	for i in tabs.size():
		_button(screen, tabs[i], Rect2(48, 137 + i * 67, 252, 51), func(): settings_tab = i; binding_index = -1; _draw_page.call_deferred(), false, settings_tab == i)
	_panel(screen, Rect2(326, 135, 1, 384), LINE, LINE)
	if settings_tab == 0:
		var labels := ["Language", "Display mode", "Window size", "Text size", "Reduced motion", "Assist mode"]
		for i in labels.size():
			var y := 137.0 + i * 59
			_label(screen, labels[i], Rect2(354, y, 326, 43), 17)
			var at := Rect2(751, y, 353, 43)
			match i:
				0: _option(screen, Locale.NAMES, Locale.current(), at, _change_language)
				1:
					display_picker = _option(screen, ["Windowed", "Fullscreen"], int(game._display_is_fullscreen()), at, _change_display)
				2:
					_option(screen, ["1152 × 648", "1280 × 720", "1600 × 900"], game.window_size_index, at, _change_window_size).disabled = OS.has_feature("web") or game._display_is_fullscreen()
				3: _option(screen, ["100%", "115%", "130%"], game.text_size_index, at, _change_text_size)
				4: _option(screen, ["Off", "On"], int(game.reduced_motion), at, _change_motion)
				5: _option(screen, ["Off", "On"], int(game.assist), at, _change_assist)
	elif settings_tab == 1:
		var labels := ["Master volume", "Music volume", "Effects volume", "Screen shake"]
		var values := [game.master_volume, game.music_volume, game.effects_volume, game.shake_strength]
		for i in labels.size():
			var y := 145.0 + i * 83
			_label(screen, labels[i], Rect2(354, y, 314, 43), 18)
			var slider := HSlider.new()
			slider.min_value = 0.0
			slider.max_value = 100.0
			slider.step = 5
			slider.value = values[i] * 100
			slider.custom_minimum_size = Vector2(282, 30)
			var track := _style(LINE.darkened(0.35), LINE, 0)
			track.content_margin_top = 3
			track.content_margin_bottom = 3
			var fill := _style(GREEN, GREEN, 0)
			fill.content_margin_top = 3
			fill.content_margin_bottom = 3
			slider.add_theme_stylebox_override("slider", track)
			slider.add_theme_stylebox_override("grabber_area", fill)
			slider.add_theme_stylebox_override("grabber_area_highlight", fill)
			slider.add_theme_icon_override("grabber", preload("res://assets/slider-thumb.svg"))
			slider.add_theme_icon_override("grabber_highlight", preload("res://assets/slider-thumb.svg"))
			_place(slider, screen, Rect2(747, y + 9, 282, 30))
			var number := _label(screen, "%d%%" % int(values[i] * 100), Rect2(1043, y, 61, 43), 16, AMBER)
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			slider.value_changed.connect(func(value: float):
				number.text = "%d%%" % int(value)
				game.set(["master_volume", "music_volume", "effects_volume", "shake_strength"][i], value / 100.0)
				game.audio_rig.set_levels(game.master_volume, game.music_volume, game.effects_volume)
			)
			slider.drag_ended.connect(func(_changed: bool): game._save())
			slider.focus_exited.connect(func(): game._save())
	else:
		var entries: Array = game.Controls.ACTIONS
		for i in entries.size():
			var x := 354.0 + (i / 5) * 385
			var y := 135.0 + (i % 5) * 63
			_label(screen, game.Controls.TITLES[i], Rect2(x, y, 205, 44), 16)
			_button(screen, "Press a key" if binding_index == i else game.controls.label(entries[i]), Rect2(x + 207, y, 150, 44), func(): binding_index = i; _draw_page.call_deferred(), false, binding_index == i)
		_label(screen, binding_note if not binding_note.is_empty() else "One key per action. Assigning an occupied key swaps the bindings.", Rect2(354, 456, 360, 71), 13, DIM, false, true)
		_button(screen, "Restore controls", Rect2(739, 471, 365, 43), func(): game.controls.defaults(); game._save(); _draw_page.call_deferred())
	_panel(screen, Rect2(48, 544, 1056, 1), LINE, LINE)
	_button(screen, "Save and return" if OS.has_feature("web") else "Save and quit", Rect2(48, 566, 242, 49), game.save_and_quit)
	_button(screen, "Clear save", Rect2(354, 566, 212, 49), _open.bind("reset"), false, false, true)
	_button(screen, "Done", Rect2(860, 566, 244, 49), back, true)
	_show_save_notice(screen, Rect2(48, 510, 1056, 30))

func _reset() -> void:
	var panel := _modal("Clear save", Rect2(248, 201, 656, 246))
	_label(panel, "Erase sector records, stars, coins and purchased equipment?", Rect2(28, 79, 596, 60), 18, AMBER, false, true)
	var cancel := _button(panel, "Cancel", Rect2(28, 157, 280, 52), _open.bind("settings"), true)
	_button(panel, "Erase progress", Rect2(335, 157, 289, 52), func(): game.reset_progress(); _open("settings"), false, false, true)
	cancel.grab_focus()

func show_save_error() -> void:
	game.save_error = true
	_draw_page.call_deferred()

func _show_save_notice(parent: Control, at: Rect2) -> void:
	if game.save_error:
		_label(parent, "Could not save. Try again before closing.", at, 13, AMBER)

func _map() -> void:
	var cleared: int = game.campaign.records.size()
	if map_region < 0:
		map_region = mini(Levels.REGIONS.size() - 1, cleared / 6)
	var offset := map_region * 6
	var tint: Color = Levels.TINTS[map_region]
	if map_focus < 0:
		map_focus = clampi(cleared, offset, offset + 5)
	var screen := _screen("Sector map", tint)
	_back_arrow(screen, Rect2(48, 35, 44, 43), back)
	var tally := _label(screen, _t("%d of %d sectors cleared") % [cleared, Levels.TABLE.size()], Rect2(800, 36, 304, 32), 15, PAPER)
	tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for region in Levels.REGIONS.size():
		var length := clampf((cleared - region * 6) / 6.0, 0.0, 1.0)
		var x := 795.0 + region * 39.0
		_panel(screen, Rect2(x, 77, 36, 4), LINE, LINE)
		if length > 0.0:
			_panel(screen, Rect2(x, 77, 36 * length, 4), Levels.TINTS[region], Levels.TINTS[region])
	_label(screen, "Regions", Rect2(48, 123, 190, 30), 14, DIM)

	for i in Levels.REGIONS.size():
		var tab := _text_action(screen, "", Rect2(48, 159 + i * 49, 202, 43), _select_region.bind(i))
		var shade: Color = Levels.TINTS[i] if cleared >= i * 6 else DIM
		var selected := i == map_region
		if selected:
			tab.add_theme_stylebox_override("normal", _style(Color("#293a49"), Color(shade, 0.34)))
		_label(tab, "%02d" % (i + 1), Rect2(11, 3, 31, 37), 12, shade)
		_label(tab, Levels.REGIONS[i], Rect2(38, 3, 158, 37), 15, PAPER if selected else DIM, true)

	var field := _panel(screen, Rect2(272, 135, 535, 436), INK, Color(tint, 0.30))
	var points := [Vector2(71, 142), Vector2(265, 121), Vector2(454, 148), Vector2(445, 296), Vector2(251, 310), Vector2(75, 278)]
	field.draw.connect(func():
		var dark := Color(tint, 0.08)
		for i in 9:
			var x := 27.0 + 60.0 * i
			field.draw_line(Vector2(x, 80), Vector2(x, 400), dark, 1.0)
		for i in 6:
			var y := 82.0 + i * 62.0
			field.draw_line(Vector2(27, y), Vector2(507, y), dark, 1.0)
		for i in range(5):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var wire := tint if cleared > offset + i else LINE
			var corner := Vector2((a.x + b.x) / 2.0, a.y)
			var path := PackedVector2Array([a, corner, Vector2(corner.x, b.y), b])
			field.draw_polyline(path, Color(wire, 0.68), 2.0, true)
	)
	_label(field, Levels.REGIONS[map_region], Rect2(21, 17, 487, 50), 30, tint, true)
	if painted_region >= 0 and painted_region != map_region and not game.reduced_motion and not game.save_path.is_empty():
		field.modulate.a = 0.17
		field.create_tween().tween_property(field, "modulate:a", 1.0, 0.21).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	painted_region = map_region
	var focus: Button
	for i in 6:
		var index := offset + i
		var midpoint: Vector2 = points[i]
		var selected := map_focus == index
		var completed := index < cleared
		var tone := tint if index <= cleared else DIM.darkened(0.19)
		var node := _text_action(field, "", Rect2(midpoint - Vector2(74, 30), Vector2(148, 90)), _focus_sector.bind(index))
		node.add_theme_stylebox_override("hover", _style(Color.TRANSPARENT, Color.TRANSPARENT, 0))
		node.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color.TRANSPARENT, 0))
		node.tooltip_text = _t("Cleared" if completed else ("Next sector" if index == cleared else "Locked"))
		node.draw.connect(func():
			var inner := Vector2(74, 30)
			node.draw_circle(inner, 29.0, Color("#162431"), true, -1.0, true)
			node.draw_circle(inner, 26.0, tone if selected or node.is_hovered() else Color(tone, 0.38), false, 2.0, true)
			node.draw_circle(inner, 20.0, Color(tone, 0.22 if selected else 0.06), true, -1.0, true)
			if node.has_focus():
				node.draw_circle(inner, 32.0, AMBER, false, 1.3, true)
		)
		var number := _label(node, "%02d" % (index + 1), Rect2(48, 10, 52, 38), 16, tone)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var name := _label(node, Levels.TABLE[index][0], Rect2(4, 59, 140, 26), 13, PAPER if index <= cleared else DIM, true)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if completed:
			for star_index in 3:
				_star(node, Vector2(60 + star_index * 14, 91), 4.1, tone if star_index < game.campaign.records[index].stars else LINE)
		if selected:
			focus = node

	var selected_level: Array = Levels.TABLE[map_focus]
	var detail := _panel(screen, Rect2(828, 135, 276, 436), PANEL, Color(tint, 0.30))
	var status := "Cleared" if map_focus < cleared else ("Next sector" if map_focus == cleared else "Locked")
	_label(detail, status, Rect2(19, 14, 232, 38), 14, tint if map_focus <= cleared else DIM)
	_label(detail, selected_level[0], Rect2(19, 53, 238, 97), 28, PAPER, true, true)
	_panel(detail, Rect2(19, 154, 238, 1), LINE, LINE)
	_label(detail, Levels.GOALS[selected_level[2]], Rect2(19, 168, 238, 116), 17, PAPER, false, true)
	if map_focus > cleared:
		_label(detail, _t("Clear sector %02d to advance.") % (cleared + 1), Rect2(19, 314, 238, 75), 14, DIM, false, true)
	else:
		var go := _button(detail, "Mission briefing", Rect2(19, 362, 238, 52), prepare_sector.bind(map_focus), true)
		if focus != null:
			focus.focus_neighbor_right = focus.get_path_to(go)
			go.focus_neighbor_left = go.get_path_to(focus)
	_show_save_notice(screen, Rect2(272, 582, 540, 30))
	if focus != null:
		focus.grab_focus()

func _select_region(region: int) -> void:
	map_region = region
	map_focus = -1
	_draw_page.call_deferred()

func _focus_sector(index: int) -> void:
	if map_focus != index:
		map_focus = index
		_draw_page.call_deferred()

func prepare_sector(index: int) -> void:
	_prepare_mission(index, "map")

func _prepare_mission(index: int, previous: String) -> void:
	if not game.campaign.selectable(index, Levels.TABLE.size()):
		return
	mission_return = previous
	sector_pending = index
	if previous == "map":
		map_focus = index
		map_region = Levels.TABLE[index][1]
	_open("mission")

func _open_shop(index: int) -> void:
	shop_return = page
	sector_pending = index
	gear_page = 0
	_open("shop")

func _mission() -> void:
	var level: Array = Levels.TABLE[sector_pending]
	var tint: Color = Levels.TINTS[level[1]]
	var screen := _screen("Mission briefing", tint)
	_back_arrow(screen, Rect2(48, 35, 44, 43), back, "Back")
	_label(screen, "%02d  /  %s" % [sector_pending + 1, _t(Levels.REGIONS[level[1]])], Rect2(48, 128, 659, 33), 17, tint)
	_label(screen, level[0], Rect2(48, 166, 659, 86), 50, PAPER, true)
	_label(screen, Levels.GOALS[level[2]], Rect2(48, 251, 647, 65), 19, PAPER, false, true)
	_mission_diagram(screen, level, tint)
	_label(screen, "Bonus star targets", Rect2(48, 555, 223, 49), 14, DIM)
	_label(screen, "%s    /    %s" % [_t("Time ≤ %ds") % int(level[5]), _t("Hits ≤ %d") % (1 if level[2] == "boss" else 0)], Rect2(278, 555, 421, 49), 17, tint)
	var reserved: Array = game.campaign.reserved
	var loadout := _panel(screen, Rect2(729, 135, 375, 391), PANEL, LINE)
	_label(loadout, "Starting loadout", Rect2(22, 18, 331, 49), 25, PAPER, true)
	_panel(loadout, Rect2(22, 72, 331, 1), LINE, LINE)
	var entry: Dictionary = game.campaign.entry(sector_pending)
	var starting_rule: String = _t(game.RULE_NAMES[entry.rule])
	_label(loadout, _t("Carried: %s   /   Hull %s of 7") % [starting_rule, entry.hp], Rect2(22, 82, 331, 55), 15, tint, false, true)
	for i in reserved.size():
		var id: int = reserved[i]
		var y := 142.0 + i * 43.0
		_gear_badge(loadout, Rect2(22, y, 35, 35), id, true)
		_label(loadout, Gear.ITEMS[id][0], Rect2(69, y, 284, 36), 15)
	if reserved.is_empty():
		_label(loadout, "Equipment is optional.", Rect2(22, 140, 331, 64), 16, DIM, false, true)
	_label(loadout, "Equipment timers start when the fight begins.", Rect2(22, 276, 331, 48), 13, DIM, false, true)
	_button(loadout, "Equipment shop", Rect2(22, 325, 331, 45), _open_shop.bind(sector_pending))
	_show_save_notice(screen, Rect2(48, 514, 659, 32))
	_panel(screen, Rect2(48, 547, 1056, 1), LINE, LINE)
	var deploy := _button(screen, "Start sector", Rect2(729, 565, 375, 50), _start_selected, true)
	deploy.grab_focus()

func _mission_diagram(parent: Control, level: Array, tint: Color) -> void:
	var card := _panel(parent, Rect2(48, 330, 659, 182), INK, LINE)
	var route := preload("res://src/route.gd").new()
	route.load_level(level)
	_label(card, ("Boss encounter" if level[2] == "boss" else "Checkpoint route"), Rect2(18, 10, 620, 36), 14, tint)
	card.draw.connect(func():
		var baseline := 142.0
		for column in 25:
			for row in 5:
				card.draw_circle(Vector2(17 + column * 26, 55 + row * 22), 0.75, Color(tint, 0.18))
		card.draw_line(Vector2(18, baseline), Vector2(641, baseline), LINE, 1.0)
		if level[2] == "boss":
			var origin := Vector2(471, 103)
			for r in [22, 30, 38]:
				card.draw_arc(origin, r, 0.0, TAU, 48, Color(tint, 0.26), 1.0, true)
			var rules: Array = game.ENCOUNTERS[level[3]].rules
			Icons.paint_rule(card, origin, 1.36, tint, rules[0 if sector_pending < 24 else 1])
			card.draw_polyline(PackedVector2Array([Vector2(108, baseline), Vector2(108, 104), Vector2(398, 104)]), Color(tint, 0.63), 1.5, true)
			return
		for deck in route.ledges:
			var p := Vector2(20 + deck.position.x * 0.53, baseline - (488 - deck.position.y) * 0.36)
			card.draw_rect(Rect2(p, Vector2(deck.size.x * 0.53, 4)), Color(tint, 0.35))
		var path := PackedVector2Array([Vector2(20 + 214 * 0.53, baseline)])
		for target: Vector2 in route.targets:
			path.append(Vector2(20 + target.x * 0.53, baseline - (488 - target.y) * 0.36 - 9))
		card.draw_polyline(path, Color(tint, 0.53), 1.4, true)
		for index in range(1, path.size()):
			card.draw_circle(path[index], 5.0, tint, true, -1.0, true)
	)

func _shop() -> void:
	var screen := _screen("Equipment shop", AMBER, 0.98)
	_back_arrow(screen, Rect2(48, 35, 44, 43), back, "Back")
	var wallet := _label(screen, _t("%d coins") % game.campaign.coins, Rect2(820, 34, 284, 45), 22, AMBER, true)
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var stock := Gear.stock(game.campaign.records.size(), true)
	var pages := ceili(stock.size() / 4.0)
	gear_page = clampi(gear_page, 0, maxi(0, pages - 1))
	var reserved: Array = game.campaign.reserved
	for i in range(gear_page * 4, mini(stock.size(), gear_page * 4 + 4)):
		var id: int = stock[i]
		var item: Array = Gear.ITEMS[id]
		var slot := i % 4
		var selected: bool = id in reserved
		var card := _panel(screen, Rect2(48 + (slot % 2) * 386, 135 + (slot / 2) * 202, 368, 184), Color("#17333e"), AMBER if selected else LINE)
		_panel(card, Rect2(0, 0, 368, 3), AMBER if selected else GREEN.darkened(0.4), LINE)
		_gear_badge(card, Rect2(16, 22, 58, 58), id)
		_label(card, item[0], Rect2(91, 15, 258, 44), 24, PAPER, true)
		_label(card, item[1], Rect2(91, 62, 258, 45), 14, DIM, false, true)
		_label(card, _t("Effect lasts %d seconds") % int(item[2]), Rect2(16, 104, 333, 29), 13, GREEN)
		var button := _button(card, (_t("Remove · %d coins") % int(item[3])) if selected else (_t("Buy · %d coins") % int(item[3])), Rect2(16, 135, 333, 35), _refund.bind(id) if selected else _buy.bind(id), not selected)
		button.disabled = not selected and (reserved.size() >= Gear.MAX_LOADOUT or item[3] > game.campaign.coins)
		if button.disabled:
			button.text = _t("Loadout full") if reserved.size() >= Gear.MAX_LOADOUT else (_t("%d coins short") % (item[3] - game.campaign.coins))
		if purchased_id == id and selected:
			_animate_purchase(card)
	var loadout := _panel(screen, Rect2(842, 135, 262, 386), Color("#0d2530"), Color("#637b76"))
	_label(loadout, "Starting loadout", Rect2(18, 13, 227, 45), 22, AMBER, true)
	for i in Gear.MAX_LOADOUT:
		var y := 70.0 + i * 80.0
		if i < reserved.size():
			var id: int = reserved[i]
			var remove := _button(loadout, "", Rect2(17, y, 228, 67), _refund.bind(id))
			_gear_badge(remove, Rect2(10, 10, 47, 47), id)
			_label(remove, Gear.ITEMS[id][0], Rect2(67, 5, 149, 31), 16, PAPER, true)
			_label(remove, "Click to refund", Rect2(67, 34, 149, 27), 12, AMBER)
		else:
			var empty := _panel(loadout, Rect2(17, y, 228, 67), Color("#10212b"), LINE.darkened(0.2))
			_label(empty, "%02d" % (i + 1), Rect2(14, 8, 44, 48), 22, DIM, true)
			_label(empty, "Empty slot", Rect2(67, 8, 149, 48), 15, DIM)
	_label(loadout, "Cancel freely before deployment. Full refund.", Rect2(18, 318, 227, 57), 14, DIM, false, true)
	_panel(screen, Rect2(48, 547, 1056, 1), LINE, LINE)
	_back_arrow(screen, Rect2(48, 568, 44, 46), _shop_page.bind(-1), "Previous").disabled = gear_page == 0
	_back_arrow(screen, Rect2(159, 568, 44, 46), _shop_page.bind(1), "Next", true).disabled = gear_page >= pages - 1
	var pager := _label(screen, "%d / %d" % [gear_page + 1, pages], Rect2(96, 568, 60, 46), 14, DIM)
	pager.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(screen, "Equipment timers start when the fight begins.", Rect2(226, 565, 495, 52), 13, DIM, false, true)
	_button(screen, "Return to briefing" if sector_pending >= 0 else "Equipment index", Rect2(805, 568, 299, 46), back if sector_pending >= 0 else _open_archive.bind(1), true)
	_show_save_notice(screen, Rect2(48, 517, 1000, 28))
	purchased_id = -1

func _animate_purchase(card: Control) -> void:
	if game.reduced_motion or game.save_path.is_empty():
		return
	card.modulate = Color("#bbffe8")
	card.create_tween().tween_property(card, "modulate", Color.WHITE, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _refund(id: int) -> void:
	game.refund_gear(id)
	_draw_page.call_deferred()

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
	if game.buy_gear(id):
		purchased_id = id
	_draw_page.call_deferred()

func _start_selected() -> void:
	lesson_pending.clear()
	for id in Levels.lessons_at(sector_pending):
		if id not in game.campaign.lessons:
			lesson_pending.append(id)
	_next_context_lesson()

func _next_context_lesson() -> void:
	if lesson_pending.is_empty():
		_deploy_pending()
	else:
		active_lesson = lesson_pending.pop_front()
		_open("new_lesson")

func _deploy_pending() -> void:
	if game.begin_sector(sector_pending):
		game.engage_sector()

func _open_archive(tab: int) -> void:
	if page != "archive" and page != "guide" and page != "new_lesson":
		archive_return = page
	dossier = tab
	gear_page = 0
	_open("archive")

func _archive() -> void:
	var panel := _screen("Field archive", AMBER, 0.94)
	_back_arrow(panel, Rect2(48, 35, 44, 43), back)
	_button(panel, "Controls guide", Rect2(48, 135, 212, 46), _open.bind("guide"))
	_button(panel, "Mechanics", Rect2(48, 197, 212, 46), _open_archive.bind(0), false, dossier == 0)
	_button(panel, "Equipment index", Rect2(48, 259, 212, 46), _open_archive.bind(1), false, dossier == 1)
	_panel(panel, Rect2(285, 135, 1, 393), LINE, LINE)
	var total := Levels.LESSONS.size() if dossier == 0 else Gear.ITEMS.size()
	var progress: int = game.campaign.records.size()
	var focus: Button
	for i in range(gear_page * 8, mini(total, (gear_page + 1) * 8)):
		var slot := i % 8
		var at := Rect2(309 + slot % 2 * 406, 135 + (slot / 2) * 98, 389, 83)
		if dossier == 0:
			var known := Levels.unlocked_lesson(i, progress)
			var tile := _button(panel, "", at, _replay_context.bind(i))
			tile.disabled = not known
			_label(tile, "%02d" % (i + 1), Rect2(20, 15, 42, 51), 15, AMBER if known else DIM)
			_label(tile, Levels.LESSONS[i][0] if known else "???", Rect2(69, 15, 294, 51), 20, PAPER if known else DIM, true)
			if known and focus == null:
				focus = tile
		else:
			var item: Array = Gear.ITEMS[i]
			var known: bool = progress >= item[4]
			var card := _panel(panel, at, INK)
			if known:
				_gear_badge(card, Rect2(14, 16, 48, 48), i)
			_label(card, item[0] if known else "???", Rect2(75, 5, 298, 29), 16, game.equipment_color(i) if known else DIM, true)
			if known:
				_label(card, item[1], Rect2(75, 34, 298, 26), 12, PAPER)
				_label(card, "%s  /  %s" % [_t("Effect lasts %d seconds") % item[2], str(item[3]) if item[3] > 0 else _t("Drop only")], Rect2(75, 56, 298, 24), 12, DIM)
	_panel(panel, Rect2(48, 551, 1056, 1), LINE, LINE)
	_back_arrow(panel, Rect2(309, 570, 44, 44), _archive_page.bind(-1), "Previous").disabled = gear_page == 0
	_back_arrow(panel, Rect2(427, 570, 44, 44), _archive_page.bind(1), "Next", true).disabled = (gear_page + 1) * 8 >= total
	var tally := _label(panel, "%d / %d" % [gear_page + 1, ceili(total / 8.0)], Rect2(359, 570, 63, 44), 15, DIM)
	tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if focus != null:
		focus.grab_focus()

func _archive_page(direction: int) -> void:
	gear_page += direction
	_draw_page.call_deferred()

func _replay_context(id: int) -> void:
	sector_pending = -1
	active_lesson = id
	_open("new_lesson")

func _new_lesson() -> void:
	var lesson: Array = Levels.LESSONS[active_lesson]
	var tone: Color = Levels.TINTS[Levels.TABLE[sector_pending][1]] if sector_pending >= 0 else AMBER
	var screen := _guide_screen("Mechanics", lesson[0], lesson[1], LESSON_KEYS[active_lesson], tone, true)
	var context := _label(screen, "%02d / %s" % [sector_pending + 1, _t(Levels.TABLE[sector_pending][0])] if sector_pending >= 0 else _t("Field archive"), Rect2(772, 39, 332, 37), 16, tone)
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	next_step_button = _button(screen, "Continue" if sector_pending >= 0 else "Done", Rect2(780, 572, 324, 48), _acknowledge_lesson, true)
	if active_lesson >= 20:
		_button(screen, "Try it", Rect2(780, 490, 324, 45), game.begin_context_practice.bind(active_lesson))
	next_step_button.disabled = sector_pending >= 0 and not game.reduced_motion
	_prepare_preview("context-%02d" % active_lesson, screen)
	_focus_guide_action()

func _acknowledge_lesson() -> void:
	if sector_pending < 0:
		_open("archive")
		return
	if active_lesson not in game.campaign.lessons:
		game.campaign.lessons.append(active_lesson)
		game._save()
	_next_context_lesson()

func _pause() -> void:
	var panel := _modal("LINK PAUSED", Rect2(56, 126, 434, 380))
	if game.save_error:
		_show_save_notice(panel, Rect2(29, 78, 376, 44))
	else:
		_label(panel, "Protocol run pauses here. Leaving ends this run." if game.protocol_run else "Your cleared sectors are saved.", Rect2(29, 78, 376, 44), 15, DIM, false, true)
	var resume := _button(panel, "RESUME", Rect2(28, 137, 378, 55), _resume, true)
	_button(panel, "Restart sector", Rect2(28, 210, 378, 49), game._retry)
	if game.practice >= 0 and onboarding:
		_button(panel, "Return to guide", Rect2(28, 282, 378, 49), game.return_from_practice)
	else:
		var leave := _back_arrow(panel, Rect2(28, 282, 378, 49), game.return_to_lobby)
		_label(leave, "Return to lobby", Rect2(50, 0, 312, 49), 16, PAPER)
	resume.grab_focus()

func _resume() -> void:
	game.mode = game.resume_mode

func _result() -> void:
	var timed_out: bool = game.mode == "lost" and game.route.limit > 0.0 and game.route.clock >= game.route.limit
	var title: String = {
		"lost": "Time expired" if timed_out else "HULL BREACHED", "practice_done": "Practice complete",
		"win": "RULES REWRITTEN", "clear": "Sector secured",
	}[game.mode]
	if game.mission_sector and game.mode in ["clear", "win"]:
		_campaign_result(title, game.sector_result)
		return
	var panel := _modal(title, Rect2(251, 172, 650, 304))
	var text_line := "You can try another action from the guide."
	var action := "Return to guide"
	var callback: Callable = game.return_from_practice
	if game.mode == "practice_done" and game.context_practice >= 0:
		callback = game.return_to_lobby
	if game.mode == "practice_done" and onboarding:
		var practice_chapter: int = game.practice
		action = "Enter lobby" if practice_chapter == DEMOS.size() - 1 else "Next lesson"
		callback = _practice_next.bind(practice_chapter)
	if game.mode in ["clear", "win"]:
		var score: Dictionary = game.sector_result
		text_line = _t("%s  /  %s hits  /  %s retries") % [game.timecode(score.get("seconds", 0.0)), score.get("hits", 0), score.get("retries", 0)]
		action = "Sector map"
		callback = game.return_to_lobby.bind("map")
		if game.protocol_run:
			action = "Next boss" if game.mode == "clear" else "Return to lobby"
			callback = game.continue_after_clear if game.mode == "clear" else game.return_to_lobby
			if game.mode == "win":
				text_line = _t("System freed. You are no longer its exception.") + "\n" + _t("%s  /  %d transfers  /  %d retries") % [game.timecode(game.run_time), game.steals, game.run_retries]
			else:
				text_line += "\n" + _t("Your rule carries forward. Hull repaired +3.")
	elif game.mode == "lost":
		text_line = game.last_failure if not game.last_failure.is_empty() else ("Time ran out. Retry from the start of this sector." if timed_out else "Reboot from this sector with your entry loadout.")
		action = "REBOOT"
		callback = game._retry
	_label(panel, text_line, Rect2(29, 83, 590, 75), 17, DIM, false, true)
	_show_save_notice(panel, Rect2(29, 154, 590, 32))
	var proceed := _button(panel, action, Rect2(28, 202, 298, 52), callback, true)
	if game.mode in ["lost", "clear", "win"]:
		_back_arrow(panel, Rect2(343, 202, 56, 52), game.return_to_lobby)
	elif game.mode == "practice_done" and onboarding:
		_button(panel, "Try again", Rect2(343, 202, 279, 52), game._retry)
	proceed.grab_focus()

func _practice_next(done: int) -> void:
	lesson_watched[done] = true
	practice_demo_time = -1.0
	if done >= DEMOS.size() - 1:
		onboarding = false
		game.guide_seen = true
		chapter = 0
		game.return_to_lobby()
	else:
		chapter = done + 1
		game.return_from_practice()

func _campaign_result(title: String, score: Dictionary) -> void:
	var level: Array = Levels.TABLE[game.sector_index]
	var screen := _screen(title, Levels.TINTS[level[1]], 0.9)
	_back_arrow(screen, Rect2(48, 35, 44, 43), game.return_to_lobby)
	_label(screen, "%02d / %s" % [game.sector_index + 1, _t(level[0])], Rect2(57, 141, 500, 47), 20, DIM)
	var score_tray := _panel(screen, Rect2(48, 201, 462, 167), PANEL, LINE)
	_panel(score_tray, Rect2(0, 0, 462, 3), AMBER, AMBER)
	for i in 3:
		var rank := Control.new()
		rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(rank, score_tray, Rect2(78 + i * 112, 38, 76, 76))
		_star(rank, Vector2(38, 38), 34.0, AMBER if i < score.get("stars", 1) else LINE)
		if opening_page and i < score.get("stars", 1) and not game.reduced_motion and not game.save_path.is_empty():
			rank.modulate.a = 0.13
			rank.pivot_offset = Vector2(38, 38)
			rank.scale = Vector2(0.70, 0.70)
			var award := rank.create_tween().set_parallel(true)
			award.tween_property(rank, "modulate:a", 1.0, 0.20).set_delay(0.17 + i * 0.09)
			award.tween_property(rank, "scale", Vector2.ONE, 0.25).set_delay(0.17 + i * 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_label(screen, _t("+%d coins") % score.get("coins", 0), Rect2(57, 384, 458, 72), 37, AMBER, true)
	_label(screen, _t("%d perfect shifts  /  %d exchanges") % [score.get("perfect", 0), score.get("shifts", 0)], Rect2(57, 463, 453, 43), 15, DIM)
	var details := _panel(screen, Rect2(543, 135, 561, 359), PANEL, LINE)
	_label(details, "Bonus star targets", Rect2(22, 21, 486, 51), 26, PAPER, true)
	_score_row(details, 89, _t("Time ≤ %ds") % int(level[5]), game.timecode(score.get("seconds", 0.0)), score.get("fast", false))
	_score_row(details, 185, _t("Hits ≤ %d") % (1 if level[2] == "boss" else 0), str(score.get("hits", 0)), score.get("clean", false))
	_show_save_notice(screen, Rect2(57, 492, 460, 33))
	_panel(screen, Rect2(48, 545, 1056, 1), LINE, LINE)
	_button(screen, "Retry", Rect2(48, 565, 162, 50), _retry_from_results)
	var last: bool = game.sector_index == Levels.TABLE.size() - 1
	var next := _button(screen, "Sector map" if last else "Next sector", Rect2(780, 565, 324, 50), game.continue_after_clear, true)
	next.grab_focus()

func _score_row(parent: Control, y: float, condition: String, actual: String, met: bool) -> void:
	_label(parent, condition, Rect2(23, y, 305, 29), 15, DIM)
	_label(parent, actual, Rect2(23, y + 30, 294, 45), 29, PAPER, true)
	var marker := _label(parent, "Target met" if met else "Target missed", Rect2(304, y + 27, 205, 41), 15, GREEN if met else AMBER)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _star(parent: Control, center: Vector2, radius: float, color: Color) -> void:
	parent.draw.connect(func():
		var points := PackedVector2Array()
		for i in 10:
			points.append(center + Vector2.from_angle(-PI / 2.0 + i * TAU / 10.0) * radius * (1.0 if i % 2 == 0 else 0.46))
		parent.draw_colored_polygon(points, color)
	)

func _retry_from_results() -> void:
	if game.begin_sector(game.sector_index):
		game.engage_sector()

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
	var demo: Array = DEMOS[chapter]
	var screen := _guide_screen("Controls guide", demo[1], demo[4], [["A / D", "SPACE"], ["J"], ["K"], ["SHIFT"], ["E"]][chapter], AMBER, not onboarding or chapter > 0)
	var count := _label(screen, _t("Lesson %d of %d") % [chapter + 1, DEMOS.size()], Rect2(800, 33, 304, 29), 16, PAPER)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for index in DEMOS.size():
		var x := 913.0 + index * 39.0
		var tab := _button(screen, "%d" % (index + 1), Rect2(x, 67, 35, 26), _choose_demo.bind(index), false, index == chapter)
		tab.add_theme_font_size_override("font_size", 13)
		tab.tooltip_text = _t(DEMOS[index][1])
		tab.disabled = onboarding and index > chapter and not lesson_watched.has(index - 1)
	_button(screen, "Try it", Rect2(780, 490, 324, 45), _try_lesson)
	var last := chapter == DEMOS.size() - 1
	next_step_button = _button(screen, ("Enter lobby" if onboarding else "Done") if last else "Next lesson", Rect2(780, 572, 324, 48), _next_lesson, true)
	next_step_button.disabled = onboarding and not lesson_watched.has(chapter) and not game.reduced_motion
	_prepare_preview(demo[0], screen)
	_focus_guide_action()

func _guide_screen(heading: String, title: String, instructions: String, keys: Array, tone: Color, show_back: bool) -> Control:
	var screen := _screen(heading, tone, 0.96)
	if show_back:
		_back_arrow(screen, Rect2(48, 35, 44, 43), back, "Back")
	else:
		var mark := TextureRect.new()
		mark.texture = preload("res://assets/icon.svg")
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(mark, screen, Rect2(48, 35, 45, 45))
	_panel(screen, GUIDE_FRAME.grow(1.0), Color("#0d1217"), LINE)
	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(preview, screen, GUIDE_FRAME)
	_panel(screen, Rect2(780, 135, 324, 3), tone, tone)
	_label(screen, title, Rect2(780, 153, 324, 91), 34, PAPER, true, true)
	_label(screen, instructions, Rect2(780, 251, 324, 179), 17, PAPER, false, true)
	if not keys.is_empty():
		_draw_keycaps(screen, keys, 440)
	_panel(screen, Rect2(48, 553, 1056, 1), LINE, LINE)
	demo_toggle = _button(screen, "Pause demo", Rect2(48, 572, 186, 48), _toggle_demo)
	_label(screen, "Gameplay recording", Rect2(253, 572, 340, 48), 14, DIM)
	return screen

func _draw_keycaps(parent: Control, keys: Array, y: float) -> void:
	var x := 780.0
	for key: String in keys:
		var action_map := {"J": "strike", "K": "dodge", "SHIFT": "steal", "E": "rule", "SPACE": "jump"}
		var label: String = game.key_label(action_map[key]) if action_map.has(key) else game.key_label("left") + " / " + game.key_label("right")
		var wide := 77.0 if label.length() > 2 else 48.0
		var cap := _panel(parent, Rect2(x, y, wide, 37), INK, LINE)
		var text := _label(cap, label, Rect2(0, 0, wide, 36), 14, GREEN)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		x += wide + 9.0

func _focus_guide_action() -> void:
	if next_step_button.disabled:
		demo_toggle.grab_focus()
	else:
		next_step_button.grab_focus()

func _prepare_preview(filename: String, screen: Control) -> void:
	demo_progress = ProgressBar.new()
	demo_progress.show_percentage = false
	demo_progress.max_value = FRAME_COUNT - 1
	demo_progress.add_theme_stylebox_override("background", _style(INK, INK, 0))
	demo_progress.add_theme_stylebox_override("fill", _style(GREEN, GREEN, 0))
	demo_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(demo_progress, screen, Rect2(GUIDE_FRAME.position.x, GUIDE_FRAME.end.y + 5, GUIDE_FRAME.size.x, 4))
	demo_texture = AtlasTexture.new()
	demo_texture.filter_clip = true
	preview.texture = demo_texture
	for i in range(ceili(float(FRAME_COUNT) / FRAMES_PER_SHEET)):
		var path := "res://assets/demos/%s-%s.webp" % [filename, i]
		if ResourceLoader.exists(path):
			demo_sheets.append(load(path))
	if demo_sheets.size() != ceili(float(FRAME_COUNT) / FRAMES_PER_SHEET):
		var error := _label(screen, "Demo unavailable", GUIDE_FRAME, 17, DIM)
		error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		is_playing = false
		demo_toggle.disabled = true
		_mark_lesson_watched()
	else:
		var returning := page == "guide" and practice_demo_time >= 0.0
		is_playing = not game.reduced_motion and not returning
		demo_toggle.text = _t("Pause demo" if is_playing else "Play")
		demo_time = practice_demo_time if returning else (0.0 if is_playing else 2.3)
		practice_demo_time = -1.0
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

func _try_lesson() -> void:
	practice_demo_time = demo_time
	game.begin_practice(chapter, "guide")

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
	demo_time = minf(demo_time + delta, demo_duration())
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
	if get_viewport().gui_get_focus_owner() == demo_toggle:
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
	return (17.0 if active_lesson == 23 else 10.0) if page == "new_lesson" else 7.0

func play_arena_reveal() -> void:
	if game.reduced_motion or game.save_path.is_empty():
		return
	if is_instance_valid(arena_reveal):
		arena_reveal.queue_free()
	var screen := CanvasLayer.new()
	arena_reveal = screen
	screen.layer = 6
	add_child(screen)
	var transition := preload("res://src/deployment_transition.gd").new()
	transition.heading = _t("Entering sector")
	transition.title = _t(Levels.TABLE[game.sector_index][0]) if game.mission_sector else _t(game.ENCOUNTERS[game.stage].name)
	transition.tone = Levels.TINTS[Levels.TABLE[game.sector_index][1]]
	transition.font = Locale.face(Locale.current())
	transition.face = Locale.face(Locale.current(), true)
	screen.add_child(transition)

func back() -> void:
	binding_index = -1
	game._save()
	if page == "language":
		return
	if onboarding and page == "guide":
		if chapter > 0:
			_choose_demo(chapter - 1)
		return
	if page == "new_lesson":
		if sector_pending >= 0:
			_open("mission")
		else:
			_open("archive")
		return
	if page == "shop" and sector_pending >= 0:
		_open(shop_return)
		return
	if page == "mission":
		_open(mission_return)
		return
	if page == "reset":
		_open("settings")
		return
	if page == "archive":
		_open(archive_return)
		return
	if page == "guide":
		chapter = 0
		_open("archive")
		return
	chapter = 0
	_open("")
