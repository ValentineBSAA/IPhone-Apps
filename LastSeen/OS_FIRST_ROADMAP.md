# LAST SEEN — authoritative master roadmap
Reorganized November 25, 2026. Start here. This document governs priority, dependencies and delivery; specialist documents govern implementation details. Historical files are retained, not current instructions. No approved feature is cancelled by reorganization. All ordinary reports remain spoiler-free.

## 1. Product pillars (locked)
- LumaOS is the game world, not a menu around a chat game. Believable ordinary life first, psychological horror and investigation emerge naturally. Original fictional OS, premium native presentation, no copying a real product. Preserve approved opening, restoration, simulated jailbreak, security progression, welcome and setup. Story authoring may proceed in parallel; no obsolete OS-approval-before-writing gate.
- Free complete offline native game, iOS 16+, iPhone 16e physical QA, no required account, ads, paywalls, runtime AI/API costs, real device data or actual system changes. Public system permission prompts remain authentic. Optional actual power-state detection, biometrics and future foreground microphone/speech only with appropriate consent and fallback. No network-dependent game functionality.
- Preserve app identity, established features, saved progress, original artwork/audio and story confidentiality. Direct ChatGPT/GitHub development; one consolidated installable IPA per verified milestone, no unnecessary intermediate physical builds. Any failed mandatory test blocks delivery. No invented completion claims.
- Story is essential, not an optional extra; avoid turning the project into endless OS feature expansion. All approved items remain tracked; new ideas are assigned to an owner milestone and acceptance criteria, not automatically added to an active corrective build.

## 2. Current baseline and status
| Item | Status | Evidence |
|---|---|---|
| Build 27 original 1.6.0 (27) | Packaged; partial physical pass | Run 45597383815; creator confirmed custom messages and app launch, reported Relay installation stall. |
| Build 27 Relay correction | CI PASS, IPA artifact published; hardware verification OPEN | Runtime 37b73218f80759c5dd230578263f4489d044a237; [run 45604001618](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/45604001618), [artifact 15016974042](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/45604001618/artifacts/15016974042). |
| Full game, later features and story | OPEN | Not complete simply because the corrective build passes. |
| Roadmap revision | Documentation only | Do not rebuild for docs alone. |

Status vocabulary: OPEN = planned/remaining; SOURCE = initial implementation exists; CI PASS = tests for exact revision passed; DEVICE PASS/PARTIAL/FAIL = reported physical result; BLOCKED = known prerequisite/failure. Never equate SOURCE with tested completion. Always cite run/commit and record actual results.

## 3. Prioritized implementation milestones
These are planning stages, not assigned version/build numbers or promises of separate IPAs. Consolidate related changes after stabilization, avoid repeated small test builds. Narrative track N runs concurrently.

| ID | Priority / milestone | Status | Gate / governing spec |
|---|---|---|---|
| S0 | Stabilize corrected Build 27 | CI PASS; device OPEN | [Build 27 acceptance](BUILD27_ACCEPTANCE.md); verify actual installation, Field Notes transaction, respring, save persistence, existing regression checklist. |
| S1 | LumaOS modernization and persistence | OPEN / partial SOURCE | [Feature requirements](FEATURE_REQUIREMENTS.md), [Gameplay Statistics](GAMEPLAY_STATISTICS_ROADMAP.md), [Relay modernization](RELAY_MODERNIZATION_ROADMAP.md). Modern UI across apps, light/dark, accessibility, live statistics, safe cross-store restore, core OS reliability, premium Relay discover/details/queue. |
| S2 | Jailbreak ecosystem and diverse puzzles | OPEN / partial SOURCE | [Relay modernization](RELAY_MODERNIZATION_ROADMAP.md), [Puzzle design](PUZZLE_DESIGN_ROADMAP.md), [Feature requirements](FEATURE_REQUIREMENTS.md). Optional discoverable sources, local source authorization, improved utility functionality and launcher shortcuts, unique challenges and fair guidance. Preserve all prior earned flags and installed packages. |
| S3 | Luma Assistant | OPEN | [Assistant spec](LUMA_ASSISTANT_ROADMAP.md). Approve one original ElevenLabs voice, recorded clips, optional native mic/on-device speech, typed fallback, local intent/action routing, spoiler-safe guidance. |
| N | Living world and complete narrative (parallel S0–S3) | Partial SOURCE / OPEN | [World bible](NORA_WORLD_BIBLE.md), [Continuity](CHARACTER_CONTINUITY.md), [Feature requirements](FEATURE_REQUIREMENTS.md), [Puzzle design](PUZZLE_DESIGN_ROADMAP.md). Complete private causal timeline, relationships, authored evidence, credible conversations, archive/site contents, game prototype, narrative escalation, payoffs and ending. Verify narrative reachability and every relevant asset. |
| S4 | Integrated release polish and final acceptance | OPEN | All specialist acceptance gates, [Feature requirements](FEATURE_REQUIREMENTS.md). Complete story playable end-to-end with alternatives, actual device QA, accessibility, persistence, performance, assets, privacy and final IPA integrity. |

Dependency order: S0 before expanding runtime scope; S1 establishes reliable presentation/save/catalog infrastructure; S2 builds discovery and puzzle progression on that foundation; S3 can prototype voice assets in parallel but integrate using stable app and clue gates. N develops in parallel and defines actual puzzle/evidence placements; story gates must not rely on unfinished optional cosmetics. S4 requires all approved scope reconciled and tested. If an item is deliberately deferred, record creator decision and scope explicitly; do not silently drop it. Keep a bounded release goal and pause new scope if it jeopardizes narrative completion.

## 4. Workstream ownership and source of truth
| Document | Purpose |
|---|---|
| [BUILD27_ACCEPTANCE.md](BUILD27_ACCEPTANCE.md) | Active corrective release evidence and physical checklist only. |
| [FEATURE_REQUIREMENTS.md](FEATURE_REQUIREMENTS.md) | Detailed inherited and outstanding requirements from prior acceptance ledger; all approved criteria retained. |
| [RELAY_MODERNIZATION_ROADMAP.md](RELAY_MODERNIZATION_ROADMAP.md) | Relay UI, transaction behavior, repositories and migration. |
| [PUZZLE_DESIGN_ROADMAP.md](PUZZLE_DESIGN_ROADMAP.md) | Original puzzle families, hints, research references, progress and acceptance. |
| [GAMEPLAY_STATISTICS_ROADMAP.md](GAMEPLAY_STATISTICS_ROADMAP.md) | Live playtime, session, autosave and earned milestone counters. |
| [LUMA_ASSISTANT_ROADMAP.md](LUMA_ASSISTANT_ROADMAP.md) | Voice, mic, offline assistant and acceptance. |
| [WORLD_DOCUMENTS_01.md](WORLD_DOCUMENTS_01.md) | Ten authored Word documents uploaded; gated integration pending. |
| [CONSOLIDATED_NEXT_BUILD.md](CONSOLIDATED_NEXT_BUILD.md) | Active next-release execution checklist, dependencies and asset lock; read first for engineering. |
| [CONNECTED_WORLD_ROADMAP.md](CONNECTED_WORLD_ROADMAP.md) | Approved connected personal/professional world, interactive mail, social apps and repair workstation; consolidated scope, implementation on hold. |
| [CONNECTED_WORLD_ICONS_01.md](CONNECTED_WORLD_ICONS_01.md) | Four approved social and memo icons uploaded; integration pending. |
| [WORLD_PHOTOS_EXPANSION_01.md](WORLD_PHOTOS_EXPANSION_01.md) | Approved photo intake, integrity and continuity review; L1 upload verified; continuity hold. |
| [NORA_WORLD_BIBLE.md](NORA_WORLD_BIBLE.md) / [CHARACTER_CONTINUITY.md](CHARACTER_CONTINUITY.md) | Canon and asset identity; not a plot walkthrough. |
| [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) | Brief restart instructions for engineering. |
| [BUILD27_CONSOLIDATION.md](BUILD27_CONSOLIDATION.md) | Historical Build 27 implementation log. |
| [OS_FIRST_HISTORY.md](OS_FIRST_HISTORY.md), [BUILD27_SCOPE_HISTORY.md](BUILD27_SCOPE_HISTORY.md), [DEVELOPMENT_HANDOFF_HISTORY.md](DEVELOPMENT_HANDOFF_HISTORY.md) | Full pre-reorganization snapshots. Retained for traceability, never use superseded release instructions as current priority. |

## 5. Next action and ongoing discipline
First verify the actual corrected artifact, then deliver the extracted unsigned IPA (not outer ZIP) and one spoiler-free physical checklist. Check actual install and package transaction before unrelated physical work. Log feedback without resetting saved data. Update this status table and the active release ledger when evidence changes; update specialist specs when approved requirements change. Keep detailed technical decisions in their proper workstream, build history in consolidation log, private story specifics in spoiler-marked developer notes. No repeated append-only copies of new requirements across every document. Preserve all prior approved requirements in specialist docs, feature ledger and archived snapshots; research citations retained from earlier notes, verify links before relying on them for implementation.


## Build 28 browser-first chapter slice
Creator approved next chapter and richer browser. Runtime work begins after the Build 27 CI baseline; device package correction remains OPEN. See [browser chapter acceptance](BROWSER_CHAPTER_ROADMAP.md). New version 1.7.0 (28); no claim of CI or device pass until exact run confirms. All other approved S1/S2/S3/N requirements remain tracked and incomplete unless independently verified.

## Consolidated next release planning hold
Creator approved the connected-world direction, including functional fictional social media. See [CONNECTED_WORLD_ROADMAP.md](CONNECTED_WORLD_ROADMAP.md). All new runtime work and additional builds are on hold until explicit go-ahead after consolidated scope review. Existing browser-focused Build 28 run 45687303359 was triggered before the hold; do not mistake it for implementation of the connected-world scope. Preserve all prior requirements and QA gates; this change is documentation only.

## Consolidated next-build execution checklist
[CONSOLIDATED_NEXT_BUILD.md](CONSOLIDATED_NEXT_BUILD.md) is the active implementation order and acceptance ledger for one cohesive next IPA. B28 run 45687303359 completed SUCCESS, artifact 15058695450; device acceptance OPEN. All ten L1 uploads confirmed. Preserve all specialist scope, including the three social apps and functional Voice Memos. This is organization only; no additional runtime changes or CI. Existing explicit development hold remains until creator directs implementation.
