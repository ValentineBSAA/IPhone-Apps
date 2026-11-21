# 🍓🧭 Berry Berry Blast | H1-B04 More Adventures Seasonal Home Icon Checklist

**Opened:** November 20, 2026. **Branch:** `artwork/berry-seasonal-more-adventures-h1-b04`. **Source category:** 04/HOME in `SEASONAL_MASTER_ICON_BATCH_MATRIX.md`.
**Status at creation:** 0/8 generated, 0/8 owner approved, zero H1-B04 source PNG binaries committed.

## Semantic ground truth from app source
In `BerryModes.swift` Home screen, **More Adventures** uses `BerryGridNavigationTile(title: "More Adventures", art: "MoreAdventures", caption: "Explore")`; tapping opens `showMore` and lets the player choose **Berry Blitz**, **Cozy Cottage**, or **Strawberry Nightmare**. It does not start a single book/calendar or automatically change a game mode.

**Design the actual function:** one distinctive strawberry-themed crossroads/garden gateway showing **three routes/options**; the scene may suggest blitz energy (a tiny lightning-star emblem), a cozy miniature cottage, and a playful mysterious moonlit path. The centerpiece must remain readable as **exploration/choices** at 64/96px. No actual text, fixed numbers, button labels, trademark characters, or fake menus inside the PNG. Seasonal celebrations and lighting are decorative around the same silhouette.

## Source/render/QA contract
1. **Generate exactly ONE original image per owner review**, in sequence below (Day, then Night for each event), not a multi-icon source collage.
2. After owner explicitly approves a design, mark its visual approval. Source original PNG bytes are immutable and distinct from alpha processing.
3. Keep all originals in `StrawberryShortcakeBlockBlast/ArtSource/SeasonalGarden/<Holiday>/<Day|Night>/Originals/Season_<Holiday>_<Day|Night>_MoreAdventures_Original.png`.
4. Create separately processed `RGBA_Candidates` only after visual approvals; visually inspect true transparent edges and any baked checkerboard on light, dark and checker backgrounds, plus small 64/96px readability.
5. Package eight original PNGs, SHA-256 JSON/CSV manifest, checker/light/dark and mobile-size contact sheets in a deterministic ZIP. GitHub binary staging is a separate gate through verified ZIP import.
6. Do not alter existing original 40 Night Garden icons and RGBA, 10 approved clock frames, 8 Berry Story icons, 8 Daily Harvest icons, initial cottage series, current game modes, Xcode assets, saved state or cosmetics.
7. Xcode game integration and in-app holiday calendar activation stay isolated and require device acceptance.

## Eight individual artwork reviews

| ID | Event | Appearance | Distinctive theme and fixed semantic shape | Original image | Owner visual approval | RGBA QA | PNG in GitHub | Xcode/iPhone |
|---|---|---|---|---|---|---|---|---|
| MA-01 | Halloween | Day | Sunlit autumn garden crossroads, pink strawberry signpost with three icon-only routes, friendly pumpkin-berry, orange/purple gingham, strawberry blossoms | ⬜ NEXT | ⬜ | ⬜ | ⬜ | ⬜ |
| MA-02 | Halloween | Night | Moonlit violet garden crossroads with same three choices, tiny golden stars, lit berry lanterns, friendly ghosts and pumpkins | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| MA-03 | Christmas | Day | Snowy red-green berry pathways, small decorated cozy cottage, gold adventure star, snow-topped strawberry signpost | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| MA-04 | Christmas | Night | Indigo snowy forked paths, warm lit cottage and twinkling Christmas trees, berry lights and crescent | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| MA-05 | Thanksgiving | Day | Amber harvest three-path signpost, maple leaves, pumpkins, berry pie, berry harvest basket | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| MA-06 | Thanksgiving | Night | Candlelit plum/gold garden fork, moonlit pumpkin-berry lanterns, pie and autumn foliage | ⬜ | ⬜ | ⬜ | ⬜ |
| MA-07 | Birthday | Day | Festive pink garden three-way signpost, strawberry cake, present, balloons and gold chapter-style star | ⬜ | ⬜ | ⬜ | ⬜ |
| MA-08 | Birthday | Night | Lavender birthday crossroads, moonlit bunting, candle glow, balloons, strawberry confetti | ⬜ | ⬜ | ⬜ | ⬜ |

## Gates and milestones
- [x] Verify actual Home tile semantics and `MoreAdventures` asset lookup in existing SwiftUI source.
- [x] Create isolated H1-B04 branch and running checklist.
- [ ] Generate **MA-01 Halloween Day** as one standalone original; request explicit visual approval.
- [ ] Continue MA-02 through MA-08, one image/owner approval at a time.
- [ ] Prepare non-destructive original/RGBA QA ZIP, source hashes, previews and per-image approval manifest.
- [ ] Verified GitHub Release importer, stage original binaries and inspect results.
- [ ] Separate seasonal runtime integration, fallback, real device iPhone UI/QA and save/regression tests.

## Previous family handoff (unchanged)
- **Daily Harvest H1-B03:** 8/8 visual designs approved; ZIP SHA-256 `e3171cb083d3faf1062dd4d75844082a61506cbe5e3491543370f61fcf59cd24`; five native RGBA and three alpha candidates (DH01, DH03, DH07) require edge review. Release importer installed on main, binary import still awaiting owner release upload.
- **Berry Story H1-B02:** 8/8 visuals approved, source/alpha QA archive prepared, binary import separately pending.
- **Clock frames:** 10/10 visually approved; source and alpha review archive separately staged for owner release upload.
- **H1-B01 cottage originals:** 8 approved PNGs already imported on separate seasonal art branch; do not modify.
- **Night Garden:** previous 40/40 original and RGBA visual approvals retained, with runtime integration still pending.

Links: [Seasonal icon matrix](SEASONAL_MASTER_ICON_BATCH_MATRIX.md) · [Daily Harvest checklist](DAILY_HARVEST_SEASONAL_ICON_CHECKLIST.md) · [Seasonal epic #42](https://github.com/ValentineBSAA/IPhone-Apps/issues/42).
