# 🍓 D0e · Standard Tool Purchase Interruption Recovery

**Checkpoint:** November 20, 2026, Arizona local date.  
**Base:** [D0d draft PR #67](https://github.com/ValentineBSAA/IPhone-Apps/pull/67), previously 40/40 named iPhone 16e simulator tests green.  
**State:** D0e source candidate only; separate feature branch and draft PR, **not merged, released or tested on a physical iPhone**.  
**Workstream:** [Advanced Developer Garden #61](https://github.com/ValentineBSAA/IPhone-Apps/issues/61).

## Problem being addressed
Previously Undo / Shuffle / Hint checkout wrote inventory and spending-ledger values to several legacy `UserDefaults` keys. A crash between writes could leave inventory debited while the ledger lagged or vice versa. D0e introduces a **versioned pending-purchase intent**, written and read back before changing legacy inventory or spending data, and idempotent replay on session launch.

## Code changes
- [x] New `BerryStandardPurchaseJournal.swift`: stores version, UUID, tool, fixed purchase price, **complete exact encoded post-purchase inventory**, absolute overall spend total and absolute per-item spend total in `berryberryblast.standardTools.pendingPurchase.v1`.
- [x] Entry validates schema, tool price, nonnegative counts, JSON inventory and matching target charge; overflow cannot create a journal.
- [x] `BerryStandardPurchaseJournal.stage()` refuses to overwrite any unresolved intent. A purchase does not change inventory/ledger when stage fails.
- [x] `recover()` writes the exact post-purchase inventory and restores ledger totals via **absolute assignment, not increment**. The intent is only cleared after read-back checks; replay cannot charge twice.
- [x] `BerryEconomyLedger.applyStandardToolSpendRecovery()` safely sets spend totals and the purchased item while retaining other item history.
- [x] On `BerryGameSession.init()`, an existing pending standard-tool purchase is recovered **before inventory is decoded**. Regular `BerryGameSession()` retains the same existing storage keys and default shared ledger.
- [x] Standard-tool purchases now consolidate through one `buyStandardTool` routine; it builds the post-purchase inventory before staging, replays the staged intent, then updates the session and preserves existing `save()` semantics. Prices, user-visible tool counts and remaining undo snapshot invalidation are preserved.
- [x] All three purchases remain completely separate from story, daily, premium, cosmetics, quest/birthday gifts, Night currency and Night Market.
- [x] Added **8 interrupted-state XCTest cases**, on top of the earlier **40** D0–D0d tests. Coverage includes successful checkout, intent-only restart, interruption after inventory update, interruption between ledger key updates, idempotent second restart, malformed-intent preservation/blocking, independent preexisting saves, and overflow/unresolved-intent refusal.
- [x] [D0e Actions #44867590124](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44867590124) **SUCCESS**; actual job log confirms **48/48 selected iPhone 16e XCTest methods passed, zero failures**, Release compiled without QA-only panel and no IPA created.
- [ ] Owner physical iPhone 16e check after approved test build; no IPA built/released as part of this stage.

## Explicit guarantees and limitations
- **Best-effort replay, not guaranteed crash durability**: `UserDefaults` is not a durable write-ahead-logged database. A sudden power loss before intent bytes physically persist is outside the guarantee. The design recovers an intent that does survive.
- **Multi-key atomicity remains limited**: inventory and the ledger are still independent preference keys. During replay they can temporarily disagree until both are written, but the retained intent allows completing the operation at the next start.
- No crash-process termination/fault-injection hardware experiment has been done. XCTest manually stages and selectively applies real persistence bytes, then creates a new real session to simulate startup.
- A malformed unresolved journal is intentionally preserved and blocks further standard-tool purchases rather than deleting evidence or risking a duplicate charge. Friendly recovery messaging and user-facing support should be added before production adoption.
- Existing user data and older Inventory encoding remain unchanged. Normal shop, cosmetics, non-standard premium tools and legacy Daily/Story saves still require separate dedicated test suites.
- No new image generation, game modes, pricing adjustments, build number or IPA.

## D0e regression checklist
- [x] Source/artwork/audio and iOS16 checks passed in GitHub Actions #44867590124.
- [x] Production Release build passed with Developer Garden QA-only panels excluded.
- [x] Named iPhone 16e simulator: prior 40 D0–D0d selected tests remain green.
- [x] Eight new `BerryStandardPurchaseRecoveryTests` pass with zero failures.
- [x] Simulator verifies no duplicate spend/charge on replay and multiple restarts; physical/crash durability testing remains open.
- [x] Simulator regression verifies unrelated 12×12 saved slot and `UserDefaults.standard` unchanged in isolated tests.
- [ ] Complete physical iPhone QA of normal Undo, Shuffle, Hint purchases and saved session reload.
- [ ] Run full-game regression before any branch merge or release.

## Later full-game milestones
[D0f] Audit true game UI error handling when a pending journal is corrupt and build friendly recovery instructions. [D1–D7] Expand Developer Garden scenario runner into premium tools, cosmetic Boutique, Daily Harvest, Story, 8/12/24 gameplay, Night Garden, holiday clock and full save migrations. Preserve all original game mechanics and approved assets. Every new game feature must have a scenario coverage entry.

**D0e is an incremental game reliability milestone, not the whole game's finish line.**


## ✅ Verified D0e automated gate · November 20, 2026 (Arizona)
- [x] [GitHub Actions #44867590124](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44867590124) terminal **SUCCESS**. Actual job log contains `** TEST SUCCEEDED **`.
- [x] `BerryDeveloperSandboxTests` **6/6**; `BerryDeveloperStateLabTests` **11/11**; `BerryEconomyTests` **4/4**; `BerryStandardPurchaseRecoveryTests` **8/8**; `BerryStandardToolCheckoutIsolationTests` **9/9**; `BerryStandardToolTransactionTests` **10/10**. Combined **48/48, 0 failures**.
- [x] Release build succeeded and the internal QA-only Developer Garden features were excluded, with no IPA generated. Original approved artwork and music source validations passed.
- [ ] **This is selected simulator regression, not full-game or physical-iPhone acceptance.** UserDefaults remains non-atomic and non-durable under sudden power loss; real process-kill/hardware and friendly corrupt-journal repair UI are still required before release.
