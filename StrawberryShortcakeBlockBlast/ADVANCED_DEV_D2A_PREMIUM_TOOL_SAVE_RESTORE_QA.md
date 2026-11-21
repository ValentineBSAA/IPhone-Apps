# 🍓 D2a · Actual Premium-Tool Use, Safe Endless Save and Restore

**Status: draft source and six new regression tests. CI and physical iPhone approval pending.** Branch `feature/berry-advanced-dev-d2a-valid-tools-save-restore` builds on D1c, D1b and D1a without merging them into production.

**Baseline kept:** `com.valentinebsaa.berryblockblast`, iOS16, v0.5.16 / internal Build 46, all original artwork, 51 local songs, 16 sound effects, seven modes, existing owners/charges/prices and every Sweet Endless save. **No IPA, no version bump or merge.**

## Why D2a follows real checkout testing

D1a–D1c cover purchasing helpers, Cottage upgrades and premium supplies in disposable stores. **Buying an item is not the same as successfully using it on the board and restoring the modified garden after quitting.** D2a is intentionally limited to the next gap: real premium tool actions against actual seeded game boards, followed by independent 8/12/24 saved-board round trips.

## Implementation

- [x] `BerryGameSession.savedEndlessEngine(side:defaults:)` now accepts an injectable preferences store, defaulting to existing `.standard`. Production callers continue operating on their original preference keys, unchanged.
- [x] `selectMode(.endless)`, its selected board size, best-score lookups and existing 8x8 migration bookkeeping use `checkoutDefaults`. When called by production `BerryGameSession()`, this is the same standard store as before. An isolated instance can now **genuinely reopen its own saved Endless garden** without reading/writing the actual player's saved run.
- [x] `BerryPremiumToolSaveRestoreTests.swift` has six cases, using an actual BerryEngine with a completed legitimate placement (`moves > 0`), actual `BerryGameSession` premium-use methods, actual injected preferences/ledger and real Codable read-back. No fake instant progression grants.
- [x] Valid **Golden Trowel** removes one occupied cell, charges one, persists its board and restarts with the cleared cell.
- [x] Valid **Starberry Seed** fills an empty cell, charges one, saves extra move and reopens with matching board.
- [x] Valid **Golden Strawberry** removes occupied cells, preserves score, marks the one-per-run rescue limit, saves and reopens without allowing a second rescue.
- [x] Invalid Trowel/Seed targets reject with no spending or save modification.
- [x] Valid 24×24 Trowel only updates 24×24, leaving both 8×8 and 12×12 saved byte blobs intact.
- [x] Isolated gameplay setup/select/save/reopen verifies **normal player wallet, premium charges, best-score, board size and 8/12/24 keys unchanged**.

## Automated gate

- [ ] [D2a Actions on named iPhone 16e](https://github.com/ValentineBSAA/IPhone-Apps/actions/workflows/berry-d2a-tool-use-restore-iphone16e.yml): selects **86 XCTest methods** (80 previous D0–D1c + six D2a); Release compile must exclude QA UI. Preflight checks iOS16, artwork and audio source, and workflow explicitly produces **no IPA**.
- [ ] Verify actual final CI conclusion and XCTest log with exact counts. Never infer pass just because the source exists or the job started.
- [ ] Physical owner iPhone 16e: explicitly approved future candidate only. Run selected actual premium tools on a saved Sweet Endless board, force-close/reopen and verify score, board, tool count and 8/12/24 other saves. Full accessibility and UI acceptance separate.
- [ ] D2b can add an internal two-column **Tool Action Lab** with deterministic one-tap valid Trowel/Seed/Golden Strawberry and bad-target fixtures after D2a passes. Reuse the real injection, never actual player saves.
- [ ] Extend positive-use coverage to Twister, Picnic Pantry and 24×24 Golden rescue, plus rescue/game-over and Story/Daily rules, only when verified. No fake full game coverage.

## Important limitations

- Purchase/write and premium-use/inventory/save currently update multiple UserDefaults keys. They are **not guaranteed crash-atomic** or durable against sudden power loss.
- The tests intentionally use valid seed boards and game method calls, not the full production SwiftUI finger-drag/tap workflow. Do not claim physical in-game interaction is verified.
- Story and Daily still have singleton state and should **not** be called in these isolated fixtures until their persistence is injected and audited.
- D1b/D1c were re-run for their corrected canonical sorted-key JSON test assertion; their terminal results must be independently reviewed before D2a can be accepted as a cumulative baseline.
