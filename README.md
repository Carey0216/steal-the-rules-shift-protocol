<p align="center"><img src="assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL logo"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

<p align="center">
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases"><img alt="Versions and release notes" src="https://img.shields.io/badge/Versions-v1.5.0-398274?style=for-the-badge"></a>
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/latest/download/shift-protocol-windows-x64.zip"><img alt="Download Windows x64 ZIP" src="https://img.shields.io/badge/Download-Windows%20x64-3b5d88?style=for-the-badge"></a>
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/latest/download/shift-protocol-web.zip"><img alt="Download Web HTML5 ZIP" src="https://img.shields.io/badge/Download-Web%20HTML5-825874?style=for-the-badge"></a>
  <a href="#field-guide"><img alt="Field guide" src="https://img.shields.io/badge/Read-Field%20guide-795c35?style=for-the-badge"></a>
</p>

**English** · [中文（简体）](docs/readme/zh-CN.md) · [中文（繁體）](docs/readme/zh-TW.md) · [日本語](docs/readme/ja.md) · [한국어](docs/readme/ko.md)

A 2D boss rush about stealing the rules of a fight. Built with Godot and GDScript for GitHub Game Off 2026.

## Features

| Feature | In the game |
| --- | --- |
| Shift exchange | Dodge an attack, approach the exposed core and press **Shift**. You gain the boss’s ability and hand it your previous rule. |
| 48 sectors in eight regions | Ride moving ferries, break relays with combos, rewire gates, cross moving sensors, hold beacons and dodge to charge capacitors. Route layouts and five new boss encounters build on the original campaign. |
| Sector map and saves | A clear lights up the map and unlocks the next sector. Replay any cleared stage for a new rating and reward. Esc pauses. The gear menu offers save and quit or a confirmed progress reset. |
| Gameplay recordings | Five introductory clips have hands-on drills. When a mechanic first appears, the game plays its clip before entry. Open **?** for the archive and equipment index. |
| Equipment and coin shop | 20 temporary items with distinct icons. Earn 1,000–3,000 coins per clear and buy up to three distinct items before entry. Weakening items only drop in combat. |
| Settings | Choose a language, display mode, window size and text size. Toggle audio, reduced motion or assist mode. Windows opens fullscreen on first launch and remembers your choice. The Web version opens inside its page and can enter fullscreen from Settings. |

![The lobby on the overlook](docs/lobby.png)

The lobby resumes the next available sector. Open Settings with the gear icon, or the guide with **?**.

![The eight-region sector map](docs/map.png)

Choose a region on the left. Select a sector to read its goal before you deploy.

![The shop with six unlocked items](docs/equipment.png)

Each item states what it does, how long it lasts and what it costs.

![The moving ferry lesson with a full arena recording and its controls](docs/guide.png)

The left side shows the move in play. The right side explains the move and lists the key.

## Controls

| Action | Keyboard | Controller |
| --- | --- | --- |
| Start / continue | Enter | Start / A |
| Move | A/D or arrow keys | Left stick / D-pad |
| Jump | Space, W or ↑ | A |
| Strike (hold to repeat) | J or Z | X |
| Dodge | K or X | B |
| Steal / exchange | Shift or Q | Right bumper |
| Use the current rule | E or C | Y |
| Pause | Esc or P | Start |
| Retry current sector | R | Back / Select |

## Rules and recovery

**RUSH** delivers a forward dash strike. **LIFT** launches you into the air so you can pierce armor with a strike. **AEGIS** catches a hit and reflects damage if the boss is close. The rule recharges after the next boss attack or a successful transfer. Entering a sector restores up to three hull points. Retrying restores that sector’s starting state.

## Field guide

1. **Get into the game.** Extract the Windows x64 download and launch `ShiftProtocol.exe`. For Web HTML5, unzip to a web server and open `index.html`, or upload the ZIP to itch.io as a browser game. In the browser, click the game to give it keyboard focus.
2. **Make the first transfer.** Watch the warning, then press K to dodge as the attack arrives. Run toward the opened core until the HUD says it is in range. Press Shift, Q or the right bumper. The HUD shows both exchanged rules. Press E or Y to use yours and J or X to strike. If the transfer fails, wait for the next opening and get closer.
3. **Read the field.** Stand on the reflected-pulse marker and use AEGIS as the warning ends. For echo locks, stay by the lock until the target stops tracking, then leave. For cargo, press J near it and bring it through the checkpoints. The **?** archive replays each unlocked demonstration.
4. **Read equipment bubbles.** Eligible hits roll a 38% chance while no capsule is on the field and the short drop cooldown has passed. The ring lasts 6 seconds. Walk into mint bubbles for a bonus or avoid coral bubbles, which weaken a stat for 5 seconds. Equipped effects last 5–9 seconds. The combat HUD shows remaining time.
5. **Earn and spend coins.** A clear earns one star, with bonus stars for the listed time and hit thresholds. Each star pays 1,000 coins, including replays. Shop prices start at 6,000. Bought equipment is reserved for the next sector entry, and its timer starts when play begins. Use the cart in the lobby or shop during the pre-entry prompt. The equipment index lists effects, duration and price as they unlock.
6. **Resume or replay.** Clear results offer Retry, Lobby and Next sector. Esc pauses the run. Settings can erase progression and coins after confirmation, while keeping display, language and accessibility settings.

The guide plays a full-arena recording automatically. Pause or replay it, then use Try it to practice a basic move. Check the mission briefing for the checkpoint layout and the shop for the duration of each item.

## Play and build

On Windows, extract the full archive and double-click `ShiftProtocol.exe`. Keep the `runtime` folder beside the launcher. In a desktop browser, click the game to focus it. To build from source, open `project.godot` in standard Godot 4.7.2 and press F5. The build instructions cover export templates, tests and the Web and Windows ZIPs.

[Download a tagged release](https://github.com/Carey0216/steal-the-rules-shift-protocol/releases) · [Build instructions](docs/BUILD.md) · [Game Off 2026](https://itch.io/jam/game-off-2026)

## Credits and license

Created by Carey for GitHub Game Off 2026. OpenAI Codex assisted with design, GDScript, procedural visuals and sound, testing, and documentation. The game uses no runtime AI. Original project files use the MIT license. Barlow Condensed, Space Mono and the Shift Sans subsets of Noto Sans ship with their SIL Open Font License notices. Godot and its dependencies have separate notices.

[MIT](LICENSE) · [SIL OFL](assets/) · [Godot](docs/GODOT_COPYRIGHT.txt)
