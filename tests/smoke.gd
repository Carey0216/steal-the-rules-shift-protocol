extends SceneTree
## Run with Godot --headless --path . --script tests/smoke.gd
## The pilot below sends standard combat inputs through the fixed-step simulation.

const GAME = preload("res://main.tscn")
const Locale = preload("res://src/locale.gd")
const Campaign = preload("res://src/campaign.gd")
const DT := 1.0 / 120.0
var failed := 0
var g: Node2D
var seen_attacks := {}
var used_rules := {}
var returned_rules := {}
var breached := false
var captures := {}
var capture := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	g = GAME.instantiate()
	g.save_path = ""
	root.add_child(g)
	g.set_physics_process(false)
	g.audio_rig.set_mute(true)
	if capture:
		g.set_fullscreen(false)
	_check(g.title_menu.page == "language", "A fresh profile must request a language.")
	await _test_recording_assets()
	for index in Locale.CODES.size():
		g.set_language(index)
		_check(Locale.current() == index, "Locale must be selectable: " + Locale.CODES[index])
		if index > 0:
			_check(Locale.text("Settings") != "Settings" and Locale.text("THE WARDEN") != "THE WARDEN", "Menus and encounters must be localized.")
		for character in Locale.NAMES[index]:
			_check(Locale.face(index).has_char(character.unicode_at(0)), "Missing glyph for native language name.")
	g.set_language(0)
	g.title_menu.pending_locale = 0
	g.title_menu._confirm_language()
	_check(g.title_menu.page == "guide", "Language confirmation must open the guide.")
	g.title_menu._next_lesson()
	_check(g.title_menu.chapter == 0 or g.title_menu.lesson_watched.has(0), "A fresh guide requires the first demo before moving on.")
	for lesson in 5:
		g.title_menu.lesson_watched[lesson] = true
	if capture:
		g.title_menu._choose_demo(3)
		await process_frame
		g.title_menu.set_process(false)
		g.title_menu.demo_time = 2.2
		g.title_menu._show_frame()
		await _shot("guide")
		g.title_menu.onboarding = false
		g.set_language(1)
		g.text_size_index = 2
		g.title_menu.active_lesson = 14
		g.title_menu._open("new_lesson")
		await process_frame
		g.title_menu.set_process(false)
		g.title_menu.demo_time = 2.5
		g.title_menu._show_frame()
		await _shot("ferry-guide-zh-large")
		g.set_language(0)
		g.text_size_index = 0
	g.title_menu._finish_guide()
	_check(g.guide_seen and g.title_menu.page.is_empty(), "Finishing the guide must unlock the title screen.")
	g.assist = false
	if capture:
		await _shot("title")
	var shift := InputEventKey.new()
	shift.keycode = KEY_SHIFT
	shift.physical_keycode = KEY_SHIFT
	shift.shift_pressed = true
	shift.pressed = true
	g._input(shift)
	_check(g.just.has("steal"), "Physical SHIFT must trigger steal even with the modifier flag.")
	g.just.clear()
	g.begin_sector(1)
	_check(g.mode == "title", "Locked sectors cannot start even when invoked directly.")
	g._new_run()
	g._physics_process(DT)
	_check(g.mode == "brief" and g.stage == 0, "Run starts at first sector briefing.")
	g.just["confirm"] = true
	g._physics_process(DT)
	_check(g.mode == "fight", "Confirm starts combat.")
	g._try_shift()
	_check(g.player_rule == g.Rule.EMPTY and g.boss_hp == 49, "Sealed Warden retains its scaled health.")

	# Make sure the failure path works without stubbing health loss.
	for i in 120 * 90:
		g._tick_fight(DT, 0.0, {}, false)
		if g.mode != "fight":
			break
	_check(g.mode == "lost" and g.hp == 0, "A motionless player can lose to boss attacks.")
	g._retry()
	_check(g.mode == "fight" and g.hp == g.MAX_HP and g.player_rule == g.Rule.EMPTY and g.run_time == 0.0, "Retry restores the actual sector checkpoint.")
	g.just["pause"] = true
	g._physics_process(DT)
	var paused_at: float = g.run_time
	g._physics_process(DT)
	_check(g.mode == "paused" and g.run_time == paused_at, "Pause freezes the run clock.")
	g.just["confirm"] = true
	g._physics_process(DT)
	_check(g.mode == "fight", "Confirm resumes a paused fight.")

	g.begin_practice(3)
	for tick in 105:
		var action := {"steal": true} if g.can_shift() else {}
		g._tick_fight(DT, 1.0, action, false)
		if g.mode == "practice_done":
			break
	_check(g.mode == "practice_done" and g.campaign.records.is_empty(), "Practice uses real movement and theft without granting a campaign clear.")
	g.return_to_lobby()
	g.begin_sector(0)
	g.mode = "fight"
	g._tick_fight(DT, 1.0, {"dodge": true}, false)
	for tick in 24:
		g._tick_fight(DT, 0.0, {}, false)
	g._check_hurt(Rect2(g.p - Vector2(20, 50), Vector2(40, 50)), g.p.x)
	_check(g.hp == g.MAX_HP, "A dodge still protects after 200 ms.")
	g._new_run()
	g.mode = "fight"

	for sector in g.ENCOUNTERS.size():
		var previous_rule: int = g.player_rule
		for i in 120 * 100:
			var input := _pilot()
			var was_rule: int = g.player_rule
			var was_charge: bool = g.charge
			g.clock += DT
			g._tick_fight(DT, input.axis, input.pressed, input.strike)
			g._tick_fx(DT)
			if g.state == "windup":
				seen_attacks[g.move_name] = true
			if input.pressed.has("rule") and was_charge and not g.charge and was_rule != g.Rule.EMPTY:
				used_rules[was_rule] = true
			if g.player_rule != was_rule and was_rule != g.Rule.EMPTY:
				_check(g.boss_rule == was_rule, "Swap hands previous player rule back to the boss.")
				returned_rules[was_rule] = true
			if sector == 1 and g.floor_broken and g.floor_y >= g.BASE + 43:
				breached = true
			if capture and sector == 0 and g.wire_time > 0.33 and not captures.has("transfer"):
				await _shot("transfer")
			if capture and breached and not captures.has("breach"):
				await _shot("breach")
			if g.mode != "fight":
				break
		var desired := "win" if sector == g.ENCOUNTERS.size() - 1 else "clear"
		print("Sector ", sector + 1, ": ", g.mode, ", boss HP ", g.boss_hp, ", player HP ", g.hp, ", ", g.steals, " transfers.")
		_check(g.mode == desired, "Pilot must clear combat chassis %s within 100 seconds." % (sector + 1))
		if g.mode != desired:
			break
		if capture and sector == 1:
			g.return_to_lobby("map")
			await _shot("map")
		if sector < g.ENCOUNTERS.size() - 1:
			_check(g.player_rule != previous_rule or g.steals > 0, "Run should use the main mechanic.")
			var carried: int = g.player_rule
			g._advance()
			_check(g.player_rule == carried and g.mode == "brief", "New sector carries slot forward.")
			g.just["confirm"] = true
			g._physics_process(DT)
	_check(breached, "Stealing LIFT in the Lattice must collapse the deck.")
	_check(seen_attacks.has("RAIL CUT") and seen_attacks.has("PULSE LATTICE") and seen_attacks.has("SKY ANVIL"), "Run must encounter all three rule moves.")
	_check(returned_rules.size() == 3 and used_rules.size() == 3, "Run must use and return all three rules.")
	if capture and g.mode == "win":
		await _shot("clear")
	_test_routes_and_overclock()
	_test_operation()
	_test_save()
	if capture:
		var all_records: Array[Dictionary] = g.campaign.records.duplicate(true)
		g.campaign.records.resize(11)
		g.title_menu.map_region = -1
		g.title_menu.map_focus = -1
		g.return_to_lobby("map")
		await _shot("map")
		g.title_menu.prepare_sector(11)
		await _shot("mission")
		g.title_menu._open_shop(11)
		await _shot("equipment")
		g.set_language(1)
		g.text_size_index = 1
		g.title_menu._draw_page()
		await _shot("equipment-zh")
		g.title_menu.map_region = 7
		g.title_menu.map_focus = -1
		g.return_to_lobby("map")
		await _shot("root")
		g.campaign.records = all_records
	await _test_menu_flow()
	print("Attacks: ", seen_attacks.keys(), " | Activated rules: ", used_rules.keys(), " | Returned rules: ", returned_rules.keys())
	print("Smoke result: ", failed, " failures")
	quit(1 if failed else 0)

func _test_recording_assets() -> void:
	var clips := ["move", "strike", "dodge", "steal", "rule"]
	for lesson in g.Levels.LESSONS.size():
		clips.append("context-%02d" % lesson)
	for clip: String in clips:
		for sheet in 4:
			var path := "res://assets/demos/%s-%d.webp" % [clip, sheet]
			var texture := ResourceLoader.load(path) as Texture2D
			_check(texture != null and texture.get_size() == Vector2(1920, 1800), "Each recording must have four full-frame sheets: " + path)
		await process_frame

func _test_menu_flow() -> void:
	g.campaign = Campaign.new()
	g.return_to_lobby()
	g.title_menu._prepare_from_lobby(0)
	_check(g.title_menu.page == "mission", "Starting an operation opens the mission briefing first.")
	g.title_menu._open_shop(0)
	g.title_menu.back()
	_check(g.mode == "title" and g.title_menu.page == "mission", "Leaving the optional shop returns to the selected mission.")
	g.title_menu._start_selected()
	_check(g.title_menu.page == "new_lesson" and g.title_menu.active_lesson == 0, "A mechanic is introduced before the first deployment.")
	_check(g.title_menu.next_step_button.disabled, "Continue waits for the first playback.")
	_check(g.title_menu.preview.get_rect() == g.title_menu.GUIDE_FRAME, "A full-frame recording must have its own unobstructed 16:9 area.")
	g.title_menu._process(g.title_menu.demo_duration())
	_check(not g.title_menu.next_step_button.disabled, "Finishing the demo unlocks deployment.")
	g.title_menu._acknowledge_lesson()
	_check(g.mode == "fight" and g.sector_index == 0, "Deploy launches the known sector without a second confirmation.")
	if capture:
		g.title_menu.sync_mode()
		await _shot("combat-ui")
	_play_route()
	_check(g.mode == "clear" and g.campaign.records.size() == 1, "The new entry path still records the sector clear.")
	if capture:
		g.title_menu.sync_mode()
		await _shot("debrief-ui")
	g.title_menu._retry_from_results()
	_check(g.mode == "fight" and g.sector_index == 0 and g.replay, "Retry launches a replay directly.")
	_play_route()
	g.continue_after_clear()
	_check(g.mode == "title" and g.title_menu.page == "mission" and g.title_menu.sector_pending == 1, "Next links straight to the new mission briefing.")
	g.return_to_lobby("map")
	g.title_menu.map_focus = 1
	g.title_menu._focus_sector(1)
	_check(g.title_menu.page == "map", "Clicking the selected map node does not deploy the mission.")

func _test_save() -> void:
	var reached: int = g.campaign.records.size()
	var rule: int = g.campaign.next_rule
	var hull: int = g.campaign.next_hull
	var path := "user://campaign-smoke-%s.cfg" % OS.get_process_id()
	g.save_path = path
	_check(g._save() == OK and g._save() == OK, "The real save can replace an existing file.")
	var loaded := ConfigFile.new()
	_check(loaded.load(path) == OK and loaded.get_value("operation", "clears", []).size() == reached, "The saved file retains every cleared sector.")
	var reloaded := Campaign.new()
	reloaded.load_from(loaded, g.Levels.TABLE.size())
	_check(reloaded.records.size() == reached and reloaded.next_rule == rule and reloaded.next_hull == hull and reloaded.coins == g.campaign.coins, "Reopening restores the frontier, loadout and coins.")
	g.begin_sector(0)
	_check(g.replay and g.stage == 0, "A cleared sector can be started again.")
	g.campaign.complete(0, g.checkpoint, {"seconds": 0.05, "hits": 0, "retries": 0}, 1, g.Rule.AEGIS)
	_check(g.campaign.records.size() == reached and g.campaign.next_rule == rule and g.campaign.next_hull == hull, "Replaying a sector cannot overwrite campaign progress.")
	g.save_path = ""
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".backup")

func _test_operation() -> void:
	g.return_to_lobby()
	g.campaign = Campaign.new()
	var route_types := {}
	for index in g.Levels.TABLE.size():
		_check(not g.campaign.selectable(index + 1, g.Levels.TABLE.size()), "Only the next stage is unlocked.")
		g.begin_sector(index)
		g.mode = "fight"
		if g.route.active():
			route_types[g.route.kind] = true
			_play_route()
		else:
			_check(g.boss_hp == roundi(float(g.ENCOUNTERS[g.stage].hp) * 1.35), "Boss health is scaled by 35 percent.")
			if index == 11:
				var before: int = g.boss_hp
				g.player_rule = g.Rule.AEGIS
				g.p = g.b - Vector2(60, 0)
				g._use_rule()
				g._check_hurt(Rect2(g.p - Vector2(22, 64), Vector2(44, 72)), g.b.x)
				_check(g.boss_hp < before and g.capacitor_power >= 3.0, "A close AEGIS reflection opens the Capacitor's longer window.")
				g.capacitor_power = 0.0
				g.player_rule = g.Rule.RUSH
				g.p.x = 934.0
				g.charge = true
				g._use_rule()
				_check(g.capacitor_power > 2.0 and g.capacitor_power < 3.0, "RUSH opens the Capacitor's short relay window.")
			if g.stage == 4:
				g._damage_boss(9)
				_check(g.boss_hp == g.boss_max_hp, "Mirror is shielded while echo locks remain.")
				for lock in g.boss_locks.duplicate():
					g.echo_target = lock.x
					g._set_state("exposed", 1.5)
					g.state_time = 0.59
					g._tick_fight(DT, 0.0, {}, false)
				_check(g.boss_locks.is_empty(), "Recorded strikes break the Mirror locks.")
			g._set_state("exposed", 1.5)
			g._damage_boss(g.boss_max_hp)
			if g.stage == 5:
				_check(g.evacuated and g.route.active() and g.mode == "fight", "Executor requires an evacuation after the core breaks.")
				_play_route()
		_check(g.mode in ["clear", "win"] and g.campaign.records.size() == index + 1, "Operation stage %02d clears and saves (x %.0f, y %.0f, checkpoint %d, clock %.1f)." % [index + 1, g.p.x, g.p.y, g.route.cursor, g.route.clock])
		if not g.mode in ["clear", "win"]:
			break
		_check(g.sector_result.coins == g.sector_result.stars * 1000, "Stars pay their actual run value.")
	_check(route_types.size() == 17 and g.Levels.TABLE.size() == 48, "All 17 route types and 48 sectors are exercised.")
	if g.campaign.records.is_empty():
		return
	g.begin_sector(0)
	g.mode = "fight"
	var previous: int = g.campaign.coins
	_play_route()
	_check(g.campaign.coins == previous + 3000, "Three-star replay pays 3000 even when the earlier best was three stars.")
	g._finish_arena()
	_check(g.campaign.coins == previous + 3000, "Settlement cannot be paid twice.")
	g.campaign.coins = 25000
	_check(g.buy_gear(0) and not g.buy_gear(0) and g.buy_gear(1) and g.buy_gear(2) and not g.buy_gear(3), "A loadout holds three distinct affordable purchases.")
	_check(g.campaign.coins == 6500, "Only successful purchases change the wallet.")
	g.begin_sector(0)
	_check(g.effects.size() == 3 and g.campaign.reserved.is_empty(), "Entry consumes the reserved gear and activates it.")
	g._tick_equipment(12.0)
	_check(g.effects.is_empty(), "Temporary gear expires.")
	var samples := 0
	var negatives := 0
	g.gear_rng.seed = 94
	for roll in 2000:
		g.drop.clear()
		g.drop_cooldown = 0.0
		g._roll_drop(g.p)
		if not g.drop.is_empty():
			samples += 1
			negatives += int(g.Gear.ITEMS[g.drop.id][3] == 0)
	_check(samples > 680 and samples < 840 and negatives > 140 and negatives < 230, "Drop and downside frequency broadly match the announced rates.")
	g.drop = {"id": 11, "at": g.p - Vector2(0, 21), "time": 6.0}
	g._tick_equipment(DT)
	_check(g.effects.has(11) and g.drop.is_empty(), "Nearby penalty is automatically equipped.")
	g._tick_equipment(5.1)
	_check(not g.effects.has(11), "Penalty expires after five seconds.")

func _play_route() -> void:
	var route: RefCounted = g.route
	for tick in 120 * 80:
		if g.mode != "fight":
			break
		var target: Vector2 = route.target()
		var aim := target
		var presses := {}
		var strike: bool = route.kind in ["break", "belt", "timer", "cargo", "combo"]
		if route.kind == "ferry" and not route.ridden:
			aim = Vector2(route.ferry.get_center().x, route.ferry.position.y)
		if route.kind == "key":
			if g.player_rule != route.required_rule:
				aim = route.socket
				if route.near(g.p, aim, 84.0):
					presses.steal = true
			elif route.near(g.p, target, 87, 55):
				presses.rule = true
		if route.kind == "evade" and fmod(route.clock, 2.6) >= 2.22 and fmod(route.clock, 2.6) < 2.25 and route.near(g.p, target, 72.0):
			aim = target + Vector2(105.0 if g.p.x <= target.x else -105.0, 0)
			presses.dodge = true
		if route.kind == "hold" and route.echo != Vector2.ZERO:
			aim.x += 101.0 if target.x < 990.0 else -101.0
		if route.kind in ["lift", "reflect"] and g.player_rule != route.socket_rule and route.cursor == 0:
			var required: int = g.Rule.LIFT if route.kind == "lift" else g.Rule.AEGIS
			if g.player_rule != required:
				aim = route.socket
				if route.near(g.p, aim, 88):
					presses.steal = true
		if route.kind == "cargo" and not route.attached:
			aim = route.cargo
		if route.kind == "timer" and route.cursor == 0 and route.timing < 1.5:
			aim = route.plate
		if route.kind == "swap" and route.near(g.p, target, 88):
			presses.steal = true
		if route.kind == "echo" and route.echo != Vector2.ZERO and route.near(route.echo, target, 68) and fmod(route.clock, 2.8) < 2.50:
			var escape := 85.0 if target.x < 985 else -85.0
			aim = target + Vector2(escape, 0.0)
		if route.kind == "reflect" and g.player_rule == g.Rule.AEGIS and fmod(route.clock, 2.8) >= 2.17 and fmod(route.clock, 2.8) < 2.26:
			presses.rule = true
		if route.kind == "lift" and g.player_rule == g.Rule.LIFT and g.charge and g.p.y > aim.y + 20.0 and absf(aim.x - g.p.x) < 180.0:
			presses.rule = true
		elif g.grounded and aim.y < g.p.y - 18.0 and absf(aim.x - g.p.x) < 151.0:
			presses.jump = true
		var hazard: Rect2 = route.hazard()
		if hazard.has_area() and hazard.grow(27).has_point(g.p - Vector2(0, 26)) and fmod(route.clock, 1.8) > 1.07:
			presses.jump = true
		var diff: float = aim.x - g.p.x
		var axis := signf(diff) if absf(diff) > 17 else 0.0
		g._tick_fight(DT, axis, presses, strike)

func _test_routes_and_overclock() -> void:
	g._new_run()
	g.stage = 1
	g._load_arena()
	g.mode = "fight"
	g.floor_broken = true
	g.p.x = 333.0
	g._set_state("idle", 60.0)
	for tick in 46:
		g._tick_fight(DT, 0.0, {}, false)
	_check(g.p.y == g.BASE and g.floor_y > g.BASE + 60.0, "The intact edge of the deck remains a usable high platform.")
	for tick in 74:
		g._tick_fight(DT, 1.0, {}, false)
	_check(g.p.x > g.DECK_LEFT and g.p.x < g.DECK_RIGHT and g.p.y == g.floor_y, "Walking off the platform gives access to the lower route.")

	g.stage = g.ENCOUNTERS.size() - 1
	g.player_rule = g.Rule.RUSH
	g._load_arena()
	g.mode = "fight"
	g.p.x = g.b.x - 120.0
	g._set_state("exposed", 1.7)
	g._try_shift()
	_check(g.boss_rule == g.Rule.RUSH and g.overclock_pending, "The Executor inherits and arms the old RUSH rule.")
	for tick in 300:
		g._tick_boss(DT)
		if g.rail_return:
			break
	_check(g.rail_return and g.state == "windup", "Inherited RUSH warns and charges back for a second sweep.")

func _pilot() -> Dictionary:
	var next := {}
	var diff: float = g.b.x - g.p.x
	var direction := signf(diff)
	var axis := direction if absf(diff) > 48.0 else 0.0
	var strike: bool = absf(diff) < 105.0
	if g.can_shift():
		next["steal"] = true
		strike = false
	elif g.state in ["exposed", "reboot"] and g.player_rule != g.Rule.EMPTY and g.charge:
		if g.player_rule == g.Rule.RUSH and absf(diff) < 265.0 and absf(diff) > 32.0:
			next["rule"] = true
			axis = direction
		elif g.player_rule == g.Rule.LIFT and absf(diff) < 97.0 and g.swing_cd < 0.05 and g.boss_hp > 5:
			next["rule"] = true
	if g.state == "windup":
		if g.move_name == "RAIL CUT":
			if g.state_time < 0.15 and g.grounded:
				next["jump"] = true
			if g.state_time < 0.22:
				axis = signf(g.attack_to - g.p.x)
		elif g.move_name == "SKY ANVIL":
			var flee: float = g.p.x - g.target_x
			if absf(flee) < 116.0:
				axis = signf(flee) if absf(flee) > 0.5 else (1.0 if g.p.x < 650 else -1.0)
			else:
				axis = 0.0
		elif g.move_name == "PULSE LATTICE":
			axis = _escape_columns()
		elif g.state_time < 0.10 and g.grounded:
			next["jump"] = true
		if g.state_time < 0.17 and g.player_rule == g.Rule.AEGIS and g.charge and absf(diff) < 396.0:
			next["rule"] = true
			axis = 0.0
	elif g.state == "active":
		if g.move_name == "RAIL CUT" and absf(diff) < 123.0 and g.p.y > g.floor_y - 54.0:
			next["dodge"] = true
		elif g.move_name == "SKY ANVIL":
			axis = 0.0
			if g.grounded:
				next["jump"] = true
		elif g.move_name == "PULSE LATTICE":
			axis = 0.0
	for hazard in g.hazards:
		var box: Rect2 = hazard.box
		var x := box.get_center().x
		if absf(hazard.v) > 1.0 and absf(x - g.p.x) < 125.0 and (g.p.x - x) * hazard.v > 0 and g.grounded:
			next["jump"] = true
	if g.grounded and g.state == "active" and g.move_name == "DEAD CIRCUIT" and absf(diff) < 56.0:
		next["dodge"] = true
	for warning in g.environmental_zones():
		var box: Rect2 = warning.box.grow(24.0)
		if not box.has_point(g.p - Vector2(0, 18)):
			continue
		if g.stage == 3:
			if g.grounded:
				next["jump"] = true
		elif g.stage in [2, 4] and not warning.live:
			axis = -1.0 if g.p.x < box.get_center().x else 1.0
			if g.stage == 4 and absf(g.p.x - g.echo_target) < 5.0:
				axis = 1.0 if g.p.x < 850.0 else -1.0
	return {"axis": axis, "pressed": next, "strike": strike}

func _escape_columns() -> float:
	for zone in g.zones:
		var box: Rect2 = zone.grow(19.0)
		if g.p.x > box.position.x and g.p.x < box.end.x:
			if box.position.x <= g.LEFT:
				return 1.0
			if box.end.x >= g.RIGHT:
				return -1.0
			return -1.0 if g.p.x < box.get_center().x else 1.0
	return 0.0

func _shot(label: String) -> void:
	captures[label] = true
	DirAccess.make_dir_recursive_absolute("res://builds/screens")
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png("res://builds/screens/" + label + ".png") == OK, "Screenshot write failed.")
