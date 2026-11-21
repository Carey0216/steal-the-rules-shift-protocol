extends "res://tests/smoke.gd"
## Real game states, isolated from player saves. Capture directory is ignored by Git.

func _run() -> void:
	g = GAME.instantiate()
	g.save_path = ""
	root.add_child(g)
	g.set_physics_process(false)
	g.set_fullscreen(false)
	g.audio_rig.set_mute(true)
	g.set_language(0)
	g.guide_seen = true
	g.title_menu.onboarding = false
	g.return_to_lobby()
	await _shot("lobby-final")
	for language in g.Locale.CODES.size():
		g.set_language(language)
		g.title_menu._open("protocol")
		await _shot("protocol-" + g.Locale.CODES[language])
		g.text_size_index = 2
		g.title_menu._draw_page()
		await _shot("protocol-large-" + g.Locale.CODES[language])
		g.text_size_index = 0
	g.set_language(0)
	g.title_menu._launch_protocol()
	for boss in g.ENCOUNTERS.size():
		for tick in 120 * 120:
			var input := _pilot()
			g.clock += DT
			g._tick_fight(DT, input.axis, input.pressed, input.strike)
			g._tick_fx(DT)
			if boss == 0 and g.wire_time > 0.33 and not captures.has("transfer-final"):
				await _shot("transfer-final")
			if boss == 1 and g.floor_broken and g.floor_y > g.BASE + 43 and not captures.has("breach-final"):
				await _shot("breach-final")
			if boss == 3 and g.boss_phase == 3 and g.state == "windup" and not captures.has("protocol-iii"):
				await _shot("protocol-iii")
			if g.mode != "fight":
				break
		if boss < 5:
			g.continue_after_clear()
			g.engage_sector()
	await _shot("ending-final")
	quit(1 if failed else 0)
