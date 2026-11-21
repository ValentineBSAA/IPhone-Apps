# Berry Berry Blast | NIGHT GARDEN artwork master pack

**40 of 40 owner-approved, standalone AI-generated icons** across eight batches. All original PNG bytes preserved, no cropping, recoloring, alpha removal, or generative substitutions. Batch 2 uses the approved **REDO**, not the rejected first draft. Batch 8 includes the final standalone **Night Build Information**.

## What this is
- Repository-aligned **art source handoff** for Berry Berry Blast, branch `planning/berry-night-garden-overhaul-v47-v48`.
- `01_Original_Approved_PNG/Batch_*`: exactly 40 approved images, grouped by the original eight batches.
- `02_Previews`: contact sheet for all 40 plus one contact sheet per batch (previews only; never import them as icons).
- `00_README/ARTWORK_MANIFEST.json`: unique image names, proposed Xcode asset paths, stages, original source archive, image mode, dimensions, SHA-256 and current import/routing status.
- `00_README/GITHUB_ASSET_IMPORT_LEDGER.csv`: spreadsheet-compatible audit for the S1 register (issue #24).
- `00_README/SHA256SUMS_Original_PNG.txt`: verify image bytes after upload/extraction.

## Exact verified sources
All eight approved batch archives were opened and all 40 original images decoded and verified at 1254×1254. The last original source is `magical_berry_build_blueprint.png`. Image sources **are not** sheet crops.

## Important Xcode integration warning
Owner visual approval does **not** mean Xcode runtime integration is complete. Most images are RGB with designed/background pixels (some may show an embedded checkerboard). The majority are **not true-alpha** overlays. Keep originals immutable and do a separately reviewed transparency/edge pass where needed; do not make unapproved automatic masks. Then create new `.imageset` folders in `StrawberryShortcakeBlockBlast/BerryBlockBlast/Assets.xcassets` using the manifest's exact `asset_name`, with a `Contents.json`, and test night routing on iPhone **16e only**.

The repo currently already includes 30 older `Night_*` asset sets and the approved `Night_Approved_Night_Market_Storefront`. **Those older assets are NOT replaced and are not included again here.** The older `Tools/import_night_assets.py` is restricted to exactly 30 RGBA day-matched sets: it **cannot** import this new 40-icon art pack as-is. Do not run the existing Nighttime GitHub Actions importer with this ZIP. The source files are grouped rather than masquerading as imported `.imageset`s.

## Stage mapping according to GitHub roadmap
- Batches 1–4: S4 / Build 4.8 (Home, discovery, modes, shop entry).
- Batch 5: S4 / Build 4.8 (Settings menu visual parity).
- Batch 6: S3 / Build 4.7 (real semantic Undo, Shuffle, Hint, Stats, Tools, Boutique toolbar).
- Batch 7: S5 / Build 4.8 (day/night special tool illustrations). **Distinct Night Market-only merchandise is a separate Build 6 backlog and is not yet designed.**
- Batch 8: developer QA tooling art only. The debug wallet must never ship in public builds.

## Scope is intentionally limited
This completes the original 40-icon **art approval** list, not every background, digital clock, board block, animation, nighttime gameplay mode, chapter/story or Night Market item. Those remain organized under GitHub Night Garden epic #23 and related issues S1–S7, N1–N4. See the repository roadmap. Do not mark the 4.7/4.8 implementation or release test gates complete solely because these PNGs exist.

## Suggested destination when uploading to GitHub
`StrawberryShortcakeBlockBlast/ArtSource/NightGarden/Approved_40_Icon_Batches/`

Upload this content to the planning/artwork branch as source material, then integrate selected images via a **separate draft PR**. Keep all original daytime sprites, the previously imported 30 night sprites, game saves, prices, 51 m4a and 16 wav intact. For production, keep the planned iOS 16+ target and iPhone 16e-only physical QA.

**Do not publish or merge a release from this asset ZIP.**
