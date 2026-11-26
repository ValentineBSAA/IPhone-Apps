# Build 32 comprehensive app acceptance register

Mandatory release gate for 1.9.0 (32), iPhone 16e. Every LabApp is listed exactly once. Earlier targeted source changes are not completed acceptance. Status: source pass = targeted correction committed, pending = full app-specific review outstanding. Every row requires source audit, native test and hardware acceptance; no row is certified complete yet. No player-facing IPA until creator authorization and native acceptance; physical acceptance follows installation of that verified candidate.

| App | Required review | Source status | Native | Device |
|---|---|---|---|---|
| VEIL | Offline routes, security modes, bookmarks, recovered media, staged unlocks | Targeted pass | Pending | Pending |
| Relay Support | Alex scope, attachments, local AI, technical troubleshooting | Targeted pass | Pending | Pending |
| Field Notes | Notebook, evidence links, saved comparisons, checkpoint access | Targeted pass | Pending | Pending |
| Phone | Recents, favorites, keypad, call outcomes, voicemail limitations | Targeted pass | Pending | Pending |
| Messages | Search, typing, delivery, attachments, context, historical records | Targeted pass | Pending | Pending |
| Contacts | Directory, profile links, favorites, availability | Targeted pass | Pending | Pending |
| Photos | Library filters, zoom, private recovery, Luma handoff | Targeted pass | Pending | Pending |
| Notes | Search, editing, pinning, keyboard, private routes | Targeted pass | Pending | Pending |
| Calendar | Dates, event details, ordinary chronology, navigation | Targeted pass | Pending | Pending |
| Mail | Folders, drafts, recipients, unread, search, attachments, notifications | Targeted pass | Pending | Pending |
| Clock | Timer, stopwatch, persistence, audio, accessibility | Targeted pass | Pending | Pending |
| Calculator | Arithmetic, edge cases, history, layout | Targeted pass | Pending | Pending |
| Settings | Every toggle, actual effect, persistence, reset, protected access, sound studio | Targeted pass | Pending | Pending |
| Files | Folders, document access, previews, search, recovered references | Targeted pass | Pending | Pending |
| Browser | History, navigation, bookmarks, offline URLs, attachments, review gates | Targeted pass | Pending | Pending |
| Relay | Repository refresh, package install/remove, dependencies, conflicts, restart | Targeted pass | Pending | Pending |
| Patchline | Safe mode, tweak status, diagnostics, respring, reboot | Targeted pass | Pending | Pending |
| Game Saves | Manual/automatic slots, restore, timers, preferences, stale routes | Targeted pass | Pending | Pending |
| Afterframe | Photo feed, profiles, drafts, privacy, social actions | Targeted pass | Pending | Pending |
| Connective | Studio feed, profiles, social actions, account settings | Targeted pass | Pending | Pending |
| CommonGround | Discussions, replies, profiles, community alerts | Targeted pass | Pending | Pending |
| Workstation | Connection, diagnostics, image tools, progression | Targeted pass | Pending | Pending |
| HavenWatch | Fixed-camera archive, preferences, events, privacy, notifications | Targeted pass | Pending | Pending |
| Dayblink | Stories, local media, expiry, interactions, notifications | Targeted pass | Pending | Pending |
| Motionwell | Retired in 1.9.1; legacy state decode, no launcher or live notifications, photo-essay migration | Targeted pass | Pending | Pending |
| Voice Memos | Record catalog, transcript, playback, read-aloud, missing audio | Targeted pass | Pending | Pending |
| Luma Assistant | Nora memory, trust, context, permissions, voice, image evidence | Targeted pass | Pending | Pending |

## Mandatory cross-app audit (all open)
- Opening, fictional setup, recovery workstation, lock screen, owner authentication and protected area sessions.
- Home layout, dock, app switcher, Control Center, search, app routes, navigation back, keyboard dismissal, empty states, dynamic type, VoiceOver, Reduce Motion, small-screen clipping.
- All notification producers, unread badges, tap routes, dismissal, preview privacy, sound/haptic ownership, no replay on load, offline behavior.
- Save/restore, migration, interrupted transactions, force-close, current access revalidation, no duplicate or leaked records, independent app settings and shared state.
- Main and optional narrative reachability, puzzle quality, pacing, endings, recovery, no spoiler leakage, no softlocks.
- Asset inventory: 47/47 dispositions closed (38 assigned, nine held), passed source/artwork preflight 45768056837. Ten generated voice candidates are technically verified but creative/rights approval and runtime import remain open. Verify 19 sound cues, release resources, all native tests and iPhone 16e QA.

Feature scope is closed. Resolve confirmed compilation/test failures first; then check each app on the approved physical candidate. A newly added launcher app must have a matching register entry. No silent scope reductions.

## Pass 160: native test evidence index (not executed results)

These are existing targeted regression suites, not proof of complete app acceptance. Native run 45770243683 covers runtime c79b98ed1892057fe728b325a79b6456a644934f. Its actual terminal test outcomes must be checked before changing any Native status. UI smoke coverage is limited to its actual routes; remaining interaction, audio, visual and accessibility behavior needs device acceptance.

| App | Existing targeted test suites |
|---|---|
| VEIL | VeilCommunityTests; LumaArchiveAtmosphereTests; EntityEchoTests |
| Relay Support | RelaySupportConversationTests; RelaySupportKnowledgeTests |
| Field Notes | EvidenceConnectionTests; RecoveryCircuitTests; LumaCommunicationSmokeTests |
| Phone | LumaCommunicationSmokeTests; LivingPhoneCoreTests (notification model) |
| Messages | LivingPhoneTests; MessageAttachmentTests; LumaCommunicationSmokeTests |
| Contacts | ContactPortraitTests; LumaCommunicationSmokeTests |
| Photos | NoraVaultTests; RecoveredImageAnalysisTests; ImageInterpretationTests; LumaImageAnalysisTests |
| Notes | LivingPhoneTests; PhoneLabTests |
| Calendar | PhoneLabTests |
| Mail | ConnectedWorldTests; LumaActivityJournalTests |
| Clock | PhoneLabTests; Build32IntegrationAuditTests |
| Calculator | PhoneLabTests |
| Settings | PhoneLabTests; RecoverySecurityTests; PhoneFeedbackTests |
| Files | PhoneLabTests; VeilCommunityTests |
| Browser | PhoneLabTests; InvestigationProgressTests; InvestigationReachabilityTests |
| Relay | RelayCatalogTests; LumaCommunicationSmokeTests |
| Patchline | RecoveryCircuitTests; RelayCatalogTests; RestartArtTests; EntityEchoTests; EntityEchoSmokeTests (new, pending) |
| Game Saves | Build32IntegrationAuditTests; RestoredPhoneBackupTests; LumaCommunicationSmokeTests |
| Afterframe | SocialAccountTests; ConnectedWorldTests |
| Connective | SocialAccountTests; CommunityMediaUseTests |
| CommonGround | CommunityActivityTests; SocialAccountTests |
| Workstation | WorkbenchDiagnosticTests; ConnectedWorldTests; UtilityProgressTests |
| HavenWatch | HavenWatchTests; HavenWatchEventTests |
| Dayblink | DayblinkTests |
| Motionwell | MotionwellTests |
| Voice Memos | LumaVoiceAssistantTests |
| Luma Assistant | LumaVoiceAssistantTests; ContextualConversationTests; EntityEchoTests |

## Physical acceptance order

1. Install only the explicitly authorized, integrity-verified candidate; verify identity, clean start and compatible existing save restore.
2. Opening/authentication/restart sequence, audio and haptics, launcher and system navigation.
3. All 27 app rows, including communication, utilities, settings, media and jailbreak ecosystem; verify persistence and accessibility.
4. Confidential integrated story and encounter acceptance, including retry, recovery, assistant hints, safe-mode behavior and both completion paths. Keep answer keys out of creator-facing checklists.
5. Close remaining failures, revalidate exact revision, and record iPhone 16e outcome. A green native run is not device certification.

## Build 33 verified baseline and outstanding device gate
Version 1.9.1 (33), runtime revision 210f38623baf33c52e09f6b9f2739ef55cbadf89, run 45905804847: native release compilation succeeded, 256 unit and 4 simulator UI tests passed. The targeted suites listed above ran as part of this validation; this is not a complete app-by-app certification. Motionwell is retired; verify only migration and absence of live entry points/alerts. 26 active app rows plus retired legacy state. Pass 12 changes to playthrough isolation are not covered by this baseline. Physical acceptance, deeper dialogue quality and outstanding source review remain open. Do not infer hardware verification or complete audit from CI success.
