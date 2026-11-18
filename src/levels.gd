extends RefCounted

const REGIONS := ["Infiltration Line", "Power Junction", "The Foundry", "Reflection Core", "Tidal Works", "Quiet Galleries", "Sky Reservoir", "Root Vault"]
const TINTS := [Color("#edb88d"), Color("#a8d7c1"), Color("#f5a18d"), Color("#d8c1ee"), Color("#85d1e2"), Color("#cfce93"), Color("#eabc8a"), Color("#e2abba")]
const LESSONS := [
	["Route markers", "Follow the exit beacon. Jump onto ledges when the beacon is above you."],
	["Breakable devices", "Get close and press J to strike the amber device. Tap K as a warning turns solid to dodge the sweep."],
	["Closing gates", "Touch the checkpoints in order before the countdown expires. A rule socket lets you borrow a shortcut."],
	["Lift sockets", "Stand near the glowing socket and press Shift or Q. Press E to lift off and land on the upper ledges."],
	["Reflect pulses", "Take AEGIS from the socket. Stay on the target while it flashes, then press E just before the flash closes to reflect its pulse."],
	["Exchange sockets", "Stand beside an illuminated socket and press Shift or Q to swap rules. The socket takes the rule you brought."],
	["Live circuits", "The striped floor warns before power comes on. Cross the dim gap, or press K just before crossing a live segment."],
	["Cargo relay", "Press J next to the cargo to connect it. Carry it through each checkpoint in order. Damage breaks your connection."],
	["Timed gates", "Step on the pressure plate to extend the timer. Reach the device and strike before its window closes."],
	["Echo locks", "Wait beside the lock until the target holds still. Step away before the pulse hits the recorded position."],
	["Core evacuation", "The Executor repeats a rule you gave it. After the core breaks, reach the beacon before the doors shut."],
	["Equipment drops", "Damage can knock loose a capsule. Move into its bubble to equip it automatically. Mint is a bonus; coral is a penalty."],
	["Penalty capsules", "Coral capsules weaken a stat for 5 seconds. Jump over one to avoid it, or wait for its ring to empty."],
	["Field supply", "Each clear pays 1,000 coins per star, including replays. Buy up to three different items before entry. Their timers start when the fight begins."],
	["Moving ferries", "Step onto the moving platform to ride it. Its deck carries you between the high beacons."],
	["Relay combos", "Get close and land three hits in quick succession. Watch the lit pips. A long pause resets the relay."],
	["Rule gates", "Take the rule shown at the gate from the matching socket. Move to the gate and use that rule with E."],
	["Sweep sensors", "Watch the beam move across the floor. Jump over it, or dodge through. Enter each station while the beam is clear."],
	["Emergency holds", "Stay inside the beacon to charge it. Leave the red strike marker and return before the beacon empties."],
	["Dodge capacitors", "Stand within the ring. When the marker flashes solid, dodge through the pulse to charge the capacitor."],
]

# The third and fourth columns tell the arena which objective and combat chassis to load.
# A point is a target's foot position; variant changes platform lanes, windows and trap placement.
const TABLE := [
	["Redline Entry", 0, "cross", 0, 0, 14.0, 0, [[425, 440], [653, 403], [1017, 488]]],
	["First Lock", 0, "break", 0, 1, 19.0, 0, [[495, 488], [810, 488]]],
	["Warden", 0, "boss", 0, -1, 46.0, 0, []],
	["Catch the Lift", 0, "chase", 0, 2, 19.0, 1, [[460, 421], [752, 488], [1021, 414]]],
	["Shaft Trial", 0, "lift", 1, 3, 20.0, 1, [[548, 356], [752, 282], [938, 337]]],
	["Lattice", 0, "boss", 1, -1, 50.0, 0, []],
	["Rebound Workshop", 1, "reflect", 2, 4, 22.0, 0, [[540, 488]]],
	["The Rule Seat", 1, "swap", 2, 5, 20.0, 1, [[516, 418], [861, 488]]],
	["Pulse Routing", 1, "reflect", 2, -1, 29.0, 1, [[427, 488], [824, 408]]],
	["Pressure Divide", 1, "live", 2, 6, 18.0, 2, [[507, 488], [761, 416], [1021, 488]]],
	["Recover the Cell", 1, "cargo", 2, 7, 29.0, 0, [[470, 488], [747, 423], [1019, 488]]],
	["Capacitor", 1, "boss", 2, -1, 58.0, 0, []],
	["First Heat", 2, "live", 3, -1, 20.0, 3, [[440, 409], [749, 488], [1021, 407]]],
	["Against the Belt", 2, "belt", 3, -1, 26.0, 2, [[433, 488], [699, 407], [1011, 488]]],
	["Press Key", 2, "timer", 3, 8, 22.0, 1, [[632, 398], [1000, 488]]],
	["Hot Handoff", 2, "cargo", 3, -1, 34.0, 2, [[477, 488], [696, 401], [1000, 488]]],
	["Slag Run", 2, "chase", 3, -1, 24.0, 3, [[433, 404], [707, 488], [1000, 419]]],
	["Furnace", 2, "boss", 3, -1, 62.0, 0, []],
	["Leave a Mark", 3, "echo", 4, 9, 23.0, 0, [[550, 488]]],
	["Glass Archive", 3, "echo", 4, -1, 31.0, 2, [[453, 488], [870, 406]]],
	["Crossfire", 3, "echo", 4, -1, 34.0, 3, [[434, 488], [644, 402], [958, 488]]],
	["Mirror", 3, "boss", 4, -1, 66.0, 0, []],
	["Contingency", 3, "swap", 5, -1, 26.0, 3, [[464, 488], [658, 488], [888, 488]]],
	["Executor", 3, "boss", 5, 10, 78.0, 0, []],
	["Tidal Crossing", 4, "ferry", 0, 14, 24.0, 0, [[472, 417], [754, 406], [1018, 488]]],
	["Pump Choir", 4, "combo", 1, 15, 26.0, 0, [[473, 488], [795, 488]]],
	["Caisson", 4, "boss", 0, -1, 48.0, 1, []],
	["Two-bank Junction", 4, "key", 2, 16, 28.0, 0, [[526, 488], [929, 488]]],
	["Silt Lift", 4, "ferry", 1, -1, 28.0, 2, [[457, 421], [757, 397], [976, 417]]],
	["Undertow", 4, "hold", 3, 18, 25.0, 0, [[500, 488], [884, 413]]],
	["Watchkeeper", 5, "sensor", 4, 17, 24.0, 0, [[482, 488], [749, 415], [1020, 488]]],
	["Hush Freight", 5, "cargo", 2, -1, 26.0, 1, [[482, 415], [713, 488], [1001, 405]]],
	["Cold Lens", 5, "boss", 4, -1, 68.0, 2, []],
	["Glass Dials", 5, "combo", 0, -1, 25.0, 2, [[458, 419], [685, 488], [901, 417]]],
	["Deadband", 5, "evade", 2, 19, 29.0, 0, [[503, 488], [841, 488]]],
	["Quiet Hours", 5, "sensor", 3, -1, 28.0, 2, [[438, 427], [648, 488], [834, 423], [1018, 488]]],
	["Ballast Run", 6, "chase", 0, -1, 23.0, 4, [[410, 410], [621, 488], [824, 403], [1022, 488]]],
	["Updraft Ferry", 6, "ferry", 1, -1, 30.0, 3, [[464, 419], [720, 392], [972, 415]]],
	["Cloudbreak", 6, "boss", 1, -1, 55.0, 3, []],
	["Storm Moorings", 6, "evade", 2, -1, 28.0, 2, [[484, 421], [728, 488], [965, 423]]],
	["Float Relay", 6, "key", 3, -1, 29.0, 1, [[477, 488], [735, 419], [988, 488]]],
	["Lightning Wells", 6, "hold", 3, -1, 34.0, 2, [[430, 418], [684, 488], [933, 418]]],
	["Ghost Circuit", 7, "key", 4, -1, 33.0, 2, [[476, 415], [721, 488], [981, 411]]],
	["Triple Interlock", 7, "echo", 4, -1, 31.0, 4, [[430, 488], [665, 412], [940, 488]]],
	["Backfeed", 7, "boss", 2, -1, 64.0, 3, []],
	["Redline Protocol", 7, "combo", 3, -1, 28.0, 3, [[419, 421], [647, 488], [874, 415]]],
	["Forty-second Stand", 7, "hold", 4, -1, 33.0, 3, [[421, 488], [644, 413], [825, 488], [1030, 416]]],
	["Root Warden", 7, "boss", 5, -1, 85.0, 4, []],
]

const GOALS := {
	"cross": "Reach the exit beacon.", "break": "Strike the lock devices.",
	"chase": "Reach each beacon before the gates close.", "lift": "Borrow LIFT and reach the high beacons.",
	"reflect": "Reflect each pulse with AEGIS.", "swap": "Exchange with every active socket.",
	"live": "Cross the live floor to the exit.", "cargo": "Connect the cargo with J and deliver it through the checkpoints.",
	"belt": "Cross the belts and strike each relay.", "timer": "Stand on the plate, then strike the timed latch.",
	"echo": "Lure the recorded strike onto each lock.", "boss": "Dodge the attack, steal from the exposed core, then strike.",
	"ferry": "Ride the ferry and reach each high beacon.", "combo": "Chain three strikes to break each relay.",
	"key": "Borrow the shown rule and activate the gate.", "sensor": "Cross the sensor beam and visit each station.",
	"hold": "Charge each beacon while avoiding the strikes.", "evade": "Dodge a pulse inside each ring.",
}

static func unlocked_lesson(id: int, progress: int) -> bool:
	if id in [11, 12]:
		return progress >= 1
	if id == 13:
		return progress >= 2
	for i in range(mini(progress + 1, TABLE.size())):
		if TABLE[i][4] == id:
			return true
	return false

static func lessons_at(index: int) -> Array[int]:
	var result: Array[int] = []
	if TABLE[index][4] >= 0:
		result.append(TABLE[index][4])
	if index == 1:
		result.append_array([11, 12])
	if index == 2:
		result.append(13)
	return result
