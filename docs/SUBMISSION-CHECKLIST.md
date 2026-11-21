# Game Off 2026 — submission checklist

Candidate: **STEAL THE RULES: SHIFT PROTOCOL v1.7.0**. Prepared on 2026-11-21. Publishing remains a creator-confirmed step.

## Rules checked

- [x] Theme: **SHIFT**, expressed as two-way rule exchange, RUSH position exchange and campaign world-phase switching.
- [x] Official deadline: **December 1, 2026, 13:37 PST / December 2, 05:37 Asia/Shanghai**.
- [x] A public source repository exists: [Carey0216/steal-the-rules-shift-protocol](https://github.com/Carey0216/steal-the-rules-shift-protocol). Public repository metadata was checked during this sprint; this does not mean the new candidate is uploaded.
- [x] The project was developed during November; local history and existing source were retained.
- [x] AI assistance is permitted with disclosure. Prepared [AI disclosure](AI-DISCLOSURE.md) and [asset provenance](../assets/ART-NOTES.txt).

Official sources: [jam overview](https://itch.io/jam/game-off-2026) and [host FAQ](https://itch.io/jam/game-off-2026/topic/7290154/frequently-asked-questions-faq). Pushing to GitHub alone does not enter the jam. Most development should happen during the jam; the final eligibility determination belongs to the organizer.

## Build and quality

- [x] Godot 4.7.2 standard project, compatible renderer; matching export templates available.
- [x] Smoke suite: six-boss simulation, 48-sector progression/objective settlement, guides, saves, refunds, rules and equipment.
- [x] Release regressions: six complete protocol simulations in two difficulty settings; all three combat phases; damaged save recovery and failed purchase rollback; blocked counter preservation; focus pause and menu continuation.
- [x] Windows x64 and single-thread Web release ZIPs built. ZIP root and required runtime files verified.
- [x] Desktop browser startup, tutorial input, combat input, pause/retry and reload persistence checked locally. Native windows and layout checked. See [validation report](VALIDATION-v1.7.0.md) for the precise scope and limits.
- [x] Five-language instructions and current screenshots prepared. Readability checked at the normal and enlarged text settings.
- [x] License, fonts, Godot notices and AI disclosure included.

## Creator approval and online submission

- [ ] Confirm publication of the reviewed v1.7.0 source and release files to the existing public GitHub repository. Review the local source ZIP/diff first.
- [ ] Push the verified candidate commit and version tag; verify GitHub's source and download hashes match the supplied manifest. Do not use an older `latest` download as the v1.7.0 candidate.
- [ ] Log in to the intended itch.io creator account; join Game Off 2026 if necessary.
- [ ] Create/update the game listing using [ITCH.md](ITCH.md). Add the source URL and AI metadata/disclosure.
- [ ] Upload the Web ZIP as playable HTML, 1152 × 648, fullscreen enabled; upload Windows ZIP as optional download. Keep `index.html` at the Web ZIP root.
- [ ] Play the **hosted itch.io build** in a fresh profile. Check keyboard focus, audio unlock, pause, local save/reload, browser fullscreen and one complete protocol run. Local host checks do not replace this final hosted test.
- [ ] Obtain creator confirmation before making the listing public and pressing **Submit** on the jam page.
- [ ] Verify the entry appears among the jam submissions and record its game URL and jam entry URL.

No new release was publicly published and no jam entry was submitted by this sprint. Game quality and award outcomes cannot be guaranteed.
