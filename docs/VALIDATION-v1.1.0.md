# v1.1.0 tutorial skip update — 2026-11-24

Godot 4.7.2 stable, Windows x64. Version remains 1.1.0 as requested.

## Implemented behavior

- Every basic and contextual recording has an immediately enabled Skip button.
- A sequence with subsequent lessons opens a modal with Skip current, Skip all this time and Keep watching. A single or final lesson skips immediately.
- The scope modal pauses playback. Cancel or Back restores the original playback position and preserves whether it was playing or manually paused.
- Skipping all first-time basic lessons starts the next playable campaign sector directly.
- Skipping contextual lessons advances the current queue without marking unwatched mechanics as watched. Skip all affects only this deployment. Archive replays return to the archive.
- All five UI languages and their bundled font subsets include the new text. English and Chinese play guides, itch listing copy and five-language release notes were updated.
- Preserved the pending smaller browser package, verified chunk loader and recovery UI from the source checkout.

## Completed verification

- Clean headless import with an isolated portable editor profile.
- `tests/smoke.gd`: 0 failures, including the existing six-boss/campaign/menu/save regressions.
- `tests/release.gd`: 0 failures, including six full boss runs across normal/assist modes and three seeds, plus all localized glyphs.
- `tests/guide_skip.gd`: 0 failures. Exercises actual button signals, current/all scopes, cancel and Back, paused playback, onboarding, deployment-only skipping, another deployment, last/single lessons, archive replays and five languages at 130% text.
- `tests/web_loader.cjs`: success, including retry and rejection of corrupt/missing chunks.
- Web and Windows release exports and ZIP packaging completed without script errors.
- Web package: all 61 chunks have correct lengths and SHA-256 hashes; reconstructed PCK/WASM match the original exported files.
- Exported Web PCK: Chinese skip dialog and direct gameplay after skip verified by a separate engine test. This verifies exported resources, not browser rendering.

## Publication status

The updated Web and Windows packages were uploaded in Chrome to the existing itch.io project on 2026-11-24 (Asia/Shanghai). Both uploads showed Success. The Web package is marked playable in browser, and Windows retains its Windows download designation. The public page shows the new skip-guide explanation and the 59 MB Windows download.

Hosted Chrome verification: the new HTML5 build loaded, showed the Simplified Chinese language screen and the guide with its Skip button. The scope dialog displayed Skip current, Keep watching and Skip all this time in Chinese. Gameplay in the first campaign sector was reached after leaving the guide. The current-only branch is covered by the automated signal tests; the live screenshot confirmed actual gameplay after skipping. Save reload, audio/fullscreen and further keyboard checks are not claimed.

GitHub's refreshed v1.1.0 release notes and Web, Windows and matching source ZIP assets were published through the signed-in Edge session on 2026-11-24. The two previous executable archives were retained with `-previous-20261123` in their names. Core source changes, localization and resource imports were also committed to main through GitHub's web upload interface because CLI networking was unavailable.

The existing v1.1.0 Git tag was retained at c096698; GitHub's automatic tag-based Source code archives therefore describe the original tag. Use the explicitly attached `shift-protocol-source-v1.1.0.zip` for the refreshed build's matching source, or the updated main branch. This distinction is stated in the release notes through the matching source attachment name.

## Published artifacts

- `builds/shift-protocol-web.zip` — HTML5 upload; mark as playable in browser.
- `builds/shift-protocol-windows-x64.zip` — Windows download.
- `docs/releases/v1.1.0.md` — GitHub release notes in five languages.
- `docs/ITCH.md` — updated itch.io listing text and embed configuration.

The packages and listing are uploaded and saved in Chrome, and the GitHub release is updated in Edge. Further hosted checks for save persistence and audio/fullscreen remain; they are not claimed by this record.
