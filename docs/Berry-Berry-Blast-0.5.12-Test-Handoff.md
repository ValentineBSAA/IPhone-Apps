# Berry Berry Blast 0.5.12 Build 1 | Native iPhone QA handoff

## What changed

- Strawberry Trophy Garden under **Berry Collection** and Inventory: ten grid cards with locked conditions, progress, permanent entitlement, and Equip/Unequip.
- Permanent cosmetic reward thresholds: 10/100/250/450/700/1000/1400/2000 lifetime lines, Royal Berry requiring 2500 lines and Story Chapter 5, and Moonberry Nightmare requiring five full 3-minute survivals plus 12 lines in one Nightmare run.
- Existing \`berryblockblast.strawberry-unlocked\` remains honored; Red Strawberry is now illustrated rather than a tiny emoji when its art is installed.
- Unlock notifications use a nonblocking timed toast, with no full-screen interruptions during Strawberry Nightmare.
- Gameplay board max width grows from \`width - 48\` to \`width - 24\` on 393-point-class devices; touch/collision geometry remains unchanged.
- Full 18-piece approved toolbar and seasonal-frame catalog; 10 approved board concepts with 10 lightweight per-cell textures; ten 512px collectible block PNGs.
- Original bundle ID \`com.valentinebsaa.berryblockblast\`, iOS 16.0 minimum, user savings keys, original 51 M4As and 16 WAVs are preserved.

## Exact artwork reproducibility

GitHub's connected text-file API does not directly upload a binary archive. The **complete unsigned iPhone test IPA distributed in ChatGPT already includes all 48 PNGs**, verified individually.

To reproduce a native, asset-catalog-compiled IPA with GitHub Actions, upload exactly \`BerryBerryBlast_0512_Production_Assets.zip\` into \`BuildPayload/\` on branch \`feature/berry-berry-blast-0512-reward-garden-test\`. Its expected SHA-256 is:

\`eb874b9de8d757fdb6451275dd8d2d9cca9f34aca0cc57c54f6cffdc859d75ad\`

The file \`StrawberryShortcakeBlockBlast/Tools/install_art512.py\` verifies the archive and all 48 image hashes. The workflow \`.github/workflows/berry-0512-complete-art-build.yml\` then compiles the simulator and device app and publishes an unsigned IPA. Do not remove this verification gate or claim missing art is present.

The smoke-build workflow intentionally excludes the new art **only until local assembly**, so it must not be mistaken for the full visual candidate.

## Build and QA

- Native Swift 5 simulator and device builds succeeded in GitHub Actions run #44282855555.
- Verified final locally assembled test IPA: 0.5.12 (1), iOS 16.0, all 48 image PNGs, original 51 music tracks and 16 sound effects with matching bytes, no altered bundle ID.
- Six focused trophy XCTest cases are included; use the dedicated \`berry-0512-trophy-tests.yml\` workflow to execute them.
- Signed installation and **physical device testing** on iPhone 14 Pro and iPhone 16 are still required. The app is unsigned and cannot be installed directly without a compatible install/signing method.
- Before updating an existing installation, back up game data. Keep 0.5.10 Build 2 and 0.5.11 for rollback.

## Manual tests

1. Check all four in-game toolbar images; Pause/Home/Settings/Help still work.
2. Verify 8x8 and 12x12 board size and hitboxes on both phones without clipping tool controls, including 24x24 Endless sections.
3. Compare each seasonal frame with Original; no overlay captures touches or changes the puzzle rules.
4. Open all 10 board-concept previews and selected surfaces; no stretched, text-covered gameplay grids.
5. Verify the legacy Red Strawberry unlock is still owned and now uses the full illustrated candy tile.
6. Open the two-column Trophy Garden: locked progress, higher requirements, special dual-condition trophies, switching skins, persistence after restart and no duplication with Undo.
7. In Nightmare, confirm a reward toast never interrupts the clock, and an early board lock does not count as surviving.
8. Check wallet, purchases, audio, Story progress and saves survive updating.
