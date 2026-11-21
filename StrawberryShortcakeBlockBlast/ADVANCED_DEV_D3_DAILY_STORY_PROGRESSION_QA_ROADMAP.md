# 🍓 Berry Berry Blast · D3 Whole-Game Progression, Daily and Story QA Roadmap

**Status: AUDITED ROADMAP ONLY, not implemented.** Written while the stacked D2b/D2c simulator suites are being verified. This roadmap extends the whole game, not just a test menu. Keep all user progress, save migrations, day/night state, approved art/audio, iOS16, 12-hour clock and two-column menu layouts intact.

## Why D3 requires more care than premium tools

The existing `BerryDailyHistory` has partial dependency injection already: `outcome`, `beginToday`, `activeEngine`, `saveActiveEngine`, `expirePriorAttemptIfNeeded` and `markLostToday` accept an optional `UserDefaults` suite. But `BerryGameSession.selectMode(.daily)` and its `save()` path still call these using shared defaults, so creating an otherwise isolated QA `BerryGameSession` could spend the REAL player's daily attempt.

`BerryDailyHistory.completed`, `markCompleteToday`, `nextStreakDay`, streak counters and historical legacy completion paths also read/write `UserDefaults.standard` and use `Date()`/`Calendar.current`. Directly simulating new days by touching system date or shared defaults is prohibited.

`BerryProgression.shared` is a singleton. It reads/writes daily quest progress, claims, claimed totals, played modes, Story chapter completion and celebration through `UserDefaults.standard`, with live dates. `BerryGameSession.awardOnce` likewise writes the real reward-consumption key and `earn` writes real reward receipts and the shared economy ledger. **These must not be called in disposable QA tests until isolation is complete.**

Story level, birthday month/day and seasonal state are also exposed through `@AppStorage` in native views. New one-tap fixtures must not mutate the player's actual story chapter, birthday or present-day state.

## D3a: Daily Harvest true safe deterministic scenario runner
- [ ] Refactor the `BerryGameSession` Daily mode selection, active engine save, win/loss and reset paths to consistently pass its injected preferences. Ensure production defaults remain `.standard`, legacy save keys and user completion history remain untouched.
- [ ] Create an injectable **date provider** for applicable Daily `begin`, `outcome`, `activeEngine`, `expire`, `save` and `finish` decisions. Default must remain current local date and timezone; do not change the user's phone time.
- [ ] Tests: first entry consumes precisely today's attempt before first move; unfinished attempt resumes; same day second entry resumes without additional spend; win/loss blocks another attempt; midnight expires yesterday's active game but leaves new day free; locked future day not selectable.
- [ ] Tests: restore legacy completion without double claim, corrupt save without granting duplicate attempt, and independent daily state across disposable suites.
- [ ] When real-handler tests pass on **named iPhone 16e simulator**, add two-column one-tap Daily Lab with per-scenario expected/actual PASS, isolated clock and reset; label as scenario testing, not real physical user UI testing.

## D3b: Economy-safe Daily quest and reward verification
- [ ] Dependency-inject `BerryProgression`'s existing preferences and date source **without changing its shared live instance**, and design isolated claim receipt/payout path that uses injected `BerryGameSession` reward methods.
- [ ] `BerryGameSession.awardOnce`, `earn`, and `rewardDaily` must use session preferences, real injected `BerryEconomyLedger` and isolated reward receipts, preserving existing one-time keys and older paid completions.
- [ ] Tests: all four quest types' progress counts, no double berry reward on repeated claims, idempotent reopen, invalid claim no spend, day boundary quest reset, seven-day streak reward ladder and legacy no-double-pay. Distinguish economy line-earned and quest/story-earned counts; do not retroactively recalculate players' wallets.
- [ ] Story/Birthday awards and celebrations should not broadcast into real shared `BerryProgression` from an isolated session. Production celebrations remain as before.

## D3c: Story, Birthday, Village and continuation
- [ ] Separate persisted Story chapter completion and owner-visible chapter/story progression from disposable QA checkpoint state. Keep `berryblockblast.story.level` original key.
- [ ] Tests: complete a chapter, rewardOnce exact amount, no chapter double claim, continue/restart semantics, Story Game Over and purchased rescue (including D2c combined checkout logic) tested through the actual production screen separately.
- [ ] Birthday: test Feb 29/non-leap years, local midnight, repeat open, month/day not set, yearly single-award rule and no reward when unset. Do not fake the actual birthday or modify owner `@AppStorage` to test.
- [ ] Village and future Build 5 Daily Quest progression: test unlock rules, migration from old saves and real owned Cottage decorations. Include actual UX in two-column card design.

## D3d: Physical and complete regression gate
- [ ] Explicit test logs on named iPhone16e simulator and production Release code with QA internals excluded. No IPA from testing workflow.
- [ ] Owner physical iPhone16e: check actual day progression, tutorial, story, rewards, shop and gameplay UI, accessibility, long session, 8/12/24 saved Endless slots, local 12-hour UI and all approved artwork/audio.
- [ ] Never call "all features tested" until both selected automated coverage **and** the owner physical suite are accepted. Do not advance release version/build just for internal QA additions.

## Other game work still retained
D4 seasonal icon/art integration from approved GitHub assets, Build 4.7/4.8 true Day/Night visual parity and fireworks, Build 5 Village/Daily Quest progression, Build 6 genuine Moonberry Night Market, unique Night modes/Story, and final performance/low-memory/mobile layout acceptance. The Developer Garden remains a tool serving the **whole Strawberry game**, not a replacement product.

**Safety acceptance prerequisite:** D2b [94-test run](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871494518) and D2c [102-test run](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44871838416) must finish terminal SUCCESS and be accepted before treating their work as verified baseline.
