# v1.7.0 validation record

Date: **2026-11-21**, Asia/Shanghai. Engine: **Godot 4.7.2 standard**, Compatibility renderer. Windows host: NVIDIA GeForce RTX 5060 Laptop GPU, OpenGL 3.3. Existing 1.6.0 source was clean before changes; base commit `c085b0d` was retained.

## Automated checks

`tests/smoke.gd`: **0 failures**. It pilots the six original boss chassis using fixed-step combat inputs, activates and returns all three rules, checks the Lattice deck break, loss/retry/pause, five-language menus, guides, saves, replay settlement, purchase/refund, equipment and 48-sector progression/objectives. Some campaign objective and special-core checks use controlled positioning/state and direct damage; this is not a claim that an unaided player or bot played all 48 sectors end to end.

`tests/release.gd`: **0 failures**. It runs the complete six-boss protocol route in normal and assist modes three times each, using real movement, jump, dodge, exchange, strike and ability inputs in the 120 Hz simulation. Normal pilot: 01:19.15, 25 transfers; assist pilot: 01:11.71, 27 transfers. These are deterministic machine-pilot results, not expected human completion times. All three phases occur. The suite also covers blocked-counter preservation and one-time consumption, protocol menu/start/next/retry, campaign isolation, focus pause, malformed values, corrupt-primary backup recovery, preserving the good backup and purchase rollback after save failure. Every translated glyph is checked against its bundled font.

The build script stops on nonzero engine exits **and** reported script errors, since some Godot script errors can otherwise return exit 0. Both Web and Windows release exports and packaging pass. The final build log reports 0 smoke and 0 release failures. A Windows virtual-keyboard regression also verifies logical Escape when an injected event incorrectly reports the Pause scan code; such events are corrected without adding alternate physical key bindings.

One headless import attempt crashed while reimporting the four regenerated fonts. A separate reimport completed; the subsequent complete build and tests passed. No game runtime crash was observed. If a fresh source import fails, rerun import before exporting and keep the failing log for investigation.

## Visual and interactive checks

Fresh isolated Windows profile: language selection, all five lesson pages and completion into the lobby. The normal player's save was not used for test fixture resets.

Local Edge Web build: first load, Chinese language/guide, tutorial playback, real strike drill, movement plus SHIFT theft drill, E ability drill and their completion screens; protocol briefing/start and Escape pause. The transfer visibly changes player to RUSH and boss to EMPTY. Follow-up checks cover pause/retry, reload persistence and the final rebuilt font display.

Native Windows release: actual packaged launcher and runtime startup, v1.7.0 lobby, challenge entry/pause and clean exit checked. A headless boot of the exported runtime also completes without script errors.

Captured actual renderer output for rule transfer, deck breach, Protocol III and the ending. Captured all five locales, normal and 130% text, for the new protocol briefing; existing lobby/map/shop/guide/settings screenshots were refreshed. Corrected compact lesson numbers and missing new Chinese glyphs during QA. The final glyph test covers all localized text rather than only the language names.

## Scope and remaining online checks

This verifies the local candidate, not an itch.io-hosted upload. Hosted keyboard focus, browser storage, audio unlock and fullscreen still need the final itch.io test after upload. A physical controller was not available for a complete playthrough; bindings and confirmation paths were checked in source/automated tests. Mobile/touch, macOS and Linux native builds are not claimed. Audio synthesis and trigger code are retained; no independent listening panel or player study was performed.

The public GitHub repository already exists. New source, tag and release assets have **not** been published by this sprint, and the game has **not** been entered in Game Off by this sprint. These are creator-confirmed external actions. See [submission checklist](SUBMISSION-CHECKLIST.md).

## Reproduction

```text
godot --headless --path . --import
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/release.gd
```

Run `tools/build.ps1` with the matching console executable and export templates. Use `tools/review.gd` for an isolated manual profile, `tools/capture_readme.gd` for five-language UI captures and `tools/capture_release.gd` for simulated-combat captures. Test/build tools and screenshots are excluded from playable exports.
