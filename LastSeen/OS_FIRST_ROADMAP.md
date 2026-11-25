# LAST SEEN — master roadmap / spoiler-free status
Updated November 25, 2026. Start here. All previous requirements and specialist documents remain active; historical gates are superseded by the following current release contract.

## 1. Release gate and next milestone
**CURRENT GATE — Build 32: Living Phone / cohesive upgrade (November 25, 2026).** Creator explicitly authorized consolidated development and confidential story expansion. Build 31 is failed/superseded and will not be separately delivered or installed. Carry every outstanding B31 audio, lifecycle, packaging and hardware acceptance item into B32 alongside W01–W14 and the living-world scope. Target identity 1.9.0 (32); one player-facing verified IPA only after complete integrated acceptance, no intermediate install requests. Internal CI runs are allowed as necessary after implementation; no premature release. This commit prepares roadmap and version contracts only; runtime feature and narrative implementation remain open. No spoilers in creator-facing status. See [BUILD32_EXECUTION_PLAN.md](BUILD32_EXECUTION_PLAN.md).

- [x] Build 31 native compilation and simulator tests passed; [run 45708950139](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/45708950139) failed at IPA packaging (stale 30/1.8.1 assertion in Tools/verify_device_assets.py). No IPA was published. Build 31 retired as standalone delivery, not as a source baseline.
- [x] Creator approved Build 32 consolidated scope, including full story authoring and all-app authenticity. No plot facts inferred from photographs.
- [x] B32 version contract and packaging verifier corrected in source; execution/CI verification still OPEN.
- [ ] Complete integrated B32 implementation and private narrative, mandatory CI, independent IPA verification and focused iPhone 16e QA.

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
- [ ] B31 corrective acceptance carried into B32: package verification / publication / independent IPA verification / physical QA and outstanding cue lifecycle coverage.
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
| W01 foundation/security/persistence | partial SOURCE | B32 corrective carryover; unified records and safe restore |
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
- [Build 32 execution plan](BUILD32_EXECUTION_PLAN.md): sole current release contract and ordered acceptance checklist.
- [Consolidated W01–W14 checklist and asset lock](CONSOLIDATED_NEXT_BUILD.md): detailed requirements; historical logs are not current gates.
- [Living Phone Authenticity](LIVING_PHONE_AUTHENTICITY_ROADMAP.md): next priority, acceptance criteria and HavenWatch integration.
- [Connected World](CONNECTED_WORLD_ROADMAP.md), [Psychological Horror and Living Notifications](PSYCHOLOGICAL_HORROR_AND_LIVING_NOTIFICATIONS.md): approved feature requirements.
- [Audio corrective release](AUDIO_CORRECTIVE_ROADMAP.md), [Build 27 acceptance](BUILD27_ACCEPTANCE.md), [Browser](BROWSER_CHAPTER_ROADMAP.md): release-specific evidence.
- [Feature requirements](FEATURE_REQUIREMENTS.md), [Relay](RELAY_MODERNIZATION_ROADMAP.md), [Puzzles](PUZZLE_DESIGN_ROADMAP.md), [Statistics](GAMEPLAY_STATISTICS_ROADMAP.md), [Assistant](LUMA_ASSISTANT_ROADMAP.md), [Documents](WORLD_DOCUMENTS_01.md), [Icons](CONNECTED_WORLD_ICONS_01.md), [Photos](WORLD_PHOTOS_EXPANSION_01.md): inherited requirements remain active.
- Developer-only narrative/continuity files retain canon. Do not include plot outcomes, identities, puzzle solutions or future revelations in ordinary reports. Prior master snapshot and all history files retained.

## 5. Delivery discipline
Offline fictional LumaOS, iOS 16 minimum, iPhone 16e primary. No real device changes, accounts, surveillance, actual messaging or runtime API dependency. Preserve all save formats and approved features; no redundant apps. Deliver one verified installable IPA per cohesive milestone, never weaken mandatory tests, and distinguish source, asset, CI and hardware results. Narrative completion is essential; avoid indefinite OS expansion.

## Build 32 implementation tranche 01 — historical living-world content
- [x] SOURCE: 30 additional historical social posts, 36 comments/replies and 22 historical mail records (11 sent); studio promotion, personal and community activity. Stable restored-world gate, no new progress flags, historical dates and local repair-desk identity. Comments merged with local replies; historical mail presented as read. Existing privacy gates retained.
- [x] SOURCE: initial everyday reply branches and immediate-repeat guard for secondary contacts. New regression tests added; not run yet.
- [ ] Full conversation context, natural scheduler, confidential story completion and all integrated CI remain OPEN; no interim install.

## B32 tranche 02 — device haptics and feedback routing
- [x] SOURCE: independent audio and tactile delivery; distinct incoming text and mail profiles; bounded alert-only haptic queue; no keypad interruption of an active alert; Core Haptics reset recovery and UIKit fallback; separate mail and vibration-only previews; passcode feedback routed through shared engine. Existing timer and authentication paths preserved. Newly delivered local inbox IDs, not restored mail or folder changes, trigger mail feedback. Regression tests authored, CI/device testing OPEN.
- [ ] Connect future authored incoming calls, voicemail, social, Dayblink, Motionwell, HavenWatch, and other notification categories to the common event scheduler and appropriate tactile profiles. Social/security profiles prepared but no new event producers falsely marked integrated. Do not vibrate for browsing old history, ordinary read/dismiss, re-opening or fake activity. Verify physical iPhone 16e with sound off/haptics on, haptics off/sound on, foreground arrivals, concurrent alerts, keypad/auth, timer, lock-screen simulation and resume; respect system haptics settings. No real background vibration or hardware claim until tested.

## B32 tranche 03 — researched app authenticity
- [x] SOURCE: nine independent community profiles/18 posts, account settings entry, Nora and studio profile access, saved per-app mute and notification preferences; Relay repository browsing, wishlist/refresh time, Patchline environment/package activity. Tests added; no CI/device claim.
- [ ] Complete remaining research-backed scope in [BUILD32_AUTHENTICITY_RESEARCH.md](BUILD32_AUTHENTICITY_RESEARCH.md), including scheduler integration and original assets. No separate install.

## B32 community portrait intake 01
- [x] SOURCE: 18 existing CC0 synthetic 256px portraits visually reviewed and imported unchanged into the asset catalog; 9 assigned to existing independent social accounts and 9 reserved. Per-image source revision/blob hash, license and assignment manifest in CommunityPortraits. Compiled catalog verifier and XCTest coverage added. No image generation, external runtime dependency or changes to established character art.
- [ ] More varied casual portraits, older adults and non-face avatars; 100-account target not yet fulfilled. CI and physical review remain OPEN.

## Community media intake 02
- [x] SOURCE: six CC0 non-face photographs acquired, individually reviewed and bundled as unassigned candidates, with provenance. 18 prior synthetic portraits retained. See CommunityPortraits/MEDIA_INTAKE_02.md.
- [ ] Larger synthetic portrait collection downloads, older adults, casual portraits, original business identities and actual use in feeds remain open. CI/device QA pending.

## Community portrait intake 02
- [x] ACQUIRED: ten additional synthetic adult portraits, including older-looking adults; source WebP originals, provenance, Apache-2.0 license and upstream NOTICE retained. 28 portraits acquired overall, nine assigned in source. These ten are reserve artwork, not yet bundled or assigned.
- [ ] Casual environmental selfies, pet/hobby avatars and organization artwork remain open. Do not imply 100 accounts completed.

## Community artwork intake 03
- [x] ACQUIRED: four more synthetic adult portraits, four illustrated pet/hobby avatars, six illustrated creator/business profile candidates, source hashes and license files retained. 42 assets acquired overall; 9 assigned in source, remaining reserves not integrated. Generic artwork is not a custom business logo.
- [ ] Eight OpenPeople casual selfies reviewed and linked in manifest; conflicting license/disclaimer must be resolved before distribution. Original brand identities, asset bundling, assignment and CI remain open. See CommunityPortraits/Intake03.
