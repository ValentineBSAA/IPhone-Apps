# 🍓 Berry Berry Blast | v0.5.14 Build 4.3 POLISH QA

**Status: TEST CANDIDATE ONLY. Do not merge or release.**

**Parent:** Build 4.2 real-device QA 23/26, source branch
\`feature/berry-build4-r3-responsive-layout\`, user results recorded
[here](https://github.com/ValentineBSAA/IPhone-Apps/issues/8).
**Build 4.3 branch:** \`feature/berry-build4-r4-polish-qa\`.
**Build number:** Info.plist \`43\` (marketing version remains \`0.5.14\`).
**On-device Home identifier:** \`B4.3 POLISH\`; Settings and Developer Garden \`Build 4.3 • POLISH QA\`.

## Purpose: close two known visual issues without engine churn

- [x] Replace the old pale pink default gameplay pieces with the user's
  approved second darker *raspberry* pink image, now connected directly to
  BerryTile on the board, in ghost previews and in the tray
- [x] Preserve one and only one default pink UIImage route, and use it for
  actual pink color indices in Classic/Endless, Story, Blitz and Nightmare
- [x] Update the image integrity test to **the actual committed 160×160 PNG**
  with SHA256 \`5cf64371058073cf2924b0bcf0ff864e50cc61ef0a5b80e015952ee9f4ba9775\`.
  Previous wrong 192px expectation blocked CI before compilation
- [x] Remove duplicated **Berry Classic** wording: top bar retains mode
  identity, score panel says "CURRENT SCORE" and secondary objective says
  "Three pieces • Chase your best!"
- [x] Shorten repeated Daily/Cozy/Nightmare descriptions without modifying
  scores, timers or progress. Top bar remains the single mode identifier
- [x] Do not change saved sessions, touch targets, board size/geometry,
  Blossom Glass external border, economy, mode rules, music or inventory
- [x] Explicitly distinguish Build 4.3 from the installed Build 4.2 IPA

## GitHub CI gates (must complete before owner tests)

- [ ] Source, iOS 16, audio and PNG checks
- [ ] Linux Swift engine regression
- [ ] **Real iPhone 16e simulator** entire XCTest suite, geometry and screenshots
- [ ] **Real iPhone 14 Pro simulator** entire XCTest suite, geometry and screenshots
- [ ] iOS device compilation, IPA integrity, native assets and build 43 check

## Physical QA on Build 4.3 (new candidate, not inherited from 4.2)

- [ ] Home clearly reads **B4.3 POLISH**; Settings = Build 4.3/internal 43
- [ ] Original Strawberry Jam default pink squares are distinctly darker
  than pink board in both **Berry Classic and Sweet Endless** (8×8)
- [ ] Dark pink tiles do not show black outlines, halos, visible transparency,
  crushed shine or degraded artwork compared to yellow/purple/teal
- [ ] Single-tile art scales well on smaller **12×12** cells and in the tray
- [ ] Pink pieces maintain correct positions during taps, drag/ghost preview,
  corner and edge placement. Other colors are unchanged
- [ ] Optional Boutique block skins still render and revert independently
- [ ] Berry Classic now has **one mode title**; score HUD and challenge
  caption are readable, no text clipping
- [ ] Story/Blitz/Nightmare/Daily/Cozy labels fit and don't repeat their names
- [ ] Blossom Glass stays outside all board squares and reverts correctly
- [ ] Sweet Endless 12×12 previously unchecked: all 144 cells, three slots,
  tools and score fit and accept placements
- [ ] Confirm saved Endless run, berries, purchases, tool charges and
  stats preserved after background and force-quit
- [ ] iPhone 14 Pro physical 8×8 + 12×12 + pink + Blossom Glass cross-check

## Release hold

Build 4.2 had **23/26** checks marked on a real iPhone 16e. The three
previously unchecked items were the duplicated-mode-label requirement,
Sweet Endless 12×12 hardware, and iPhone 14 Pro physical testing. **None
of these counts transfer automatically to 4.3**. Only the first has a
source correction; the other two still require owner device tests.
Gameplay rules, long-term progression, economy, balance, and launch
readiness remain future work. Owner has not decided to release publicly.
Keep Build 3 rollback and parent draft PRs intact.
