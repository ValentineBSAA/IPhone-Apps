# Build 32 comprehensive app acceptance register

Mandatory release gate for 1.9.0 (32), iPhone 16e. Every LabApp is listed exactly once. Earlier targeted source changes are not completed acceptance. Status: source pass = targeted correction committed, pending = full app-specific review outstanding. Every row requires source audit, native test and hardware acceptance; no row is certified complete yet. No IPA until creator authorization.

| App | Required review | Source status | Native | Device |
|---|---|---|---|---|
| VEIL | Offline routes, security modes, bookmarks, recovered media, staged unlocks | Pending | Pending | Pending |
| Relay Support | Alex scope, attachments, local AI, technical troubleshooting | Pending | Pending | Pending |
| Field Notes | Notebook, evidence links, saved comparisons, checkpoint access | Pending | Pending | Pending |
| Phone | Recents, favorites, keypad, call outcomes, voicemail limitations | Targeted pass | Pending | Pending |
| Messages | Search, typing, delivery, attachments, context, historical records | Targeted pass | Pending | Pending |
| Contacts | Directory, profile links, favorites, availability | Targeted pass | Pending | Pending |
| Photos | Library filters, zoom, private recovery, Luma handoff | Targeted pass | Pending | Pending |
| Notes | Search, editing, pinning, keyboard, private routes | Pending | Pending | Pending |
| Calendar | Dates, event details, ordinary chronology, navigation | Pending | Pending | Pending |
| Mail | Folders, drafts, recipients, unread, search, attachments, notifications | Targeted pass | Pending | Pending |
| Clock | Timer, stopwatch, persistence, audio, accessibility | Pending | Pending | Pending |
| Calculator | Arithmetic, edge cases, history, layout | Pending | Pending | Pending |
| Settings | Every toggle, actual effect, persistence, reset, protected access, sound studio | Targeted pass | Pending | Pending |
| Files | Folders, document access, previews, search, recovered references | Pending | Pending | Pending |
| Browser | History, navigation, bookmarks, offline URLs, attachments, review gates | Pending | Pending | Pending |
| Relay | Repository refresh, package install/remove, dependencies, conflicts, restart | Pending | Pending | Pending |
| Patchline | Safe mode, tweak status, diagnostics, respring, reboot | Pending | Pending | Pending |
| Game Saves | Manual/automatic slots, restore, timers, preferences, stale routes | Pending | Pending | Pending |
| Afterframe | Photo feed, profiles, drafts, privacy, social actions | Targeted pass | Pending | Pending |
| Connective | Studio feed, profiles, social actions, account settings | Targeted pass | Pending | Pending |
| CommonGround | Discussions, replies, profiles, community alerts | Targeted pass | Pending | Pending |
| Workstation | Connection, diagnostics, image tools, progression | Pending | Pending | Pending |
| HavenWatch | Fixed-camera archive, preferences, events, privacy, notifications | Pending | Pending | Pending |
| Dayblink | Stories, local media, expiry, interactions, notifications | Pending | Pending | Pending |
| Motionwell | Catalog, media availability, playback, saved state, notifications | Pending | Pending | Pending |
| Voice Memos | Record catalog, transcript, playback, read-aloud, missing audio | Pending | Pending | Pending |
| Luma Assistant | Nora memory, trust, context, permissions, voice, image evidence | Pending | Pending | Pending |

## Mandatory cross-app audit (all open)
- Opening, fictional setup, recovery workstation, lock screen, owner authentication and protected area sessions.
- Home layout, dock, app switcher, Control Center, search, app routes, navigation back, keyboard dismissal, empty states, dynamic type, VoiceOver, Reduce Motion, small-screen clipping.
- All notification producers, unread badges, tap routes, dismissal, preview privacy, sound/haptic ownership, no replay on load, offline behavior.
- Save/restore, migration, interrupted transactions, force-close, current access revalidation, no duplicate or leaked records, independent app settings and shared state.
- Main and optional narrative reachability, puzzle quality, pacing, endings, recovery, no spoiler leakage, no softlocks.
- Asset inventory, 40 unresolved artwork assignments, ten unapproved voice candidates, 19 sound cues, release resource verification, all tests and iPhone 16e QA.

Prioritize Mail and Settings now, then remaining utilities and platform-specific media/technical applications. A newly added launcher app must have a matching register entry. No silent scope reductions.
