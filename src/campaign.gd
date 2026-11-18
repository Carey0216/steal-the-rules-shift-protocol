extends RefCounted
## The unlocked frontier and each cleared sector's entry loadout survive a game restart.

const Gear = preload("res://src/gear.gd")
const Levels = preload("res://src/levels.gd")

var records: Array[Dictionary] = []
var next_hull := 7
var next_rule := 0
var coins := 0
var reserved: Array[int] = []
var lessons: Array[int] = []

func load_from(config: ConfigFile, sector_count: int) -> void:
	records.clear()
	var saved: Variant = config.get_value("operation", "clears", [])
	if saved is Array:
		for item in saved:
			if records.size() >= sector_count or not item is Dictionary:
				break
			records.append({
				"entry_hp": clampi(int(item.get("entry_hp", 7)), 1, 7),
				"entry_rule": clampi(int(item.get("entry_rule", 0)), 0, 3),
				"seconds": maxf(0.0, float(item.get("seconds", 0.0))),
				"hits": maxi(0, int(item.get("hits", 0))),
				"retries": maxi(0, int(item.get("retries", 0))),
				"stars": clampi(int(item.get("stars", 1)), 1, 3),
			})
	next_hull = clampi(config.get_value("operation", "next_hull", 7), 1, 7)
	next_rule = clampi(config.get_value("operation", "next_rule", 0), 0, 3)
	coins = clampi(config.get_value("operation", "coins", 0), 0, Gear.MAX_COINS)
	reserved.clear()
	lessons.clear()
	for id in config.get_value("operation", "reserved", []):
		if id is int and id >= 0 and id < Gear.ITEMS.size() and Gear.ITEMS[id][3] > 0 and id not in reserved and reserved.size() < Gear.MAX_LOADOUT:
			reserved.append(id)
	for id in config.get_value("operation", "lessons", []):
		if id is int and id >= 0 and id < Levels.LESSONS.size() and id not in lessons:
			lessons.append(id)

func write_to(config: ConfigFile) -> void:
	config.set_value("operation", "clears", records)
	config.set_value("operation", "next_hull", next_hull)
	config.set_value("operation", "next_rule", next_rule)
	config.set_value("operation", "coins", coins)
	config.set_value("operation", "reserved", reserved)
	config.set_value("operation", "lessons", lessons)

func selectable(index: int, sector_count: int) -> bool:
	return index >= 0 and index < sector_count and index <= records.size()

func entry(index: int) -> Dictionary:
	if index < records.size():
		return {"hp": records[index].entry_hp, "rule": records[index].entry_rule}
	return {"hp": next_hull, "rule": next_rule}

func complete(index: int, entry_stats: Dictionary, result: Dictionary, hull: int, rule: int) -> void:
	if index == records.size():
		records.append({
			"entry_hp": entry_stats.hp,
			"entry_rule": entry_stats.rule,
			"seconds": result.seconds,
			"hits": result.hits,
			"retries": result.retries,
			"stars": result.get("stars", 1),
		})
		next_hull = mini(7, hull + 3)
		next_rule = rule
	elif index < records.size():
		var best := records[index]
		var stars: int = result.get("stars", 1)
		if stars > best.stars or (stars == best.stars and result.seconds < best.seconds):
			for key in ["seconds", "hits", "retries"]:
				best[key] = result[key]
			best.stars = stars
