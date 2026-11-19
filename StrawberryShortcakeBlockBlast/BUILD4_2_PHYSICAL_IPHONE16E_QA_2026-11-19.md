# 🍓 Berry Berry Blast • Build 4.2 physical iPhone QA

**Recorded:** November 19, 2026  
**Tester:** owner, real iPhone 16e, signed/installable local Build 4.2 IPA  
**App:** v0.5.14 • Build 42 • Home label "B4.2 LAYOUT"  
**Evidence:** user-supplied ChatGPT checklist screenshots \`IMG_9689.png\` to \`IMG_9693.png\`, showing **23 of 26 checked**  
**Status:** **23/26 PASS (owner-reported), 3 UNCHECKED; NOT release approved**  
**Original Build 4.2 simulator + IPA run:** https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/44517994703  
**Draft source PR:** https://github.com/ValentineBSAA/IPhone-Apps/pull/11  
**Known-good Build 3 rollback:** \`b4ffda288b7a778a79a860c8d8ebc2cab3e5755b\`

### 1. Installation and existing progress — 4/4

- [x] Home displays **B4.2 LAYOUT**, not B4.1 TEST
- [x] Settings shows **Build 4.2 (internal 42)**
- [x] Saved Sweet Endless run resumes with previous score, **44+ lines**, moves and **260 strawberries** preserved
- [x] Original Strawberry Jam board renders normally, all 64 squares visible

### 2. Responsive 8×8 layout — 6/7

- [x] Board slightly smaller than Build 4.1, still comfortably large
- [x] Title, score, combo, board, tray, toolbar and bottom counters have clean vertical separation
- [x] All four corner squares completely visible and accept placements
- [x] Tap/drag near edges: ghost preview matches final placement
- [x] All three tray cards remain visible, evenly spaced; no overlapping buttons
- [ ] **Labels and stats**: readable, **no duplicate Sweet Endless subtitle** or clipped text. Tester intentionally left this unchecked. Earlier visible screenshot also showed repetitive **Berry Classic** labels. Inspect and remove duplicated mode labels without moving the proven board
- [x] QA TOUCH diagnostics toggles on/off; extra readout fits without hiding controls

### 3. Blossom Glass containment — 4/4

- [x] Blossom Glass enabled and clearly distinct from Original Strawberry Jam
- [x] New decorative border stays outside *all* playable cells, including corners
- [x] Edge/corner dragging with Blossom Glass works without visual or touch obstruction
- [x] Returning to Original Strawberry Jam does not modify saved game

**This closes the specific blocker discovered in Build 4.1** on the owner's tested iPhone 16e; **separate iPhone 14 Pro hardware verification remains outstanding**.

### 4. All game modes and board sizes — 6/7

- [ ] **Sweet Endless 12×12**: explicitly verify all 144 squares, three tray cards and controls accessible. Not checked in the owner's screenshot; **do not infer this pass from Nightmare's 12×12**
- [x] Sweet Endless 24×24: 12×12 viewing sections fit, switching sections works without overlap
- [x] Berry Story: chapter progress and dialogue above board; tray and controls visible
- [x] Daily Harvest: calendar/objectives fit; controls not obscured
- [x] Berry Blitz: timer, score, board and tools fit; timer advances
- [x] Strawberry Nightmare: 12×12 board, countdown and score fit
- [x] Cozy Cottage and Berry Classic: HUD, tray and navigation properly proportioned

### 5. Final safety checks — 3/4

- [x] Pause, Home, Settings, Help and Boutique open/close; layout not broken
- [x] Gameplay sounds, music and haptics work
- [x] Force-close and relaunch: saved progress, appearance and inventory persist
- [ ] **iPhone 14 Pro physical cross-check**: repeat core 8×8, 12×12, Blossom Glass, saved run. The *simulator* passing does **not** constitute real 14 Pro sign-off

### Observations outside the 26-item checklist

- **Pink block contrast issue:** default pale frosting-pink pieces visually blend into the pink playing field. Owner approved the **second, much darker raspberry candy block** concept. A focused GitHub change is now committed at \`d026a36d8485e1339e148f5c6320aaefac3d3f86\`: replacement \`Tile_Pink.png\`, default-block renderer connection and test. **Not yet physically tested in an IPA.** The 23/26 checklist above pertains to the previous Build 4.2 IPA, *not* this newer untested artwork commit
- **Duplicate labels:** Berry Classic appeared in multiple lines in the tester's earlier screenshots. The checked count correctly leaves the clean-label requirement open
- **Gameplay rules, difficulty/progression, rewards and economy** are still developmental. Owner expressly says not ready for release and is undecided whether the game will be publicly released. Do not treat a polished UI as a release milestone
- **Future scope:** finish unverified 12×12 Endless and iPhone 14 Pro tests; later independently design and test gameplay rules, progression pacing, repeat-play incentives, tools, purchases and rewards. Preserve current working controls, engine, touch targets and saves
- Night Edition auto switching, Moonberries and Night Market transactions are future staged features, **not** failures in Build 4.2

### Release hold and next steps

- [ ] Confirm 12×12 Endless on actual iPhone 16e
- [ ] Eliminate/approve duplicated mode text and ensure labels fit without clipping
- [ ] Finish 14 Pro physical sign-off
- [ ] Build/test approved dark raspberry tile on actual device before calling its contrast issue resolved
- [ ] Audit and stabilize game rules, reward/economy design and long-term progression before any public release decision
- [ ] Leave PR #11 and parent draft PRs unmerged until separate visual and gameplay sign-off

**Do not merge or publish based only on 23/26.** UI work is showing meaningful progress; remaining rule and economy development needs its own tests.
