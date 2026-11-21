# 🍓 I6 | Board Studio and Settings persistence on actual iPhone UI

**Source base:** I5 integrated Quest/Story/Daily/Birthday + safe Shuffle/Undo draft [PR #89](https://github.com/ValentineBSAA/IPhone-Apps/pull/89). This follow-up is unmerged, development-only, and does not replace real iPhone owner acceptance.

## Previously open real-device issue

The Build 4.4 physical testing checklist left unchecked whether Boutique, Settings and gameplay retain the same selected board after force closing the application. Original Strawberry Jam and Strawberry Blossom Glass are the only two approved Board Studio looks currently exposed. This is a cross-menu persistence contract, not a new visual skin.

## Actual production code

- [x] The real Berry Boutique Board Studio and Berry Settings already share the original on-device UserDefaults/AppStorage key: berryberryblast.board.surface.v059.
- [x] Native, stable accessibility identifiers added to existing two-column category and Board Studio cards, and Settings Original/Blossom choice cards. Both cards report their real selected/not-selected state to VoiceOver; their player-visible text, visual layout and existing behavior remain unchanged.
- [x] Test drives real native screens: open Boutique → Board Studio → select Original → Blossom Glass → confirm Settings also shows Blossom → terminate the whole app → relaunch → confirm both menus persist Blossom → select Original from Settings → confirm Boutique → terminate again → relaunch → confirm Original persisted.
- [x] Test runs in a disposable iPhone simulator; never changes a real owner's phone, inventory, wallet, Endless save, prices, artwork or board geometry.
- [x] Existing five native navigation and Daily/Story journeys remain inherited from I5, as do 161 selected real model tests and original 51 music/16 effects.

## Verification still required

- [ ] I6 combined named iPhone 16e CI terminal success: all **six native UI tests** and **161 existing model tests**, with zero failures and screenshot evidence.
- [ ] Production Release no internal QA panels, original iOS16 source/art/audio, no accidental IPA or publishing.
- [ ] Real owner iPhone hardware: touch edge/corner on both 8x8 visual surfaces; force close with existing active Endless run and score and verify board selection persists without wiping the save; check Settings/Boutique from gameplay.
- [ ] Validate iOS accessibility, contrast and long user labels on both board looks.
- [ ] Separate whole-game QA remains: Story blocked-board rescue and Golden confirm/cancel, actual earned Quest/Birthday touch rewards, full original 8x8/12x12/24x24 restores, final Village/Quest/Journal art (#78), seasons Day/Night, Build5 Village and Build6 separate Night Market/Moonberries.

Preserve v0.5.16/internal Build46, com.valentinebsaa.berryblockblast, iOS16+, existing preferences and saves. **No merge, IPA, signing or public release without further review.**
