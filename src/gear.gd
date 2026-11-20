extends RefCounted

const DROP_CHANCE := 0.38
const DROP_LIFETIME := 6.0
const MAX_COINS := 999999999
const MAX_LOADOUT := 3
const ITEMS := [
	["Edge Oil", "Damage ×1.5", 8.0, 6000, 0, "DMG"],
	["Runner Mesh", "Run speed ×1.2", 9.0, 6000, 0, "RUN"],
	["Slip Bearing", "Dodge recovery ×0.68", 8.0, 6500, 1, "EV"],
	["Spring Soles", "Jump strength ×1.2", 8.0, 6500, 3, "UP"],
	["Quick Coil", "Strike recovery ×0.72", 8.0, 7500, 5, "ATK"],
	["Wide Arc", "Strike reach ×1.35", 8.0, 7500, 7, "ARC"],
	["Impact Liner", "Blocks one hit", 9.0, 8500, 9, "HP"],
	["Guard Prism", "Dodge protection +0.14 s", 8.0, 9000, 11, "IF"],
	["Auxiliary Cell", "Rule abilities recharge after 2 s", 9.0, 10500, 14, "E"],
	["Breach Catalyst", "Damage ×1.8; run speed ×0.85", 7.0, 12000, 17, "MAX"],
	["Blunt Relay", "Damage ×0.65", 5.0, 0, 0, "DMG"],
	["Magnetic Drag", "Run speed ×0.70", 5.0, 0, 0, "RUN"],
	["Sticky Joint", "Dodge recovery ×1.5", 5.0, 0, 1, "EV"],
	["Heavy Soles", "Jump strength ×0.78", 5.0, 0, 3, "UP"],
	["Rust Link", "Strike recovery ×1.4", 5.0, 0, 5, "ATK"],
	["Cracked Optic", "Strike reach ×0.75", 5.0, 0, 7, "ARC"],
	["Hull Patch", "Repairs one hull after 4 s", 8.0, 8500, 12, "FIX"],
	["Grounding Mat", "Blocks live floor and vent damage", 8.0, 10000, 19, "ISO"],
	["Feedback Loop", "Rule use locked while active", 5.0, 0, 11, "LOCK"],
	["Brake Teeth", "Dodge distance ×0.7", 5.0, 0, 15, "BRAKE"],
	["Pursuit Spur", "After dodging, the next strike deals +2 damage", 9.0, 9500, 5, "CHASE"],
	["Echo Prism", "A close reflection sends a second 5-damage pulse", 9.0, 11000, 10, "ECHO"],
	["Exchange Drive", "A rule swap primes a counterstrike and cools faster", 8.0, 11500, 16, "SHIFT"],
]

static func stock(progress: int, paid: bool) -> Array[int]:
	var result: Array[int] = []
	for i in ITEMS.size():
		if (ITEMS[i][3] > 0) == paid and ITEMS[i][4] <= progress:
			result.append(i)
	return result
