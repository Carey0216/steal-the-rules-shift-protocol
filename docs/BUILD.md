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

The script makes the Web and Windows exports from the committed presets, includes accompanying notices, and writes two ZIPs under `builds/`. Alternatively, export **Web** to `builds/web/index.html` and **Windows** to `builds/windows/ShiftProtocol.exe` from Project → Export after creating the output folders. Use the packaging script for distribution.

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

On the hosted page, verify the first transfer with both Shift and Q, finish all three sectors on at least one target, retry from sector two, toggle audio and reduced motion, and check the final stats screen. Test with the canvas embedded at its intended dimensions. The automated run checks the rules and all three encounters; it does not replace a first-time player trying the tutorial.
