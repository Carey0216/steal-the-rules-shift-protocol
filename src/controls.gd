extends RefCounted
## One physical keyboard key for each action. Rebinding swaps occupied keys.
const ACTIONS := ["left", "right", "jump", "strike", "dodge", "steal", "rule", "pause", "retry"]
const TITLES := ["Move left", "Move right", "Jump", "Strike", "Dodge", "Shift", "Use your rule", "Pause", "Retry"]
const DEFAULTS := [KEY_A, KEY_D, KEY_SPACE, KEY_J, KEY_K, KEY_SHIFT, KEY_E, KEY_ESCAPE, KEY_R]
const PAD := ["STICK", "STICK", "A", "X", "B", "RB", "Y", "START", "BACK"]

var keys: Array[int] = []

func install(config: ConfigFile) -> void:
	keys.assign(DEFAULTS)
	var saved: Variant = config.get_value("settings", "keys", [])
	if saved is Array and saved.size() == DEFAULTS.size():
		var unique := {}
		var valid := true
		for key in saved:
			valid = valid and key is int and key > 0 and key != KEY_ENTER and key != KEY_F11 and not unique.has(key)
			unique[key] = true
		if valid:
			keys.assign(saved)
	apply()

func apply() -> void:
	var localization := preload("res://src/locale.gd")
	localization.custom_keys.clear()
	for i in ACTIONS.size():
		if DEFAULTS[i] != keys[i]:
			localization.custom_keys[OS.get_keycode_string(DEFAULTS[i]).to_upper()] = OS.get_keycode_string(keys[i]).to_upper()
	for i in ACTIONS.size():
		if not InputMap.has_action(ACTIONS[i]):
			InputMap.add_action(ACTIONS[i])
		var events := InputMap.action_get_events(ACTIONS[i])
		for event in events:
			if event is InputEventKey:
				InputMap.action_erase_event(ACTIONS[i], event)
		var event := InputEventKey.new()
		event.physical_keycode = keys[i]
		InputMap.action_add_event(ACTIONS[i], event)

func rebind(index: int, key: int) -> bool:
	if index < 0 or index >= keys.size() or key <= 0 or key in [KEY_ENTER, KEY_F11, KEY_PRINT, KEY_CAPSLOCK]:
		return false
	var occupied := keys.find(key)
	if occupied >= 0:
		keys[occupied] = keys[index]
	keys[index] = key
	apply()
	return true

func label(action: String, pad := false) -> String:
	var i := ACTIONS.find(action)
	if i < 0:
		return action
	if pad:
		return PAD[i]
	return OS.get_keycode_string(keys[i]).to_upper()

func defaults() -> void:
	keys.assign(DEFAULTS)
	apply()
