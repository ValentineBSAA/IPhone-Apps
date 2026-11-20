# 🍓 Berry Berry Blast Build 4.5 FAIR PLAY LAB • QA

**Build:** Berry Berry Blast v0.5.15 • internal 45 • B4.5 FAIR PLAY • iOS 16.0+
**Parent source:** Build 4.4 commit 14579caff8d15e6d5c69380297ea7cb77a414a45
**Build 4.4 owner QA:** 11/12 passed. Real iPhone 14 Pro item 12 still open; simulator coverage is not hardware signoff.
**No public release, merge or signed IPA authorized.**

## Source/CI gates
- [x] Existing 4.4 gameplay, Board Studio, Blossom border, approved cosmetics, 51 M4A and 16 WAV files retained.
- [x] QA-only deterministic initializer for all board sizes; original gameplay constructors and persisted saves remain.
- [x] Synthetic 2,030 seeded games across 9 mode/size profiles; JSON evidence contains legal/blocked trays, moves, clear rates, line-earnings estimates, stalls and free recoveries. Not human telemetry.
- [x] Read-only Developer Garden Diagnostics mode-policy grid and Economy Inspector observed-ledger tiles. No purchases/rewards/mode changes.
- [x] No changes to strawberry prices, one-time awards, wallet keys or Moonberry/night features.
- [x] Regression XCTest, preflight and JSON report validator added.
- [ ] GitHub integrity and deterministic Swift engine gates PASS.
- [ ] iPhone 14 Pro and iPhone 16e **named simulator** XCTest/screenshot gates PASS.
- [ ] Native unsigned v0.5.15 / 45 IPA fully compiled and uploaded.

## Owner changed-area physical iPhone checklist • 0/12 until tested
- [ ] 1. Update existing installation without uninstalling; saved score, wallet, helpers and charges remain.
- [ ] 2. Home says B4.5 FAIR PLAY and Settings/Developer Build Information shows internal 45.
- [ ] 3. Developer Garden → Diagnostics displays the old Touch Diagnostics toggle **and** a new 2-column seven-mode read-only rules grid.
- [ ] 4. Developer Garden → Economy Inspector displays recorded spending/line-earning statistics as 2-column tiles, explicitly not wallet balance and without buying or rewarding.
- [ ] 5. Classic remains pure puzzle; Endless/Story/Cozy/Blitz/Nightmare have their expected helper rules.
- [ ] 6. 8×8 and 12×12 playable borders/corners align; Blossom Glass remains only outside the board.
- [ ] 7. Board Studio changes Original ↔ Blossom without changing currency or score; favorite skins and original dark raspberry remain.
- [ ] 8. Invalid tools don't consume charges; real purchases still have their original costs.
- [ ] 9. Force-quit/relaunch retains board choice, current saved Endless session and purchased items.
- [ ] 10. Daily/Story/Quests still do not double-award; audio/haptics and Home/Pause/Settings/Help work.
- [ ] 11. **Physical iPhone 14 Pro** 8×8/12×12 Blossom corner input and save restoration (not yet owner-tested on 4.4).
- [ ] 12. Inspect CI audit JSON as synthetic evidence only. No price/reward change is justified by first-fit simulation alone.

**Release state:** Candidate only. Keep PR as draft until physical QA and explicit approval. Night Edition stays a later visual-only Build 4.6.
