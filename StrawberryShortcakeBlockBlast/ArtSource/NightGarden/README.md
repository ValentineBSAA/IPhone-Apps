# 🌙 Berry Berry Blast • Approved Night Garden artwork source staging

**Non-release artwork branch:** `artwork/berry-night-garden-40-rgba-staging`

The owner uploaded the exact approved 40-icon master ZIP as GitHub Release [V1 / Night Garden Master Artwork Pack](https://github.com/ValentineBSAA/IPhone-Apps/releases/tag/V1). The release byte digest is **SHA-256 `3d4785171fe9ffe5ca019b814bfeb4ceba0663e33362496b1782db5f7f0f807c`**.

## Stable directory convention

- `Approved_40_Icon_Batches/Batch_01_* … Batch_08_*`: **40 original, full-resolution PNGs, unchanged**.
- `Approved_40_Icon_Batches/_Provenance/`: release manifest, 40-file original checksums and owner approval metadata.
- `Approved_40_Icon_Batches/_Previews/`: original review contact sheets.
- `Approved_40_Icon_Batches/_RGBA_Preflight/`: alpha channel inspection ledger; source images **are not automatically transparencies**.
- Future approved derivatives, after review: `RGBA_Reviewed/<asset_name>.png` (separate from these sources; do not overwrite approved originals).

## Processing and release gates

1. Verify the V1 release's SHA-256 exactly, ZIP integrity, 40 individual names, per-PNG checksum, 1254×1254 image size and batch count with `Tools/stage_night_garden_40.py`. Refuse any different existing file.
2. Audit alpha. **Only real RGBA transparency is valid for overlays.** Black mattes, pale checkerboards baked into pixels and painted backgrounds require *different* edge treatments. Do **not** mass color-key the entire batch.
3. Derive RGBA candidates **as separate files**, manually review edges at 100% on black/white/day/night, assess preserved glass/shadows/glows, and inspect at actual iPhone 16e toolbar and Home tile sizes.
4. Add reviewed assets to *new* Xcode image sets only when artwork is accepted; map actual source use-sites in [Night Asset Matrix](../../NIGHT_ASSET_PARITY_MATRIX.md). Current 30 preexisting Night image sets and approved Night Market storefront remain untouched.
5. Test iPhone 16e, quick static asset mapping and full CI before any public release. Build 4.7/4.8 are visual stage milestones, not the separate Night Story/game mode/unique catalog release.

**This folder is art source and preparation only. No shipping app code, prices, saves, Story modes, Moonberry rules, or Day icons are modified here.**

See [40-icon approval ledger](../../NIGHT_40_ICON_ART_APPROVAL_LEDGER.md), [Night roadmap](../../BERRY_BUILD4_TO_BUILD6_NIGHT_ROADMAP.md), and [Night Garden epic #23](https://github.com/ValentineBSAA/IPhone-Apps/issues/23).
