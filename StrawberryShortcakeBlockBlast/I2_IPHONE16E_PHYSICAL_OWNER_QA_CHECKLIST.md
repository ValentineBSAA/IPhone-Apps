# 🍓 Berry Berry Blast · I2 Physical iPhone 16e Owner Acceptance Checklist

**Status: PREPARED, NOT RUN OR ACCEPTED.** Applies only after independently verified [I2 combined PR #85](https://github.com/ValentineBSAA/IPhone-Apps/pull/85), with separate D3e/I1 automated passes and a deliberately approved test-signed installation. Preparing this checklist **does not create, install, publish or authorize an IPA**.

**Expected app baseline:** iOS 16+, bundle `com.valentinebsaa.berryblockblast`, v0.5.16/internal Build46, approved original art and 51 music tracks/16 effects, independent 8×8/12×12/24×24 Endless saves and original player wallet, premium ownership, Story/Daily/Cozy/Blitz/Nightmare progress. The I2 development branch combines Quest & Story diagnostics, safe approved-image fallbacks and birthday date validation, but is not a signed/merged public build.

## Protect saves before touching anything

- [ ] Record phone model, iOS version, displayed Build number, available storage and whether this is the **internal QA** or ordinary **Release** build. Do not confuse named-simulator tests with physical testing.
- [ ] Use the game's supported backup/export flow before any destructive testing, then verify the backup can be read. Do **not** share a sensitive personal save publicly or deliberately reset current progress.
- [ ] Capture existing wallet, top score, chosen mode, saved 8×8/12×12/24×24 gardens, owned premium tools, Story chapter and Daily history. Comparing screenshots later is enough; **no need to play dozens of rounds**.
- [ ] Verify the iPhone is in normal time/date settings; **do not change system clock** to simulate birthday or Daily rollover in a real saved player profile.

## Home, native navigation and artwork (short tap pass)

- [ ] Home shows the correct version, berry wallet and one readable title. Settings, Boutique, Story, Village, Quest Board, Journal and Developer Garden navigation do not hide Home/Pause/Help/Settings actions unintentionally.
- [ ] All non-gameplay menus and submenus remain **two-column card grids**. No accidental stacked list replacement, text clipped offscreen, invisible cells, overlapping panels, or duplicate headers.
- [ ] Village, Quest Board and Journal show real **bundled approved fallback imagery** rather than missing-image blank areas. Temporary fallback `BerryStory`, `HarvestReward`, `Milestone` is **not the final exact approved illustration**; leave missing-art issue #78 open until the actual approved named art and owner visual signoff.
- [ ] On screen rotation/large text/VoiceOver as applicable, controls stay legible, two-column cards are accessible, and B/back/close/pause behavior follows native iPhone expectations. Long pages scroll without trapping taps.
- [ ] Confirm playback selection, 51-original-song catalog and 16 existing effects still work as before (spot check music toggle and one effect; no need to play each).

## Birthday, especially D3e

- [ ] Settings → Celebration has birthday **Month** and **Day** in a two-column card grid with local-only privacy text, and a working `Not Set` option. The app does not request a birth year.
- [ ] Selecting February shows **at most 29** days, April/June/September/November **at most 30**, and January/March/May/July/August/October/December 31. February 29 remains selectable.
- [ ] If an existing user has an older invalid saved pair such as April 31, the UI explains the problem politely and offers a valid choice **without silently overwriting** saved data. Never corrupt a real preference just to manufacture this case; isolated simulator tests cover it.
- [ ] With birthday unset or not today, no annual gift appears. On the owner's **actual** matching birthday, one tap gives exactly **100 strawberries** once, remains claimed after relaunch, and does not duplicate a prior year's award. If it is not birthday today, mark **Not currently observable**, not PASS or FAIL.
- [ ] Don't alter the device clock to test future years or February 29. Existing leap-day policy celebrates on the actual February 29 only; owner decision on alternative nonleap celebration day remains future.

## Existing gameplay and save compatibility (minimal physical smoke)

- [ ] Open Endless 8×8, make one normal move, exit/reopen; score, tray and garden persist. Repeat for independent 12×12 and 24×24 slots **without replacing other sizes**.
- [ ] Basic edge/corner placement and original Strawberry Jam/Blossom Glass board skins remain visible, reversible and touch-aligned.
- [ ] Story and Daily entry/resume retain original chapter/day rules. A real Daily attempt cannot be restarted on the same local date after loss/completion; no need to purposely lose a valuable saved active attempt.
- [ ] Check one existing owned cosmetic can equip, unequip and survive restart; premium wallet/ledger/owned tools do not spontaneously debit or reset. Do not buy more solely for QA.
- [ ] No unexpected crash, blank game-over dialog, lost pause/settings/help icons, frozen tool taps, audio takeover or progression jump from switching menus.

## Internal-only Developer Garden: one-tap instead of grinding

Only if a **deliberate internal QA build** is installed. For production Release, confirm these controls are **not present**, not that they are hidden behind another page.

- [ ] The preexisting Sandbox, State Lab, Commerce Lab and eleven-card Tool Action Lab remain readable two-column cards with expected/actual and PASS/FAIL.
- [ ] One-tap **18-Move Quest** returns 20 temporary berries exactly once and one receipt. No real quest progress changes.
- [ ] One-tap **Story Chapter & Claim** returns 35 test berries for the chapter quest plus 25 chapter reward exactly once, and reopens with 60 temporary berries.
- [ ] One-tap **Four-Day Quest Rotation** checks each day with a simulated local date; one-tap **Village Levels** verifies 1→2→4→5. The phone clock and current real chapter never change.
- [ ] One-tap **Wrong Wallet Protection** rejects payment into another test wallet. Reset and rerun the scenarios, then force-close/reopen and confirm the original actual wallet, Story quest claims and all three Endless saved gardens remain intact.
- [ ] If internal actions show FAIL, record the scenario, expected/actual text and screenshots. **Do not clear/reset real player data to 'fix' a test.**

## Release acceptance and omissions

- [ ] The **I2 152-selected XCTest** is terminal green, after both independent I1 143 and D3e 141 runs are checked, and production Release excludes QA-only internals with no IPA created by CI.
- [ ] Physical visual/tap testing is recorded as **owner-approved or pending**. Model-handler XCTest does not prove native Story Game Over, premium checkout, Quest Claim or Birthday banner touch flow.
- [ ] All additions retain iOS16 compatibility, original sound/art identifiers, prices, rewards, separate Endless gardens, Daily/Story progress and old preferences. Keep unrelated full-game roadmap visible: complete approved seasonal day/night assets, Build4.7/4.8 Day/Night parity, Build5 evolving Village/quests, Build6 distinct Night Market/Moonberries, birthday refinements and transaction crash consistency.

**Tester result:** ☐ Not started ☐ Partial ☐ Completed with failures ☐ Completed and owner-approved

**Evidence:** device/iOS ___ · installed Build ___ · screenshots/logs ___ · failed sections ___ · owner signoff ___

**Safety:** No merge, TestFlight/public release, version/build increase, signed IPA or owner save migrations merely because this checklist exists.
