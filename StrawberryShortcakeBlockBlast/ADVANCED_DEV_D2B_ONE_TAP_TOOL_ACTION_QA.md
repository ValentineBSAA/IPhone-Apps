# 🍓 D2b · Developer Garden Real Tool Action Lab

**Status:** Internal D2b source staged in a separate draft feature branch; no physical owner signoff and **CI verification pending**. Based on D2a, D1c, D1b, D1a and earlier D0 proof.

**Product unchanged:** `com.valentinebsaa.berryblockblast`, iOS 16, **v0.5.16 / internal Build 46**, same save schema, game modes, approved artwork, 51 music/16 sound assets, currency and item prices. **No IPA, merge or version bump.**

## What is truly implemented
- [x] Added **Tool Action Lab** to the existing internal Developer Garden's **two-column advanced tools grid** alongside (not replacing) Scenario Sandbox, State & Timer Lab and Commerce Lab.
- [x] **One-tap execution**: each card constructs its own actual `BerryEngine` with one legal move, actual `BerryGameSession`, selected `checkoutDefaults` and isolated real `BerryEconomyLedger`; executes a real valid or invalid premium action; decodes or reopens the exact test saved board; reports expected versus actual with PASS/FAIL; verifies owner real preference keys unchanged.
- [x] Uses freshly named disposable `UserDefaults` suite for every tap; clears test domain after execution. Re-run and Discard & reset are present. Never receives the owner's game session and never silently grants real player strawberries.
- [x] Both model and SwiftUI panel use the **`#if BERRY_INTERNAL_QA` guard**. Release build checks for QA-only symbols. The existing original manual Test Strawberries button remains separate.

## Seven real-action scenario cards
1. **Trowel Removes Cell:** valid Trowel on occupied 8×8 board, spend one charge, saved cell empty after actual GameSession restart, score/moves preserved.
2. **Seed Plants Cell:** valid Starberry Seed into empty cell, save/reload planted cell and move count, spend charge once.
3. **Golden Rescue:** valid Golden Strawberry clears occupied board, preserves score, retains `goldenRescueUsed` and zero charges on reopen.
4. **Golden Only Once:** second attempt after restart is rejected without extra debit.
5. **Invalid Tool Targets:** off-board Trowel and occupied-cell Seed do not change charges or saved-game bytes.
6. **Mega Garden Save:** valid 24×24 Trowel persists exactly that board, retaining byte-identical 8×8 and 12×12 test saved slots.
7. **Buy & Use Trowel:** actual 150-berry premium purchase, valid use, wallet zero, actual ledger 150, zero charges and updated board after restart.

## Verification
- [x] **Eight new XCTest methods** in `BerryDeveloperToolActionLabTests.swift`, checking all seven card scenarios, targeted receipts, repeat-run isolation, reset/discard and original owner UserDefaults not modified.
- [ ] [D2b Actions #44871494518](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518): **94 selected iPhone 16e simulator XCTest** (D0–D2a existing 86 + 8 D2b), original source, artwork/audio/iOS16 preflight, production Release exclusion of D2b panel+runner and no IPA. Must verify actual terminal logs; no claim until green.
- [ ] Owner physical iPhone 16e: enter Developer Garden > More diagnostics > Tool Action Lab; run all 7; compare expected/actual; verify original saves/wallet/charges unchanged on force quit/reopen; inspect two-column readability, VoiceOver, gesture/tap responsiveness and B/Done dismissal.
- [ ] Long regression: Story/Daily/Blitz/Cozy/Nightmare modes, normal user-facing gameplay tool gestures, permanent upgrades, integration of asset and seasonal packs. Not covered by 94 targeted XCTest alone.

## Restrictions and future work
- One-tap tests execute actual handler methods against isolated storage. They **do not** automate the production SwiftUI game board interaction, not proof of full touch integration.
- UserDefaults multi-key purchase/save transactions are not power-loss atomic; sudden crash durability is not guaranteed.
- Remaining D2c valid Ribbon Twister and Picnic Pantry action coverage, 24×24 Golden rescue, Game Over rescue and safe exit; D3 Story/Daily/quest/birthday timers and reward protections; D4 seasonal artwork; Build4.7/4.8 Day/Night parity; Build5 quests/village; Build6 Night Market/Moonberries remain on the whole-game roadmap.
- Preserve physical owner acceptance gate and all original art, music, save files. No new IPA, no merge without explicit approval.
