extends SceneTree
## Run with Godot --headless --path . --script tests/smoke.gd
## The pilot below sends standard combat inputs through the fixed-step simulation.

const GAME = preload("res://main.tscn")
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
	root.add_child(g)
	g.set_physics_process(false)
	g.audio_rig.set_mute(true)
	g.save_path = ""
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
	g._new_run()
	g._physics_process(DT)
	_check(g.mode == "brief" and g.stage == 0, "Run starts at first sector briefing.")
	g.just["confirm"] = true
	g._physics_process(DT)
	_check(g.mode == "fight", "Confirm starts combat.")
	g._try_shift()
	_check(g.player_rule == g.Rule.EMPTY and g.boss_hp == 36, "Cannot steal from a sealed core.")

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

	for sector in 3:
		var previous_rule: int = g.player_rule
		for i in 120 * 75:
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
		var desired := "win" if sector == 2 else "clear"
		print("Sector ", sector + 1, ": ", g.mode, ", boss HP ", g.boss_hp, ", player HP ", g.hp, ", ", g.steals, " transfers.")
		_check(g.mode == desired, "Pilot must clear sector %s within 75 seconds." % (sector + 1))
		if g.mode != desired:
			break
		if sector < 2:
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
	print("Attacks: ", seen_attacks.keys(), " | Activated rules: ", used_rules.keys(), " | Returned rules: ", returned_rules.keys())
	print("Smoke result: ", failed, " failures")
	quit(1 if failed else 0)

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
