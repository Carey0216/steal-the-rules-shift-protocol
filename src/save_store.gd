extends RefCounted
## Sanitize local data before it reaches typed gameplay properties.

static func sanitize(source: ConfigFile) -> ConfigFile:
	var clean := ConfigFile.new()
	var defaults := {
		"settings": {"mute": false, "reduced_motion": false, "assist": false, "master_volume": 1.0, "music_volume": 0.7, "effects_volume": 0.85, "shake_strength": 0.65, "language": "", "guide_seen": false, "text_size": 0, "window_size": 0, "fullscreen": true, "keys": []},
		"records": {"clear_time": 0.0},
		"operation": {"clears": [], "next_hull": 7, "next_rule": 0, "coins": 0, "reserved": [], "lessons": []},
	}
	for section in defaults:
		for key in defaults[section]:
			var fallback: Variant = defaults[section][key]
			var value: Variant = source.get_value(section, key, fallback)
			var valid := typeof(value) == typeof(fallback)
			if typeof(fallback) == TYPE_FLOAT:
				valid = (value is float or value is int) and is_finite(float(value))
			if valid:
				clean.set_value(section, key, value)
	var records: Array = clean.get_value("operation", "clears", [])
	var accepted: Array = []
	for record in records:
		if not record is Dictionary:
			break
		var valid := true
		for key in ["entry_hp", "entry_rule", "hits", "retries", "stars", "seconds"]:
			var value: Variant = record.get(key, 0)
			if not (value is int or value is float) or not is_finite(float(value)):
				valid = false
		if not valid:
			break
		accepted.append(record)
	clean.set_value("operation", "clears", accepted)
	return clean

static func load_profile(path: String) -> Dictionary:
	var source := ConfigFile.new()
	var recovered := false
	if not path.is_empty() and source.load(path) != OK:
		recovered = source.load(path + ".backup") == OK
	return {"config": sanitize(source), "recovered": recovered}
