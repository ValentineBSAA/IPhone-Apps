# LAST SEEN: The Living Phone
## Production direction | November 17, 2026

**Status:** Approved concept for a *planned* follow-up, not an assertion that these features are implemented. Voice calls, real-call impersonation, microphone capture, speech recognition and active AI services are explicitly out of scope. iOS 16.0 / iPhone 14 Pro remains the baseline.

### The product promise

The player enters a *fictional everyday phone* in which the world makes sense before it becomes frightening. They might open Messages, check a contact, browse photographs or find a maintenance notice. For the first part of a chapter, nothing loudly announces "horror game." Mystery is discovered through inconsistency and observation.

**Opening test:** A player beginning at 3:53 PM should see 3:53 PM and receive a plausible afternoon text. No dialogue should claim it's 2 AM. Time-of-day affects language and atmosphere but never blocks chapter completion.

### Critical architecture change

**Today:** three isolated selectable stories, Nora's Missing Floor, Eli's Night Shift, and Unknown's Seventh Number. This avoids simultaneous chat flooding but makes it difficult to believe all three share a single building. Current Nora scenario also forwards Eli and Unknown messages through Nora, which can feel contrived.

**Target:** one **active campaign** embedded in a shared fictional world. The player's Messages app has multiple contacts with stable relationships, shared evidence and consistent history. Only the chosen campaign's main plot advances. Other contacts may have grounded mundane conversations and later become relevant *when warranted*, but must never trigger their entire separate horror story at the same time. Preserve each standalone campaign as replayable content rather than deleting it.

**Data layers:** fictional-world snapshot, campaign state, contact/relationship state, inbox messages, media library, notes/calendar records, notifications and scheduling, and settings. Use stable IDs and migration from saves v1/v2; do not reset players without consent. All views are projections of one canonical state store.

### Phone home screen (vNext, in priority order)

P0 **Messages:** search, inbox previews, filters (All/Unread), grouped bubbles, realistic time dividers, timestamps on long-press or after gaps, single bottom composer, choices that *mean something*, read/delivered status, contact avatars linking to profiles, reactions, attachment previews, photo viewer, and no permanent debugging "Reveal" UI. Provide an accessibility "skip waits" control in Settings.

P0 **Contacts:** working fictional directory, real-looking contact profile, story-grounded personal notes, current shared media, relationships, and message action. "Call" and "Video" remain inactive with explanation.

P0 **Photos:** camera-roll style fictional shared-media library and full-size zoomable photographs with original file metadata, favorites and notes. No access to player's real photo library; photos shared by characters appear only after receipt. Deleting a photo should not softlock clue discovery.

P1 **Notes:** ordinary shopping/maintenance notes before useful discovered notes later. Allow legitimate clue pinning, with a consistent entry's author/time and source.

P1 **Calendar / reminders:** building inspection and plans with plausible dates. Timestamps derive from real device calendar; plot events schedule relative to player's play session, respecting time-zone changes. No required waiting for a literal 2 AM.

P2 **Mail, maps or browser:** only after those apps have useful story functions, not empty icons. Fake phone call history may include *text-only* records as clues, never a functioning call without recorded character audio.

P0 **Settings:** volume, effects, notifications, Reduce Motion, haptic strength/on-off, accessibility, text speed, save/replay controls. The game must not overwrite iOS system preferences.

### The ordinary-world layer

Add 2-3 well-written incidental fictional contacts to establish a real neighborhood, e.g. friend Maya, manager Denise, and a delivery/building-office message. Give each distinct voice and schedule; avoid turning everyone suspicious or making constant interruptions.

- Nora is a believable neighbor with mundane problems, mild humor, uncertainty, and imperfect phrasing. She doesn't instantly know about haunted floors.
- Eli has a job, shift boundaries, mundane maintenance details, and imperfect knowledge. His claims must be consistent with records.
- Unknown Number should first plausibly be a wrong number, mislabeled building message, or spam; all-caps supernatural pronouncements belong much later or should be cut.
- Use the existing Ash Street / apartment 402 / publicly four-floor building for continuity; don't randomly rename locations or floors across assets.
- Every relationship evolves from player's choices and past messages rather than arbitrary jumps.

### Narrative pace (target 35-50 min *active play*, validate on hardware)

**Act I, 0-10 minutes | normality:** a plausible afternoon/evening maintenance question, a routine friend or building message, browsing a contact photo and a hallway photograph. At least one conversation unrelated to horror; no disturbing soundtrack.

**Act II, 10-20 minutes | faint discrepancy:** elevator says "out of service" but Nora sees it operating. A normal image contains a subtle mismatch. The player can voluntarily inspect rather than being told what's wrong.

**Act III, 20-35 minutes | corroboration:** maintenance notes, elevator photo and old floor records contradict one another. Choices alter trust and evidence access. The first sincerely frightening moment comes after the player has formed their own theory.

**Act IV, 35-50 minutes | consequences:** messages shift, a known person acts inconsistently, photographs tell an unnerving story, and meaningful choices determine endings. No cheap choice with identical results.

Design review condition: a first-time player must be able to say "For the first several minutes I was just using a fictional phone," not "The ghost started texting immediately."

### Hybrid realism, photographs and forensic consistency

The **ten story photographs** uploaded in GitHub Release `Photos-1` are for narrative *attachments*, not static props. The first six were generated as separate images. Four later assets were cropped from concept-board work; replace those with polished standalone high-resolution images before a public release. All must share a consistent building: cream walls, brown carpet, dark wood doors, modest ceiling lights, stainless elevator, maintenance-room materials.

Define a photo registry: `photoID`, `senderID`, `assetName`, `takenAt` (within fiction), `deliveredAt` (device local), `caption`, `requiredClue`, optional `hotspot` for the meaningful detail, and `inspectionState`. Never rely on tiny AI-rendered labels for required evidence. If an image has 01:43 printed inside it but is sent at 3:53 PM, explicitly establish it is an *old photograph*, otherwise remove/replace the embedded timestamp. The clue in the artwork and the written inference must agree.

Photo viewers should support pinch-to-zoom, double-tap, aspect-ratio-safe opening, attachment info, return to exact scroll position, and evidence discovery through player action. A photo should never explain itself with "LOOK HERE, THIS IS IMPOSSIBLE."

### Real-time system, actual local time without long idle blocks

Use `Date()` and `Calendar.current` for the displayed clock; preserve each message's real delivery timestamp. Distinguish wall-clock time from active narrative playtime and in-world past photo metadata.

Schedule story events by stable IDs and due times, with constrained *variation* for natural pauses. Don't show dots for every sentence; introduce thinking delays, occasional instantly typed short replies, corrections, reactions, read/seen states and a few long silences. Do not flood chat with messages after a long app suspension. On foreground resume, deliver at most a small plausible batch, check unresolved choice gates, and reconcile due notifications idempotently.

Optional local notifications should carry specific believable dialogue previews with contact name, remain recognizably from LAST SEEN in iOS, and respect permission/Focus. iOS usually suspends background apps; don't promise continuous real-time execution or invented immediate reply processing. Native quick replies can match authored choices or be preserved as drafts. No fake emergencies.

### Sound

Retain current subtle notification chime/haptics. Make normal-world ambience nearly invisible, gradually introduce plausible environmental noises as locations/acts warrant (elevator hum, ventilation, far-off knocks, short unnatural silence). Avoid continuous ominous drone, cheap stingers or a false voice-call interface. All audio and clue information must have text/accessibility alternatives.

### Acceptance checklist: the next real-device milestone

1. Open at noon: no dialogue says "tonight" or "2 AM"; header and message metadata track local time, timezone and DST correctly.
2. Switch between contacts: only active campaign advances, but relevant world state remains coherent; no simultaneous flood.
3. Contact icon → functional profile; media button → images actually received; no empty fake actions.
4. Photograph matches sender, location, time and clues; no placeholder illustrated elevator in the imported build.
5. Reliable back navigation and safe-area layout on iPhone 14 Pro; no clipped chat bubbles; grouped timestamp display.
6. Lock phone for 30 minutes; optional believable message notification; reopen with no duplicated or out-of-order scene events.
7. Turn off notifications or audio; game and mystery remain complete and understandable.
8. Restore an older v1.0.2/v1.0.3 save, verify migration, replay one campaign without clearing unrelated progress.
9. Confirm all story branches and endings through automated tests plus 3 full manual playthroughs.
10. Microphone permissions not requested, no live voice call UI and no raw audio collection.

### Release gates and engineering order

**A. Quality baseline:** import the ten images, verify the built IPA and test on actual iOS 16. Keep the working build as a rollback.

**B. One cohesive phone shell:** Messages, Contacts, Photos and Settings fully usable; remove developer control surfaces; fix scrolling/safe area; realistic grouped chat.

**C. World engine:** unify contact and campaign state, message delivery/scheduler, real-time correctness and persisted state; write deterministic clock tests.

**D. Writing:** replace early abrupt horror with nuanced Act I and establish a consistent story bible and content schema. Run narrative continuity audits and human playthroughs.

**E. Evidence/audio polish:** improved full-res final four photographs, clues/hotspots, low-key sound design and responsible optional notifications.

**Do not build yet:** AI free chat, Story Maker, network accounts, real SMS/call access, always-running background processes, voice-call capture or recognition. Every one would consume time and make the basic experience harder to finish.

### External platform guardrails

- Apple App Review 4.1 discourages imitating other apps; use **familiar patterns but original visual identity**, not a pixel-perfect clone of Messages/Phone.
- Apple's background app model is not a persistent chat server. Use local notifications and state reconciliation, never a promise of exact-second background execution.
- Keep LAST SEEN as the internal codename until public branding is checked.

References:
https://developer.apple.com/help/app-review/guideline-reference/4-1-prevent-copycat-rejection/
https://developer.apple.com/documentation/uikit/about-the-background-execution-sequence
https://developer.apple.com/documentation/usernotifications/untextinputnotificationaction
