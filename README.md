<p align="center"><img src="assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL logo"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

<p align="center">
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases"><img alt="Versions and release notes" src="https://img.shields.io/badge/Versions-v1.1.0-398274?style=for-the-badge"></a>
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/latest/download/shift-protocol-windows-x64.zip"><img alt="Download Windows x64 ZIP" src="https://img.shields.io/badge/Download-Windows%20x64-3b5d88?style=for-the-badge"></a>
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/latest/download/shift-protocol-web.zip"><img alt="Download Web HTML5 ZIP" src="https://img.shields.io/badge/Download-Web%20HTML5-825874?style=for-the-badge"></a>
  <a href="#field-guide"><img alt="Field guide" src="https://img.shields.io/badge/Read-Field%20guide-795c35?style=for-the-badge"></a>
</p>

<p align="center">
  <strong>English</strong> · <a href="docs/readme/zh-CN.md">中文（简体）</a> · <a href="docs/readme/zh-TW.md">中文（繁體）</a> · <a href="docs/readme/ja.md">日本語</a> · <a href="docs/readme/ko.md">한국어</a>
</p>

A 2D boss rush about stealing the rules of a fight. Built with Godot and GDScript for GitHub Game Off 2026.

## Features

| | |
| --- | --- |
| Six-boss Protocol run | Three phases per boss, carried rules, hull repair and retries from the current fight. |
| 48 sectors, 8 regions | 19 route types, 14 boss encounter sectors and 13 routes with a guardian interception. Every region ends in a boss. |
| Three meanings of Shift | Trade your rule with the enemy, exchange positions with anchors and switch the solid platforms between two world phases. |
| Perfect dodge | Dodge just before impact to prime one strike with +4 damage. Use it within two seconds. Ordinary dodges keep their normal protection. |
| Reversible loadouts | 23 short-lived items. Buy up to three different items. Click a reserved item or its Remove button for a full refund before deployment. Penalties only drop in combat. |
| Guides and settings | 29 real gameplay clips, drills, persistent remapping, separate master/music/effects levels and screen shake strength. The lower-left HUD lists every action and its current key. |

![Continue the next operation or open the map, shop, archive and settings.](docs/lobby.png)

Continue the next operation or open the map, shop, archive and settings.

![Pick a region, then a sector. Read the goal before deployment.](docs/map.png)

Pick a region, then a sector. Read the goal before deployment.

![Every item has a visible effect duration. Reserved slots on the right can be clicked to refund.](docs/equipment.png)

Every item has a visible effect duration. Reserved slots on the right can be clicked to refund.

![World-phase lesson: watch the real gameplay on the left, read the instruction and key on the right.](docs/guide.png)

World-phase lesson: watch the real gameplay on the left, read the instruction and key on the right.

## Controls

| Action | Default keyboard key | Controller |
| --- | --- | --- |
| Menu confirmation | Enter | A |
| Move left | A | ← Stick |
| Move right | D | Stick → |
| Jump | Space | A |
| Strike (hold to repeat) | J | X |
| Dodge | K | B |
| Shift / exchange | Shift | RB |
| Use the current rule | E | Y |
| Pause | Esc | Start |
| Retry | R | Back |

## Shift changes the fight

Taking **RUSH** exchanges the player and boss positions and turns you to face the enemy. Taking **LIFT** grounds the boss; the Lattice deck breaks open. Taking **AEGIS** strips armor for a short damage window. The enemy receives your old rule and uses it for its next attack. Preview both rule icons before you swap.

## Protocol run

Choose **Protocol run** in the lobby for six consecutive bosses. Your rule carries into the next fight, each clear repairs up to three hull, and retry restarts the current boss. The final screen shows time, transfers and retries.

Bosses change phase at **67%** and **34%** health. Later phases add return charges, double shockwaves and wider pulse patterns. The separate **48-sector operation** keeps its saved map progress, stars, wallet and equipment.

## Field guide

1. Extract the Windows ZIP and launch **ShiftProtocol.exe**, leaving its runtime folder in place. First launch is fullscreen. Choose your language, watch the five basic lessons and use **Try it** to practice. **Skip** is available immediately: choose the current lesson or all remaining lessons when a sequence follows. Skipping the first-time guide starts a playable sector. Campaign skips affect this deployment only; clips remain in the Field archive.

2. Watch the red windup. Dodge or leave its marked zone, approach the opened core, then press **Shift**. Press **E** to use the stolen rule. The bar shows when dodge is ready.

3. For a perfect dodge, press **K** just before contact. The gold ring and cue confirm a counter. Your next successful strike receives the bonus once, for two seconds.

4. Phase routes show **I / II**. Shift activates the matching platforms. Anchor routes show a large range ring: enter it and Shift to trade places with the anchor. New mechanics play their lesson automatically and remain in **?**.

5. A route can end with a guardian. Finish the checkpoints, then defeat it to clear. A replay pays 1,000 coins per star. Buy gear from the cart; click any reserved slot to return its full price before entry. Purchased effects last 7–9 seconds and start with combat.

6. Open the gear icon for settings. Keyboard has one key per action; choosing an occupied key swaps the two bindings. The HUD follows your choice. Adjust audio channels and screen shake separately. Esc pauses; Save and quit writes local progress.

## MONEY — experimental coin editor

For trying different equipment without replaying sectors for coins.

1. In the lobby, click the coin balance **five times within 2.4 seconds**.
2. Enter **MONEY** and confirm.
3. When the amount prompt appears, enter an integer from **0 to 999999999** and confirm.

This sets the saved coin balance. It does not unlock sectors or change stars. The entry stays hidden in the game.
