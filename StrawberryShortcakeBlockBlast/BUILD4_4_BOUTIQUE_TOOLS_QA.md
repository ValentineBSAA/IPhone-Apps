# 🍓 Berry Berry Blast • Build 4.4 STUDIO QA

**Source branch:** `feature/berry-build4-r5-boutique-tools-qa`
**App:** v0.5.14 • internal build **44** • iOS 16.0+
**Home:** `B4.4 STUDIO`
**Policy:** development test candidate; draft PR; no public release.
**Base:** Build 4.3 commit `413a4b5601bd72e3b4f4c7c422cafdb49563c467`, CI passed; owner physical **22/26**, four checks still open.

## Change scope

- [x] Show **Board Studio** again as an approved two-column Boutique category, while keeping retired Seasonal/untested surface artwork hidden.
- [x] In Board Studio offer two free board appearance cards: **Original Strawberry Jam** and **Strawberry Blossom Glass**, with thumbnail previews, Selected state and accessibility descriptions.
- [x] Use the existing `berryberryblast.board.surface.v059` preference in Boutique, Settings and gameplay. Do not touch the board hitboxes, user wallet, existing owned skins, saving or Blossom Glass exterior frame.
- [x] Special Tools: single sheet title, readable labels when disabled, explicit `Locked` / `0 left` / `Select a piece` / `Available when stuck` status. Invalid selections cannot trigger the tool action; keep its two-column grid.
- [x] Clarify in How to Play that Classic has no Undo/Shuffle/Hint or premium tools, while supported non-timed modes retain their existing helpers.
- [x] Preserve 51 M4A + 16 WAV audio files, darker raspberry tile, original cosmetic skins, scoring, gameplay, quests, economy, save keys, Night assets and existing iOS 16 compatibility.
- [x] Add automated policy tests for only two supported board surfaces, legacy preference round trip and wallet isolation, zero-charge/selected-piece/Golden rescue tools, and unchanged base helper prices.
- [x] CI concurrency scoped per ref, superseded runs canceled, scarce macOS simulators still serial.

## GitHub acceptance gates

- [ ] Ubuntu source/audio/art/image checks + Build44 preflight
- [ ] Swift engine regression
- [ ] iPhone 14 Pro named simulator full XCTest + screenshot evidence
- [ ] iPhone 16e named simulator full XCTest + screenshot evidence
- [ ] Native iOS device build, version 44 IPA integrity and artifact upload

## Physical owner QA for this focused release (0/12 until tested)

- [ ] Home shows `B4.4 STUDIO`; Settings internal build 44.
- [ ] Boutique grid shows **Board Studio**, while unwanted Seasonal content remains hidden.
- [ ] Board Studio shows **exactly the two approved options**, both with readable art previews and selected indicators.
- [ ] Select Blossom Glass inside Boutique; returning to gameplay changes only the board style; edge and corner placements remain accurate.
- [ ] Select Original Strawberry Jam inside Boutique; switching back leaves the existing saved run and score intact.
- [ ] Board selection in Settings and Boutique always matches, even after force-quit/reopen.
- [ ] Special Tools sheet has one title, its icons/names/descriptions remain readable even at 0 charges.
- [ ] Locked pantry, empty charges and missing selected piece show distinct statuses; invalid taps spend nothing.
- [ ] Classic How to Play explains intentionally limited helpers; other game modes' toolbars remain correct.
- [ ] Boutique block skins still equip/unequip and dark raspberry default returns.
- [ ] Existing Endless game, wallet, inventory and premium charges survive relaunch; no purchases/awards occur from cosmetic-only changes.
- [ ] iPhone 14 Pro real-device quick cross-check: 8×8, 12×12, Blossom Glass, save, and touch edges.

## Backlog deliberately deferred

- **Build 4.5:** rule/difficulty and strawberry economy diagnostics and evidence-backed tuning.
- **Build 4.6:** Night Edition visuals and local 12-hour clock, no new currency.
- **Build 5:** polish existing Daily Quests, Village, notification/celebration delivery.
- **Build 6:** real Moonberries and Night Market economy with durable separate ledger.
- **Build 4.3:** four still-open physical QA items remain owner-reportable on the historical checklist, not auto-approved by newer code.
