# 🍓 Berry Berry Blast I7 / v0.5.16 Build 49 | Exact verification handoff

**Status November 21, 2026:** implementation committed to draft [PR #97](https://github.com/ValentineBSAA/IPhone-Apps/pull/97), **NOT yet compiled for iPhone or packaged**. Verified existing physical-device fallback is Build 48, [successful CI #44947069107](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44947069107). Don't replace a working owner install until Build 49's own green evidence exists.

## Changes in the candidate

- Existing Home header now displays **12-hour local time with seconds** (`2:00:37 PM`) and an **HH:MM:SS second-by-second countdown** to next local **6 PM Moonlight** / **6 AM Sunrise**. It samples real `Date()` on each tick and on app foreground/significant-time changes.
- Permanent Settings long-press PIN **1476** Developer Garden, real Cheat Strawberries with exact previous-balance restore, and the original isolated labs remain in the *Release* target.
- Four **read-only** Developer Garden Timers & Clocks / State & Timer Lab time previews (5:59:58 AM, 6:00 AM, 5:59:58 PM, 6:00 PM). Does not edit iPhone clock, purchases or saves.
- Six **actual approved bundled PNGs** shown in a **two-column** Moonberries & Night Market Developer Garden preview: `BerryRewardBlueberrySparkle`, `BerryRewardMoonberryNightmare`, `Moonberry_Currency`, `Night_Moonberry_Currency`, `Approved_Night_Market_Storefront`, `Night_Approved_Night_Market_Storefront`. This does not create a real Night Market or Moonberry economy; those are Build 6.
- Same iOS 16+ `com.valentinebsaa.berryblockblast` bundle ID, existing saved progress and original 51 music/16 SFX resource paths. Build identity **0.5.16 / internal 49 / I7 QA**.

## Verification performed vs outstanding

- [x] Source committed to `feature/berry-i7-live-clock-seconds-b49` and scoped in [issue #95](https://github.com/ValentineBSAA/IPhone-Apps/issues/95) and both full-game roadmaps.
- [x] Independent **Linux Swift Foundation** time-helper checks passed: 12-hour clock strings, 6 AM/6 PM boundary rollovers, 1-second countdown, midnight, next-day wakeup, fractional final second, America/Phoenix vs America/New_York local boundaries and virtual 5:59:58 → 6 PM. **Not an Xcode/iPhone build**.
- [x] Wrote `BerryClockCountdownSecondTests.swift` (**9** Swift unit cases), `BerryReadyBlueberryMoonberryArtTests.swift` (**2** bundle/catalog tests), `BerryLiveHomeSecondsUITests.swift` (**1** native UI journey).
- [ ] **GitHub Actions activation is owner-side.** The complete Build49 9-native-UI + 180-regression + unsigned IPA workflow is [staged for review](BuildDocs/berry-i7-clock-b49-WORKFLOW-TO-ACTIVATE.yml), with [one manual activation action](BuildDocs/ACTIVATE_BUILD49_GITHUB_ACTIONS.md) to move it into `.github/workflows/berry-i7-clock-b49-private-ipa.yml` on this branch. The connected GitHub integration is blocked from writing `.github/workflows`. **Until the owner performs that move, no Build49 workflow run exists and Build49 has not passed native CI.**
- [ ] After manually activating the staged workflow on an authorized macOS/Xcode GitHub runner: require exact Bundle **49**, nine native UI tests (8 prior + new live seconds screen), 180 selected regression cases (169 prior + nine clock + two artwork), iPhoneOS Release compile with the hidden Garden, 51+16 audio resources, all six PNG images, bundle identifier, SHA-256 and ZIP integrity. **Do not turn an unrun prepared YAML into a claimed green build.**
- [ ] Only **after the full new Build49 CI is green** supply its unsigned private IPA to the owner for AltStore signing. Do not create a GitHub public release or merge into `main`.
- [ ] Confirm actual phone functionality and save continuity before marking Build49 physically approved.

## The owner's THREE short physical checks (only after green CI + backup)

1. Home shows **v0.5.16 • B49 • I7 QA** and the 12-hour clock and Moonlight/Sunrise countdown seconds visibly update.
2. Settings build-label long-press opens the PIN-protected Developer Garden; Strawberry cheat/restore remain; the safe timer previews and six Blueberry/Moonberry art previews display.
3. Existing wallet balance, owned cosmetics, Endless 8×8/12×12/24×24 saved games, music and ordinary navigation remain intact.

**Explicitly deferred:** approved decorative clock frame integration, new highly illustrated Blueberry Velvet tile art, a real Night Market checkout and a separate live Moonberry balance/cheat/restore. No substitutes, mock purchases or owner-save resets.

**Build49 remains a DRAFT source candidate until these gates pass.**
