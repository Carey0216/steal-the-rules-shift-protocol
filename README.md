<p align="center"><img src="assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL logo"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

![Version 1.1.0](https://img.shields.io/badge/version-1.1.0-4caa94) ![Godot 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf) ![Platform Windows and Web](https://img.shields.io/badge/platform-Windows%20%7C%20Web-30363d) [![MIT license](https://img.shields.io/badge/license-MIT-cc8850)](LICENSE)

**English** · [中文（简体）](docs/readme/zh-CN.md) · [中文（繁體）](docs/readme/zh-TW.md) · [日本語](docs/readme/ja.md) · [한국어](docs/readme/ko.md)

A 2D boss rush about stealing the rules of a fight. Built with Godot and GDScript for GitHub Game Off 2026.

## Features

| Feature | In the game |
| --- | --- |
| Shift exchange | Dodge an attack, approach the exposed core and press **Shift**. You gain the boss’s ability and hand it your previous rule. |
| Three bosses | Fight the Warden, the Lattice and the Executor. Steal LIFT in the second arena to bring down the floor. |
| Recorded guide | On first launch, pick a language and watch in-game recordings of movement, jumping, striking, dodging, stealing and using a rule. Open **?** on the title screen to watch them again. |
| Settings | Choose a language, display mode, window size and text size. Toggle audio, reduced motion or assist mode. Windows opens fullscreen on first launch and remembers your choice. The Web version opens inside its page and can enter fullscreen from Settings. |

![A gameplay recording displayed in the controls guide](docs/guide.png)

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

## Play and build

On Windows, extract the full archive and open `ShiftProtocol.exe` beside `ShiftProtocol.pck`. In a desktop browser, click the game to focus it. To build from source, open `project.godot` in standard Godot 4.7.2 and press F5. The build instructions cover export templates, tests and the Web and Windows ZIPs.

[Build instructions](docs/BUILD.md) · [Game Off 2026](https://itch.io/jam/game-off-2026)

## Credits and license

Created by Carey for GitHub Game Off 2026. OpenAI Codex assisted with design, GDScript, procedural visuals and sound, testing, and documentation. The game uses no runtime AI. Original project files use the MIT license. Barlow Condensed, Space Mono and the Shift Sans subsets of Noto Sans ship with their SIL Open Font License notices. Godot and its dependencies have separate notices.

[MIT](LICENSE) · [SIL OFL](assets/) · [Godot](docs/GODOT_COPYRIGHT.txt)
