# Build and submission

Install **Godot 4.7.2 (standard, not .NET)**, open `project.godot`, and run the main scene with **F6** if `main.tscn` is open or **F5** from anywhere. The project uses Compatibility rendering. Install **matching export templates** from Editor → Manage Export Templates before exporting.

```text
godot --headless --path . --import
godot --headless --path . --script tests/smoke.gd
```

On Windows, use the Godot console executable for command output. To build and package both targets:

```powershell
./tools/build.ps1 -Godot 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe'
```

The script tests and packages both platforms in a staging folder. It exports the game into the Windows `runtime` directory and uses the Windows .NET Framework C# compiler to make the `ShiftProtocol.exe` launcher. After both ZIPs are ready, it replaces the previous exports and ZIPs under `builds/`. The launcher temporarily disables the five-Shift shortcut only while the game is the active Windows window and Sticky Keys is off. It restores the shortcut on focus loss and exit.

Serve the Web build over HTTP, rather than double-clicking the HTML:

```text
python -m http.server 8060 --bind 127.0.0.1 --directory builds/web
```

Open `http://127.0.0.1:8060/` in a desktop browser with WebGL 2. The Web preset uses a single thread and does not need cross-origin isolation. Browser audio may need a click or keypress before playback.

## itch.io

1. Create an HTML project titled **STEAL THE RULES: SHIFT PROTOCOL**. Upload `shift-protocol-web.zip` as “This file will be played in the browser.” Keep `index.html` at the ZIP root. Use a 1152 × 648 embed with fullscreen enabled.
2. Add `shift-protocol-windows-x64.zip` as an optional Windows download. Use the gameplay screenshot and listing copy in this directory.
3. Include the public GitHub repository URL. Mark AI usage and paste the disclosure from the README where requested.
4. Play the uploaded page, then submit the project through the [Game Off 2026 jam page](https://itch.io/jam/game-off-2026). Jam deadline: **2026-12-01 13:37 PST / 2026-12-02 05:37 China Standard Time**. See the [official FAQ](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq).

## Before submitting

On the hosted page, verify first launch in a fresh browser profile. Complete the five guide steps and try a practice arena. Start the first sector, confirm its new-mechanic recording plays, and clear it. Replay a sector and check its payout. Reload and verify the wallet, map and bought loadout. Check the Windows fullscreen startup and the save-and-quit button.

## Publish a tagged release

Set the version in `project.godot` and add `docs/releases/vX.Y.Z.md`. Write complete notes in this order: English, 中文（简体）, 中文（繁體）, 日本語, 한국어. Separate the five sections with `---`. Commit and push the release, then build both targets. Run `./tools/release.ps1 -Tag vX.Y.Z -Commit HEAD -BuildDir builds -Latest`. The script checks the version and the language order, then publishes the tag and both ZIPs.

## Record the guide again

The capture script drives the playable game with keyboard and mouse inputs and checks the action succeeded. Use the graphical Godot binary with `--path . --windowed --resolution 1152x648 --script tools/record_demos.gd -- --all`, then `python tools/pack_demos.py --all` with Pillow installed. This creates all 29 recordings. For one mechanic use `-- --lesson=N`, then `python tools/pack_demos.py --lesson=N`. The capture verifies menus are hidden in arena takes and shown in the shop take. Intro playback lasts seven seconds, mechanics ten seconds, and the longer guardian sequence seventeen seconds. All frames remain 16:9.

For the five localized READMEs, run the graphical binary with `--path . --windowed --resolution 1152x648 --script tools/capture_readme.gd`. It captures the lobby, map, shop and an example tutorial in each locale under `builds/screens/readme`. Move the reviewed screenshots to the matching names in `docs/`. Keep the English files unsuffixed.
