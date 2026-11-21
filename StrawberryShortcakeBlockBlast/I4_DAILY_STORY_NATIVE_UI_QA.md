# Berry Berry Blast I4 | Native Daily Harvest and Berry Story acceptance

**Source base:** I3 native navigation [draft PR #87](https://github.com/ValentineBSAA/IPhone-Apps/pull/87), which itself builds on the I2 152/152 simulator-verified production-model baseline. **I4 remains development-only, unmerged and unverified by a fresh CI run.**

## Actual player journeys added

- [x] Native Home → Daily Streak → actual Harvest Almanac → Done: verify calendar objective and player-facing return.
- [x] Native Home → Berry Story → interactive dialogue → complete-text alert → Back to Garden → Pause → Return to Village.
- [x] Native Home → Daily Harvest → Pause/Return → reopen same Daily attempt → Pause/Return. Home must display **Resume Today**, not Play Today or new attempt.
- [x] Open the actual Harvest Almanac after interruption and verify **Your garden is still growing. Resume today's attempt.** No second Daily attempt is minted.
- [x] No QA reward fixture, no charged tool purchase, no test grants or GameSession storage schema changes; runner uses a disposable simulator app.
- [x] Native accessibility identifiers added to original Story/Home/Daily calendar controls without changing human-readable labels or 2-column grid.

## Required verification before I4 acceptance

- [ ] I3 first needs terminal evidence for all three native UI journeys; I4 source is independent and does not alter the running I3 branch.
- [ ] Run named iPhone 16e XCUITest for **both I4 new methods** plus all I3 three journeys. Record actual pass/failure and screenshots; don't claim source-file presence equals success.
- [ ] Confirm daily original saved attempt, completed/lost dates and rewards remain consistent across force close, app return and midnight, without a paid replay.
- [ ] Production Release with internal QA excluded; original art/audio, bundle com.valentinebsaa.berryblockblast, iOS16, v0.5.16/Build46 and 8×8/12×12/24×24 saved gardens intact.
- [ ] Owner iPhone real touch QA including VoiceOver, compact Dynamic Type, gameplay/story text readability and actual Daily result overlay.
- [ ] Separate follow-up: safe test fixture for *earned* Quest payout touch and Birthday 100-berry native button; don't fake an owner wallet.

## Still whole-game work, not merely the cockpit

Native Daily victory/game-over screen tests, Story rescue confirmation, final Village/Quest/Journal approved artwork (issue #78), Season Day/Night parity 4.7–4.8, Build 5 Village and quest growth, Build 6 Night Market/Moonberries, power-loss durable wallet transactions, and full hardware acceptance remain open. Story Shuffle Continue isolated ledger fix is being handled separately in [draft PR #86](https://github.com/ValentineBSAA/IPhone-Apps/pull/86), and **must be deliberately reconciled with these UI test branches later**.

**No IPA, release, production merge, build/version change, source artwork regeneration, or physical owner signoff.**
