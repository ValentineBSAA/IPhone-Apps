# 🍓 D3c · Real Quest, Story Chapter and Village Progression Isolation

**Status:** Implemented source and eight selected XCTest on a stacked **draft feature branch**. GitHub Actions and physical iPhone16e owner acceptance are pending. No IPA, merge, release or version bump.

**Compatibility preserved:** `com.valentinebsaa.berryblockblast`, iOS16+, v0.5.16/internal Build46, original Story/Daily/Endless/Cozy/Blitz/Nightmare modes, original quest IDs, targets and strawberry rewards, selected two-column menus, all existing saves, approved artwork and audio.

## Why this fixes an actual test-safety gap

`BerryProgression.shared` reads and writes daily quest counters, claims, chapter completions and lifetime claim totals directly from `UserDefaults.standard`. Any advanced Developer Garden or simulator scenario that invoked it could change the owner's real progress, even when the `BerryGameSession` under test used a temporary store. Quests also selected themselves using `Date()`, making virtual-day testing impossible.

D3c preserves the **same original live shared instance** while adding `BerryProgression(defaults:now:)` to build a separate progress tracker from an isolated `UserDefaults` suite and virtual local date. All model-only reads/writes and the original rotating-three-of-four daily quest selection use injected data. The view remains linked to `BerryProgression.shared`. The existing quest IDs, rewards, progression keys, Story and Village formulas remain unchanged.

For reward safety, real `BerryProgression.claim(_:into:)` refuses a mismatch between its preferences store and the target real `BerryGameSession`, so a disposable QA model cannot pay a quest into an unrelated or live profile. `BerryGameSession.usesCheckoutDefaults` is a small identity guard, without changing regular gameplay.

## Eight real-handler XCTest scenarios
1. Place pieces in actual progression handler; verify move, line-clear and distinct-mode counters, including repeated play in the same mode counting only once for mode discovery.
2. Actual Garden Gardener quest requires **18 moves**, rewards **20 strawberries** precisely once, writes one receipt, survives GameSession reopen and refuses duplicate claim.
3. Across four virtual local dates, the rotating **three out of four** quest choices are deterministic and cycle correctly, without touching the phone clock.
4. Complete Story chapter 2 twice and chapter 3 once; chapter completion increments only for distinct chapters. Claim active Story Keeper quest for **35 strawberries** once, and verify Story chapter 2's existing **25-strawberry** reward is idempotent.
5. Local next-day quest counters reset while the original lifetime claim total survives.
6. A quest claim with a GameSession pointing at a different UserDefaults suite is **refused without paying or marking claimed**.
7. Village level reads injected chapter and Daily completed-history keys, reaches the correct levels and caps at level 5.
8. Snapshot actual owner wallet, chapter, quest, reward, Daily and 8×8/12×12/24×24 saved-game keys; verify all remain unchanged after isolated real claims and Story rewards.

### Simulator gate
[D3c GitHub Actions #44873090908](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44873090908) selects **132 XCTest**: 124 from D0–D3b plus eight D3c, with source/art/audio/iOS16 checks, a named **iPhone 16e** simulator, Release compilation excluding `BERRY_INTERNAL_QA` tools and **no IPA**. The workflow was queued when added. **Do not claim green until terminal logs show 132/132 zero failures.**

### Acceptance and limitations
- [ ] D3b 124-case terminal pass and D3c 132-case terminal pass, Release QA-exclusion and no IPA.
- [ ] Owner physical iPhone16e: actual quest cards and claim buttons, accessibility, Story completion flow, Village visuals, force-close/reopen, score/berry/quest safeguards, 12-hour display and two-column design.
- [ ] Actual Story **Game Over** UI and combined rescue remain separate from the premium handler regression. Current QA does not simulate screen taps.
- [ ] Birthday year-specific awards, quest claim process-kill journal/atomic recovery, seasonal art, Day/Night Build4.7/4.8, Build5 Village/quests and Build6 Night Market/Moonberries remain on the whole-game roadmap.

Do not represent these selected source tests as a complete game release, nor change the signed app bundle, user data, original artwork/audio, original reward ladder or save keys.
