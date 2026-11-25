# LAST SEEN — Development handoff
Updated November 25, 2026. Start here when resuming work in a new chat. This is a spoiler-light engineering handoff, not the story script.

## Current state
- Repository ValentineBSAA/IPhone-Apps; project LastSeen; active branch feature/last-seen-nora-photo-vault, based on feature/last-seen-custom-phone-sounds (PR 130).
- Last successful packaged release: 1.4.0 Build 23, GitHub Actions run 45570667413, artifact 15003326336. All CI steps passed. Build 22 is superseded. Target physical QA: iPhone 16e; minimum iOS 16.0. Actual unsigned IPA required, not source-only.
- Build 23 owner feedback: sounds work; haptics appear to work; active-thread banner is wrong; tutorial pacing needs review, but owner had not manually replayed it. No blanket QA approval.
- New canonical Nora portrait and camera-roll direction approved. Character continuity register and world bible govern future generations. Staged code: NoraPhotoCatalog.swift, RestoredPhoneBackup.swift owner portrait, PhoneWorldStore.swift persistent discovery flags, OwnerSecurityView.swift private album, PhoneLabView.swift gated gallery. Not yet compiled. Do not conflate staged code with verified release.
- Asset pack exists as Last-Seen-Nora-Photo-Pack.zip; all 16 images and manifest verified locally. L1 release checked: only sound ZIP present, Nora pack not yet uploaded. See CHARACTER_CONTINUITY.md for exact archive and file hashes. Do not trigger a build that silently uses placeholders or omits required art.
- Prior approved opening, welcome, setup, Relay, Patchline, simulated respring/reboot, four restart sounds and eleven custom one-shot phone recordings remain intact; no reset of unrelated saved state.

## Next build acceptance gates (proposed Build 24, version not yet committed)
1. Verify exact creator asset uploaded to private L1; import manifest-matched JPEGs as asset catalog entries. Retire old Nora images in all runtime routes, including legacy compatibility mappings; preserve other characters and story assets. Verify references, no missing images, correct physical profile and bubble portraits.
2. Staged photo recovery: separate authentication from individual discoveries; initial everyday selection only, future-gated content stays inaccessible until actual puzzles exist. Opaque replacement texture must not load source image behind it. No bypass via favorites, zoom, metadata, search, preview or relaunch. Persist discoveries through tutorial replay; confirm save migration and private-session re-lock. Gallery counts and accessibility labels must not reveal hidden content.
3. Authentic messaging: track visible thread accurately through navigation, modals and app lifecycle; suppress same-thread notification overlay but retain normal sensory feedback. Other threads still notify. Implement recipient-specific delivered/read state and typing/timed replies independent of local unread state. Canonical owner avatar on right, correspondent on left. Test sound sequence so outgoing clip, incoming clip and lock/unlock do not arbitrarily cut one another off; preserve explicit Stop and toggles.
4. Reactive conversation design: keep optional suggested replies, accept actual free text, bounded length, persist exact text; contact-specific responses grounded in current knowledge and evidence, handle unexpected input and clarification naturally. Do not claim general AI support before implementing/testing it. Offline-first evaluation; deterministic story gates independent of any generated dialogue; cannot unlock by typing an answer not earned. Preserve player-as-repairer premise and identities. Scope the first implementation deliberately rather than pretend unlimited replies.
5. Tutorial: replay with real custom audio, verify all required steps and persistence, provide natural follow-up and optional help without mandatory handholding. No forced story reset, no premature scare or reveal.
6. Regression: build metadata synchronized across project.yml, BuildIdentityTests, workflow and in-game Settings; add focused tests, validate manifest, full simulator suite, package unsigned IPA, inspect bundle and report actual physical checklist. No claim of build success before CI passes.

## Roadmap after next physical approval
- Complete authentic core phone apps, contacts, messaging, Photos, Notes, Files, Mail, Calendar, Clock, Settings, calls and offline browser; add family/studio records gradually.
- Maintain individual cast identities, canonical portraits and eventually voice references; approve new visual batches only as needed. Rich ordinary camera roll and genuine relationships, not every record a clue.
- Build actual offline game prototypes and developer utilities from the approved studio premise; integrate original hacking puzzle systems into Patchline/Relay. See OS_FIRST_ROADMAP.md for established scope.
- Plan and implement narrative dependency graph and earned discoveries in separate spoiler-marked development material. Complete causal timeline, scene and clue continuity, alternate routes, branching consequences, replay and accessibility tests before relevant chapters ship. Exact plot is not yet finalized; no invented claim that it is.
- Add fictional calls, recorded voice notes/captions, restrained horror audio and haptic cues at authored events. All eleven creator recordings play once, even loop-labeled sources; physical haptics separate.
- Creator tests each section on hardware; creative freedom delegated for details, but preserve locked approvals, ask for visual approval when needed and keep plot revelations out of reports. No external service requirement, actual hacking, real phone data access or paid unlocks.

## Authoritative documents
- OS_FIRST_ROADMAP.md: build history, feature roadmap and acceptance.
- NORA_WORLD_BIBLE.md: approved character/world direction.
- CHARACTER_CONTINUITY.md: identity and asset registry; update before introducing each new portrait/voice.
- GAME_DESIGN.md and older QA: legacy fixtures, not new campaign canon. Avoid legacy story spoilers in creator-facing reports.
- PHONE_FEEDBACK_QA.md and LIVING_PHONE_QA.md: previous regression requirements.
- Future spoiler-marked narrative documents: separate from creator-facing summary; repository access can still reveal their content.

## Current checkpoint — Foundation, November 25, 2026
Build 24 v1.4.1 successfully compiled, tested and published (run 45577112995). Nora ZIP uploaded and verified, staged photo and reactive messaging changes shipped. Physical testing incomplete: creator likes new Nora images, questions photo recovery/authentication, requests premium coherent system/app redesign. Creator approved [FOUNDATION_BUILD25.md](FOUNDATION_BUILD25.md), including working LumaOS identity, original artwork, system and app overhaul, manual save and configurable periodic autosaves plus event checkpoints. Save icon must be generated before compilation; initial generation failed, so artwork is pending. No Build 25 runtime changes or workflow started by this checkpoint. This supersedes earlier stale Build 23/L1 upload status; preserve historical entries for context.
