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

## B32 tranche 04 — persistent local activity
- [x] SOURCE: mail and timer arrivals create persistent deduplicated activity records; limited authored replies to first supported community comments are delayed, saved, and honor app notification/mute preferences. Notification center, redacted locked-phone activity, foreground app banner, tap route and dismissal; uses shared tactile profiles, no real push/network. Existing Messages notifications preserved. New tests authored, not executed.
- [ ] Remaining shared notification producers (calls, voicemail, broader social, Motionwell, Dayblink, HavenWatch), full per-app history/read/badges, private gate audit, narrative, asset intake and integrated testing remain OPEN. No workflow dispatch, no IPA. All prior Build 32 requirements remain mandatory.

## B32 tranche 05 — independent community and media presentation
- [x] SOURCE: assign all 18 previously bundled CC0 synthetic portraits to 18 independent accounts; add nine accounts and 18 posts (78 historical posts total), six public everyday image posts from existing verified CC0 media, app account directory/search/following list, profile photo grid and photo discussion view. Four fictional organization monograms are in-app typographic fallbacks, not final logos. Exact media/post allowlist preserves Nora photo gates. Tests and assignment manifests updated; CI not run.
- [x] SOURCE: tighten activity mail presentation when archived/trashed; make array conversion explicit. No hardware/CI claim.
- [ ] Actual casual selfies, final branded art, further reserve conversion and assignment, richer contextual conversations, HavenWatch/Motionwell/Dayblink, private narrative and complete integration remain open. Asset bookkeeping: 42 portrait/avatar assets in the prior tally plus six separately acquired CC0 everyday photos = 48 acquired files across those categories, not 48 accounts. No new release build.

## B32 tranche 06 — HavenWatch archive
- [x] SOURCE: five camera archive views, 10 approved fixed-view stills, activity list, bookmarks, zoom, infrared-style display, simulated arming and saved preferences. Launcher entry in Little things folder, restore gate, no invented capture times or real connections. Local V2 ZIP CRC checked and all 10 frames visually reviewed; exact archive SHA and manifest hashes pinned in importer; release workflow intake and catalog/test coverage added. Importer execution and native CI still pending. No live security events or haptic delivery falsely claimed.
- [ ] Confirm exact GitHub release bytes at eventual CI, run importer and full native tests, align cross-room continuity and private story timestamps, connect authored security events and notification preferences to scheduler. No V1 draft usage; no release until all B32 gates complete.

## B32 tranche 07 — Dayblink visual messaging and approved social icon intake
- [x] SOURCE: Dayblink launcher, three friendship profiles, restored visual-message conversations, saved memories, expired historical items, local Repair desk messages, limited authored delayed visual replies, one-view consumption persisted, mute/privacy settings, activity history and shared social haptic routing. Reuses three licensed public illustrations, no owner photos or real camera/contacts/location. App badge counts now derive from active app activity. New tests authored, not compiled.
- [x] ASSET PREP: original approved Dayblink and Motionwell icons packaged locally; exact ZIP and per-image SHA pinned in required importer and CI catalog checks. Icon ZIP must be uploaded to L1 before any build. No substitute icon considered release-ready.
- [ ] Dayblink active authored stories, richer interaction and media, narrative alignment, broader notifications, Motionwell functional playback, remaining app scope and native testing remain OPEN. No workflow dispatch or IPA. Preserve all previous gates.

## B32 tranche 08 — Motionwell local video platform
- [x] SOURCE: Motionwell launcher, Home/Shorts/Following/Saved/History filters, search, native AVPlayer playback, creator channels, subscriptions, likes, saved items, local comments, playback-derived resume/history, account and persisted notification preferences. Folder layout adapts to four apps. No fabricated view counts, actual network, video capture or owner impersonation. Tests added, native compilation pending.
- [x] ASSET PREP: four original silent photo-essay recipes (12, 12, 30 and 60 seconds), using six already verified CC0 source images; ffmpeg H.264 MP4 generation and ffprobe validation wired into eventual CI, resource hashes checked in app and IPA. Actual MP4 encoding has not yet run. Explicitly labeled photo essays, not genuine recorded footage.
- [ ] Approved icon ZIP still absent from L1 as of latest check; must upload exact archive. Authentic filmed clips, longer editorial/business videos, channel notifications, richer authored comments and narrative integration remain open; no new uploads falsely claimed. Full regression/physical QA and story completion still required. No build triggered.

## B32 tranche 09 — contextual conversations and timing
- [x] SOURCE: 15 ordinary conversation topics spanning seven known contacts; three authored topic turns apiece, contact-specific greetings/acknowledgements, contextual follow-ups limited to immediately preceding same-contact authored topic, recent-reply avoidance, bounded separate read/typing/delivery timing, persisted pending typing time with backward-compatible decoding. Preserve investigation and private-access responses, tutorial gate now rejects common negated/quoted/question repair reports. Delayed regular replies retain scheduled timestamps on resume. Tests added, not run. No new plot facts or access grants.
- [x] ASSET PRESENCE: exact expected Social Icons Approved ZIP filename now present in L1 (2,510,720 bytes); archive and individual hashes still verified by eventual importer.
- [ ] Broader paraphrases, multi-topic handling, more natural character availability and historical thread expansion, full confidential narrative and route integration, voice/Relay/Patchline/notification depth, native and physical testing remain OPEN. No release workflow triggered.

## B32 tranche 10 — Voice Memos and typed Luma Assistant
- [x] SOURCE: restored memo catalog with four ordinary authored transcript drafts, search, dates, native AVAudioPlayer play/pause/seek for supplied audio, transparent missing-audio fallback, interruption/background handling; approved Voice Memos icon mapped. Luma Assistant launcher and Control Center shortcut, original reduced-motion orb, typed/quick actions, bounded app navigation and local unread/time/calendar/timer/settings/package status/hints with explicit gate checks. No microphone or network use, no protected answers or state mutation. Initial four memo and six fixed assistant clip scripts organized in VoiceAssets/initial_scripts.json. Tests authored, not run.
- [ ] W12 still OPEN: voice selection/approval and actual recordings, manifest and bundling validation, expanded/gated authored memos, on-device opt-in speech input and full audio coordination, hardware/airplane-mode tests. No claim of generated voice or microphone support. Other B32 acceptance gates remain mandatory. No workflow dispatch.

## B32 tranche 11: Relay package compatibility and Patchline diagnostics
- [x] SOURCE: two functional local packages (Slate Dock and Preview Shield), explicit core requirements and symmetric dock conflict, final-state transaction checks allow removal/replacement in one queue, queue-specific error messages, current-version upgrade rejection at confirmation and commit, gate-aware launcher tweak activation, safe-mode/conflict status, publisher/compatibility details, real loader diagnostics and orphaned-source status. Transaction animation now says pending until commit. Tests added, not compiled. Preserve three core packages and existing IDs/preferences.
- [ ] W11 remains open for complete runtime/checkpoint audit, polished source index and per-package artwork/metadata, optional repository depth, full native tests and physical QA. No release triggered. All other B32 requirements remain mandatory.

## B32 tranche 12: varied workstation diagnostics
- [x] SOURCE: three additional playable local diagnostic families (signal alignment, configuration diagnosis, dependency sequencing) alongside the two existing exercises; visual and numeric trace equivalents, toggles and touch reorder controls, explicit instructions, optional three-stage hints, stable versioned IDs, persistent partial state, bounded input validation, reset, immutable verified state and idempotent completion. Two valid independent operation orders supported. Existing save keys and completed exercises unchanged; no real hardware operations or plot access grants. Added regression tests; native compile/testing not run.
- [ ] These exercises use neutral service samples, not canonical story evidence. Narrative puzzle contexts, earned rewards and cross-app provenance/timeline reconciliation, broader utility certification variety, dependency graph and end-to-end story reachability remain open. No build dispatched.

## B32 tranche 13: cross-app investigation continuation
- [x] SOURCE: gated next investigation sequence connects existing browser review to delayed authored Mail, explicit message opening, a persistent three-source comparison, validation and idempotent follow-up correspondence. Added progress tracker Mail route, hidden page and delivery gate, activity journal integration and save round-trip/negative-path tests. Existing chapter milestones retained. No plot answers included in creator-facing reports. Source not compiled or run.
- [ ] This is a chapter extension, not the ending or full causal narrative. Remaining confidential chapter/ending design, alternate paths, source consistency review, voice and media, notification breadth and native verification are OPEN. No workflow dispatch.

## B32 tranche 14: confidential resolution path
- [x] SOURCE: additional gated narrative records, separate delayed authored correspondence, ending decision with two persisted outcomes, idempotent completion, post-completion exploration, updated tracker and known-contact response adjustment. Developer-only causal draft and neutral-facing regression coverage; exact plot not reported to creator. No compulsory images or optional paid/utility gates. Native compile and actual playthrough pending.
- [ ] Full narrative acceptance still OPEN: expand pacing, cross-app evidence and private material, audit every contact and pending reply after completion, alternative routes, complete atmosphere and ending polish, end-to-end gate testing. All other B32 requirements retained; no build dispatched.

## B32 tranche 15: authored archive atmosphere and locked activity routing
- [x] SOURCE: one gated, delayed, persistent HavenWatch index event, with distinct security tactile routing, optional corrupted sound (ordinary cue fallback with horror effects disabled), redacted notification and archive history available even when alerts are muted. Explicit capture-time uncertainty and no new camera footage. Lock-screen activity selection now retains its destination through successful unlock; clears on cancellation/failure/ordinary unlock/checkpoint. Regression tests authored, not run.
- [ ] Remaining W01–W14 and B32-01–10 gates remain OPEN: notification queue breadth, ordinary and atmospheric narrative pacing, real audio/video assets, voice and remaining continuity, integration and verification. No native compilation or release dispatch.

## B32 tranche 16: integration corrections
- [x] SOURCE: bounded FIFO presentation of foreground app notifications rather than overwriting each banner in a batch, stale/dismissed notice filtering, lock/background/checkpoint queue clearing, mutually exclusive message/app/utility/recovery overlays, revalidation of pending dialogue whose authored context changed, prerequisite-chain checks for late browser pages, exact source Git blob verification before video encoding. Added focused regression tests; native compile and execution not performed. Ordinary notification history remains persisted independently.
- [ ] This is a targeted source review, not a complete code audit or CI pass. Banner preemption/expiry, checkpoint UI behavior, pending dialogue coverage, voice assets, media encoding, full storyline playthrough and all B32 gates remain to verify. No workflow dispatch.
