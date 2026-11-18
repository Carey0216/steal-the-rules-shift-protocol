extends RefCounted

const REGIONS := ["Infiltration Line", "Power Junction", "The Foundry", "Reflection Core"]
const TINTS := [Color("#e7a86f"), Color("#83ccb6"), Color("#f49274"), Color("#cfa9e2")]
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
]

# The third and fourth columns tell the arena which objective and combat chassis to load.
# A point is a target's foot position; variant changes platform lanes, windows and trap placement.
const TABLE := [
	["Redline Entry", 0, "cross", 0, 0, 14.0, 0, [[1000, 488]]],
	["First Lock", 0, "break", 0, 1, 19.0, 0, [[495, 488], [810, 488]]],
	["Warden", 0, "boss", 0, -1, 46.0, 0, []],
	["Catch the Lift", 0, "chase", 0, 2, 21.0, 1, [[443, 488], [720, 488], [1000, 488]]],
	["Shaft Trial", 0, "lift", 1, 3, 20.0, 1, [[619, 348], [924, 273]]],
	["Lattice", 0, "boss", 1, -1, 50.0, 0, []],
	["Rebound Workshop", 1, "reflect", 2, 4, 22.0, 0, [[540, 488]]],
	["The Rule Seat", 1, "swap", 2, 5, 20.0, 1, [[496, 488], [813, 488]]],
	["Pulse Routing", 1, "reflect", 2, -1, 29.0, 1, [[427, 488], [824, 408]]],
	["Pressure Divide", 1, "live", 2, 6, 18.0, 2, [[1021, 488]]],
	["Recover the Cell", 1, "cargo", 2, 7, 29.0, 0, [[493, 488], [742, 488], [999, 488]]],
	["Capacitor", 1, "boss", 2, -1, 58.0, 0, []],
	["First Heat", 2, "live", 3, -1, 20.0, 3, [[1021, 488]]],
	["Against the Belt", 2, "belt", 3, -1, 26.0, 2, [[433, 488], [765, 488], [1011, 488]]],
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
]

const GOALS := {
	"cross": "Reach the exit beacon.", "break": "Strike the lock devices.",
	"chase": "Reach each beacon before the gates close.", "lift": "Borrow LIFT and reach the high beacons.",
	"reflect": "Reflect each pulse with AEGIS.", "swap": "Exchange with every active socket.",
	"live": "Cross the live floor to the exit.", "cargo": "Connect the cargo with J and deliver it through the checkpoints.",
	"belt": "Cross the belts and strike each relay.", "timer": "Stand on the plate, then strike the timed latch.",
	"echo": "Lure the recorded strike onto each lock.", "boss": "Dodge the attack, steal from the exposed core, then strike.",
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
