# 🍓 Berry Berry Blast · Seasonal Garden H1 · Batch 01

**Art selection:** Eight individual full-resolution, visually approved *concept originals* from November 20, 2026. Four events, each with a separate **Day** and **Night** image.

| Event | Day original | Night original | Visual review |
|---|---|---|---|
| 🎃 Halloween | `Season_Halloween_Day_HomeClassic_Original.png` | `Season_Halloween_Night_HomeClassic_Original.png` | 2/2 approved |
| 🎄 Christmas | `Season_Christmas_Day_HomeClassic_Original.png` | `Season_Christmas_Night_HomeClassic_Original.png` | 2/2 approved |
| 🍂 Thanksgiving | `Season_Thanksgiving_Day_HomeClassic_Original.png` | `Season_Thanksgiving_Night_HomeClassic_Original.png` | 2/2 approved |
| 🎂 Birthday | `Season_Birthday_Day_HomeClassic_Original.png` | `Season_Birthday_Night_HomeClassic_Original.png` | 2/2 approved |

**What the images depict:** glossy berry-and-pastry cottages, decorated separately for each event and lighting condition. They are *representative Home/Classic cottage illustrations*, not the full holiday UI or block-puzzle icon inventory. Their exact Home or Classic card use is still subject to call-site mapping and approval. Original generated resolution: **1254 × 1254** each.

## Approval versus deployment

- [x] All eight separately generated images aesthetically accepted by the owner in chat ("those look good").
- [x] Original image bytes and manifest SHA-256 checksums organized in the downloadable **22,072,457-byte ZIP**.
- [ ] Original PNG files copied to the GitHub branch (requires connected release ZIP ingest; **not present at the time of creating this ledger**).
- [ ] Transparent RGBA derivation and review, preserving originals byte-for-byte.
- [ ] 64/96px small-screen proof, disabled/selected state treatment and paired contrast review.
- [ ] Xcode .imageset creation and correct runtime routing.
- [ ] CI, iPhone 16e screenshots and physical acceptance.
- [ ] Merge/release approval.

### Upload to GitHub
1. In **ValentineBSAA/IPhone-Apps**, create a new GitHub release with tag **`seasonal-h1-batch01`**; use **Draft** until the exact archive has been attached.
2. Attach `Berry_Berry_Blast_Seasonal_H1_Batch01_8_Approved_Sources.zip`. Its SHA-256 **must** be `67bea35a6b8d6195d00a0aba2e3fdd7cecbcc473093d3cabeb74f39862bfc2c3`.
3. Publish the release; the default-branch release-import workflow can validate the ZIP and stage **only the eight expected original PNG files** on this isolated artwork branch.
4. Check the Actions report and verify all eight original paths and SHA checksums; only then mark GitHub image upload complete. If no Action triggers, rerun the workflow manually using `workflow_dispatch`.
5. Do **not** merge this draft PR to the live game. Keep the separate existing `artwork/berry-night-garden-40-rgba-staging` branch and Night Garden PR #40 untouched.

## Folder structure

```
StrawberryShortcakeBlockBlast/ArtSource/
  NightGarden/                     # Existing approved 40 Night Garden originals + 40 RGBA, separate branch
  SeasonalGarden/
    00_Specs_And_Ledgers/
      H1_Batch01_Manifest.json
      H1_Batch01_README.md
    Halloween/
      Day/Originals/Season_Halloween_Day_HomeClassic_Original.png
      Night/Originals/Season_Halloween_Night_HomeClassic_Original.png
    Christmas/
      Day/Originals/...
      Night/Originals/...
    Thanksgiving/
      Day/Originals/...
      Night/Originals/...
    Birthday/
      Day/Originals/...
      Night/Originals/...
    _Previews/
```

**Pending next batches:** define the complete semantic icon inventory per visible screen, including Home, modes, Village, settings, Shop, tool HUD, clock, board edge, Collection, quests, journal, school, birthday celebrations, and particle effects. Every necessary semantic icon gets a holiday-specific Day and Night treatment, using the same meaning and approved style without replacing the existing generic Day/Night art. Generate in small **4–8 separate-source-image batches** and separately track generated, approved, alpha, routed and device-accepted states.

References: [Seasonal roadmap](../../../SEASONAL_DAY_NIGHT_ART_ROADMAP.md), [epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42), [calendar PR #48](https://github.com/ValentineBSAA/IPhone-Apps/pull/48), and [preserved Night art PR #40](https://github.com/ValentineBSAA/IPhone-Apps/pull/40).
