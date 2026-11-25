# LAST SEEN — master roadmap / spoiler-free status
Updated November 25, 2026. Start here. Current priorities supersede old planning gates; all earlier approved requirements are retained in specialist documents, the consolidated W01–W14 checklist, and [prior master snapshot](ROADMAP_HISTORY_2026-11-25.md). This is a documentation-only update, not authorization to silently change runtime or cut scope.

## 1. Release gate and next milestone
- [ ] Finish 1.8.2 (31) corrective release first. Runtime ed33ea265d4b5c45309e0be9da93efcefa9aecba; [run 45708950139](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/45708950139) FAILED at packaging, after native build and simulator tests succeeded. Job 139538074455 logs identify Tools/verify_device_assets.py line 43 still asserting 1.8.1 (30). Correct the version contract without weakening verification, audit other stale constants, rerun mandatory CI, independently extract/verify unsigned IPA, then focused iPhone 16e audio/Face ID QA. See [audio corrective spec](AUDIO_CORRECTIVE_ROADMAP.md). No Build 31 IPA published by failed run.
- [ ] **Next creative/engineering priority: Living Phone Authenticity.** Make all existing conversations and apps feel like the owner has a real ongoing everyday digital life. Creator's impression from approved photos is that the phone looks actively used; preserve this impression/uncertainty as a design goal, not a plot fact. See [LIVING_PHONE_AUTHENTICITY_ROADMAP.md](LIVING_PHONE_AUTHENTICITY_ROADMAP.md). Plan and author confidential content while stabilizing the corrective build; integrate in the next cohesive release after the gate. No new runtime build triggered by this roadmap edit.

## 2. Verified completion ledger
Checkboxes denote only the exact bounded item stated, not whole feature acceptance. SOURCE = initial implementation; CI PASS = exact step or run; DEVICE PASS/PARTIAL = creator report; APPROVED = artwork/direction; UPLOADED = release asset metadata; OPEN/BLOCKED = unfinished. Never infer physical success from CI or asset integration from upload.

### Foundation and released baseline
- [x] Native iOS foundation, opening/setup, simulated jailbreak/recovery, lock and owner-security source implemented; B27–30 compiled/tested as documented. Detailed acceptance remains open where not physically reported.
- [x] B27 initial launch and custom messages observed by creator (partial QA); Relay correction CI passed, run 45604001618. Physical transaction correction still open.
- [x] B28 initial browser slice CI passed, run 45687303359.
- [x] B29 1.8.0 CI passed, run 45692871585; creator installed and reported no game-breaking issues, launcher clipping found.
- [x] B30 1.8.1 CI passed, run 45700584903, artifact 15064780181; delivered. Creator confirmed Face ID reaches home but unlock sound missing. Horizontal launcher pages, folders, dock and layout correction in source; full physical regression open.
- [x] Initial W04 save statistics, W07 document reader, W06 local Mail, W09 three social feeds, W10 workstation diagnostics, W11 optional source indexes/tweaks implemented in B29 tranche source and B29/B30 CI baseline. Not full-scope acceptance.
- [x] B31 four new original audio assets received, decoded and matched to release L1; corrective source committed, native compile and simulator-test steps succeeded.
- [ ] B31 package verification / publication / independent IPA verification / physical QA and outstanding cue lifecycle coverage.
- [ ] Full OS polish, unified security/persistence, complete utility coverage and accessibility.

### Artwork and media
- [x] Original ten L1 asset uploads and four additional phone sounds recorded; see consolidated asset lock.
- [x] Motionwell and Dayblink standalone icon concepts approved in chat; binaries/import and playable app slices OPEN.
- [x] Expanded romantic/late-night photo concepts created and approved in chat; separate continuity review, file intake and actual game integration OPEN.
- [x] HavenWatch app icon approved; V1 draft pack uploaded and local ZIP CRC/hash match verified (24 entries, 19 cleaned draft photos; not canonical).
- [x] HavenWatch V2 approved: five empty reference environments plus five matching occupied stills, one app icon, manifest and README. Local ZIP CRC and all 11 manifest file hashes match; GitHub L1 digest matches local archive.
- [ ] V2 camera pair/floor-plan continuity QA and canonical media catalog integration; V1 supplementary drafts only, not interchangeable fixed-view footage or evidence.
- [ ] New authored clips/voice recordings and remaining media approval/intake.

### Living world
- [x] Approved psychological-horror direction, ordinary/romantic everyday world, notification system and media expansion documented. No plot answers here.
- [x] Initial Afterframe, Connective, CommonGround source: local feeds/profiles/reactions/follow/save/comments; initial local Mail and document reader exist.
- [ ] Authenticity pass across Messages, Phone, Contacts, Mail, social apps, Photos, Notes, Files, Browser, Calendar, Clock, notifications and other existing apps.
- [ ] Motionwell and Dayblink functional local slices; HavenWatch functional simulated camera archive.
- [ ] Shared local event scheduler, notification history, contextual character responses, persistent cross-app state, natural ordinary activity, privacy and access-gate tests.
- [ ] Complete confidential narrative, puzzles, optional assistant/voice, and full end-to-end release acceptance.

## 3. Workstream priorities
| Workstream | Status | Current next action |
|---|---|---|
| W01 foundation/security/persistence | partial SOURCE | B31 gate; unified records and safe restore |
| W02 artwork/records | partial SOURCE; uploads verified | canonical intake, continuity, actual bundle checks |
| W03 OS and utilities | partial SOURCE | preserve shell, finish cross-app consistency |
| W04 saves/statistics | initial SOURCE | transactional restore, timing and migration QA |
| W05 world/narrative | partial SOURCE | authenticity authoring; confidential canon |
| W06 communications | initial SOURCE | contextual conversations and natural delivery |
| W07 documents | initial SOURCE | deeper records, gate and reader QA |
| W08 browser | initial CI PASS | expand believable browsing and cross-links |
| W09 social | three initial SOURCE; two approved | enrich existing apps first; add bounded new slices |
| W10 repair/puzzles | initial SOURCE | preserve, diversify and test |
| W11 Relay/tweaks | initial SOURCE | preserve and finish approved backlog |
| W12 voice | partial artwork / OPEN | approved recordings and offline assistant |
| W13 investigation/gameplay | partial SOURCE / OPEN | narrative integration, fair progression |
| W14 release | OPEN | mandatory tests, exact IPA, iPhone 16e QA |

## 4. Source of truth
- [Consolidated W01–W14 checklist and asset lock](CONSOLIDATED_NEXT_BUILD.md): detailed requirements; historical logs are not current gates.
- [Living Phone Authenticity](LIVING_PHONE_AUTHENTICITY_ROADMAP.md): next priority, acceptance criteria and HavenWatch integration.
- [Connected World](CONNECTED_WORLD_ROADMAP.md), [Psychological Horror and Living Notifications](PSYCHOLOGICAL_HORROR_AND_LIVING_NOTIFICATIONS.md): approved feature requirements.
- [Audio corrective release](AUDIO_CORRECTIVE_ROADMAP.md), [Build 27 acceptance](BUILD27_ACCEPTANCE.md), [Browser](BROWSER_CHAPTER_ROADMAP.md): release-specific evidence.
- [Feature requirements](FEATURE_REQUIREMENTS.md), [Relay](RELAY_MODERNIZATION_ROADMAP.md), [Puzzles](PUZZLE_DESIGN_ROADMAP.md), [Statistics](GAMEPLAY_STATISTICS_ROADMAP.md), [Assistant](LUMA_ASSISTANT_ROADMAP.md), [Documents](WORLD_DOCUMENTS_01.md), [Icons](CONNECTED_WORLD_ICONS_01.md), [Photos](WORLD_PHOTOS_EXPANSION_01.md): inherited requirements remain active.
- Developer-only narrative/continuity files retain canon. Do not include plot outcomes, identities, puzzle solutions or future revelations in ordinary reports. Prior master snapshot and all history files retained.

## 5. Delivery discipline
Offline fictional LumaOS, iOS 16 minimum, iPhone 16e primary. No real device changes, accounts, surveillance, actual messaging or runtime API dependency. Preserve all save formats and approved features; no redundant apps. Deliver one verified installable IPA per cohesive milestone, never weaken mandatory tests, and distinguish source, asset, CI and hardware results. Narrative completion is essential; avoid indefinite OS expansion.
