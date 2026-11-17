extends RefCounted
## The unlocked frontier and each cleared sector's entry loadout survive a game restart.

var records: Array[Dictionary] = []
var next_hull := 7
var next_rule := 0

func load_from(config: ConfigFile, sector_count: int) -> void:
	records.clear()
	var saved: Variant = config.get_value("campaign", "clears", [])
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
			})
	next_hull = clampi(config.get_value("campaign", "next_hull", 7), 1, 7)
	next_rule = clampi(config.get_value("campaign", "next_rule", 0), 0, 3)

func write_to(config: ConfigFile) -> void:
	config.set_value("campaign", "clears", records)
	config.set_value("campaign", "next_hull", next_hull)
	config.set_value("campaign", "next_rule", next_rule)

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
		})
		next_hull = mini(7, hull + 3)
		next_rule = rule
	elif index < records.size() and result.seconds < records[index].seconds:
		records[index].merge(result, true)
