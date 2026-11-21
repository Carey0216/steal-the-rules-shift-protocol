extends "res://tests/smoke.gd"
## Release regressions: real fixed-step combat, UI callbacks and damaged profiles.

const Store = preload("res://src/save_store.gd")

func _run() -> void:
	g = GAME.instantiate()
	g.save_path = ""
	root.add_child(g)
	g.set_physics_process(false)
	g.audio_rig.set_mute(true)
	g.guide_seen = true
	g.title_menu.onboarding = false
	for language in range(1, Locale.CODES.size()):
		var file := FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
		file.get_csv_line()
		var font: Font = Locale.face(language)
		while not file.eof_reached():
			var row := file.get_csv_line()
			if row.size() > language + 1:
				for character in row[language + 1]:
					if character.unicode_at(0) > 32:
						_check(font.has_char(character.unicode_at(0)), "Missing localized glyph in " + Locale.CODES[language] + ": " + character)
	_test_profiles()
	_test_blocked_counter()
	_test_protocol_menu()
	for seed_value in [17, 94, 2026]:
		for assisted in [false, true]:
			g.assist = assisted
			g.combat_rng.seed = seed_value
			g.gear_rng.seed = seed_value
			g._new_run()
			g.engage_sector()
			var phases := {}
			for boss in g.ENCOUNTERS.size():
				for tick in 120 * 120:
					var input := _pilot()
					g._tick_fight(DT, input.axis, input.pressed, input.strike)
					g._tick_fx(DT)
					phases[g.boss_phase] = true
					_check(is_finite(g.p.x) and is_finite(g.p.y), "Combat positions stay finite.")
					if g.mode != "fight":
						break
				var expected := "win" if boss == 5 else "clear"
				_check(g.mode == expected, "Protocol pilot clears boss %d, seed %d, assist %s (hp %d, boss %d)." % [boss, seed_value, assisted, g.hp, g.boss_hp])
				if g.mode != expected:
					break
				if boss < 5:
					g.continue_after_clear()
					g.engage_sector()
			_check(phases.size() == 3, "All three combat protocols are reached.")
			print("Protocol seed ", seed_value, " assist ", assisted, ": ", g.mode, " in ", g.timecode(g.run_time), ", transfers ", g.steals, ", hull ", g.hp)
	print("Release result: ", failed, " failures")
	quit(1 if failed else 0)

func _test_profiles() -> void:
	var broken := ConfigFile.new()
	broken.set_value("settings", "master_volume", "broken")
	broken.set_value("settings", "music_volume", INF)
	broken.set_value("settings", "mute", [])
	broken.set_value("operation", "next_hull", "broken")
	broken.set_value("operation", "reserved", "broken")
	broken.set_value("operation", "lessons", 45)
	broken.set_value("operation", "clears", [{"seconds": "broken"}])
	var clean := Store.sanitize(broken)
	var profile := Campaign.new()
	profile.load_from(clean, 48)
	_check(profile.records.is_empty() and profile.reserved.is_empty() and profile.next_hull == 7, "Malformed local data safely defaults.")
	_check(clean.get_value("settings", "master_volume", 1.0) == 1.0 and clean.get_value("settings", "music_volume", 0.7) == 0.7, "Invalid audio data defaults.")
	var path := "user://release-test-profile.cfg"
	var original := ConfigFile.new()
	original.set_value("operation", "coins", 9000)
	_check(original.save(path + ".backup") == OK, "Can write isolated backup fixture.")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[broken\n")
	file.close()
	# ConfigFile reports a parse error for this intentionally damaged fixture.
	Engine.print_error_messages = false
	var recovered := Store.load_profile(path)
	Engine.print_error_messages = true
	_check(recovered.recovered and recovered.config.get_value("operation", "coins") == 9000, "Corrupt primary loads its real backup.")
	g.config = recovered.config
	g.campaign.load_from(g.config, 48)
	g.save_recovered = true
	g.save_path = path
	_check(g._save() == OK, "Recovered profile can save again.")
	var backup := ConfigFile.new()
	_check(backup.load(path + ".backup") == OK and backup.get_value("operation", "coins") == 9000, "Recovery never replaces a good backup with a corrupt primary.")
	g.save_path = "user://missing-release-test-directory/profile.cfg"
	g.campaign.coins = 20000
	g.mode = "title"
	_check(not g.buy_gear(0) and g.campaign.coins == 20000 and g.campaign.reserved.is_empty(), "Failed save rolls back a purchase.")
	g.save_path = ""
	for suffix in ["", ".backup", ".next"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)

func _test_blocked_counter() -> void:
	g._new_run()
	g.mode = "fight"
	g.p = g.b - Vector2(65, 0)
	g.facing = 1.0
	g.boss_rule = g.Rule.AEGIS
	g.counter_time = 1.7
	g._set_state("windup", 0.6)
	var before: int = g.boss_hp
	g._strike()
	_check(g.counter_time == 1.7 and g.boss_hp == before, "Armor block preserves a perfect counter.")
	g._set_state("exposed", 1.5)
	g.boss_locks.assign([Vector2(440, 488)])
	g._strike()
	_check(g.counter_time == 1.7 and g.boss_hp == before, "Locked core preserves a perfect counter.")
	g.boss_locks.clear()
	g._strike()
	_check(g.counter_time == 0.0 and before - g.boss_hp == 7, "Connected counter is consumed once.")

func _test_protocol_menu() -> void:
	g.return_to_lobby()
	g.title_menu._open("protocol")
	_check(g.title_menu.page == "protocol", "Protocol has an accessible menu entry.")
	var coins: int = g.campaign.coins
	var records: Array = g.campaign.records.duplicate(true)
	g.title_menu._launch_protocol()
	_check(g.protocol_run and not g.mission_sector and g.mode == "fight", "Protocol menu starts real combat.")
	g._finish_arena()
	g.title_menu.sync_mode()
	_check(g.campaign.records == records and g.campaign.coins == coins, "Protocol does not modify campaign progress or wallet.")
	g.continue_after_clear()
	g.engage_sector()
	_check(g.stage == 1 and g.mode == "fight", "Next boss continues the protocol.")
	g.run_time = 10.0
	g._retry()
	_check(g.run_retries == 1 and g.stage == 1 and g.mode == "fight", "Protocol retry keeps its checkpoint and increments the total.")
	g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var at: float = g.run_time
	g._physics_process(DT)
	_check(g.mode == "paused" and g.run_time == at, "Focus loss pauses actual protocol combat.")
	if OS.get_name() == "Windows":
		g.mode = "fight"
		g.just.clear()
		var virtual_key := InputEventKey.new()
		virtual_key.keycode = KEY_ESCAPE
		virtual_key.physical_keycode = KEY_PAUSE
		virtual_key.pressed = true
		Input.parse_input_event(virtual_key)
		Input.flush_buffered_events()
		Input.flush_buffered_events()
		g._physics_process(DT)
		_check(g.mode == "paused", "Windows virtual keyboard logical Escape pauses combat without extra bindings.")
		var released := virtual_key.duplicate() as InputEventKey
		released.pressed = false
		Input.parse_input_event(released)
		Input.flush_buffered_events()
	g.return_to_lobby()
	_check(not g.protocol_run, "Leaving ends the protocol run.")
