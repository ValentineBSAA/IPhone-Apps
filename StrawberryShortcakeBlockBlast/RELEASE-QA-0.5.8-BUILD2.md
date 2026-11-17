# Berry Block Blast 0.5.8 Build 2 • Corrective Test Candidate

Branch: `feature/berry-058-corrective` (the previous 0.5.8 build branch is untouched)

**Status: source integrated, native Codemagic compilation and device testing still required.**

## What changed

- Audio: SwiftUI `scenePhase` is the single authoritative app lifecycle input for music. Remove queued app-activity NotificationCenter callbacks, synchronously pause the player and stop SFX during lock/background; resume reliably when active.
- Nightmare: no legal moves ends the 3-minute round **immediately**, preserves the score/record, freezes the clock and shows "No More Moves". No post-defeat Shuffle in timed Nightmare.
- Blitz: preserve the previously verified automatic board refresh rather than ending the timed score chase. Durations stay 60/120/300/600 seconds.
- Timed pause: Pause freezes the clock. Lock, notifications and modal screens suspend the clock; returning resumes the remaining time. Home, Pause, Settings, Help are the gameplay header controls.
- Story: small persistent objective/progress bar, 2/3 lines explicitly displayed, original 6-chapter repeating narrative, optional *silent* 5-second speech bubble by the mascot. No ElevenLabs audio in this build.
- High-score and combo notifications: center in the **viewport**, not the scrolling 24×24 board. Board rectangle tracking is non-observable to avoid 576 re-renders during scroll and transient notification layout.
- Boutique: five tile/category entries instead of one endless catalog, with dedicated Block Styles, Frames & Sparkles, Garden Helpers, Cottage Decor and My Items sections.
- Strawberry fruit: newly image-generated actual 128px RGBA **strawberry-shaped** tile. Original decoration-on-a-square is removed for red unlocked strawberry tiles; a free permanent True Strawberry skin enables all fruit-shaped pieces without changing collision geometry. Blueberry Velvet remains unchanged.
- Mascot: approved standing, portrait and celebration illustrations in the same 19-image catalog ZIP; celebration pose on victory.
- iOS target 16.0, existing bundle ID `com.valentinebsaa.berryblockblast`, build 2; preserves 51 music tracks, 16 sound effects, purchases, helper counts, Story progress and Endless saves.

## Cloud build
1. In Codemagic, select branch `feature/berry-058-corrective` and workflow `berry-block-blast-unsigned`.
2. The workflow imports `BuildPayload/Berry_Block_Blast_0.5.8_19_ArtCatalogs_CloudReady.zip` and decodes `BuildPayload/BerryRealStrawberry.png.base64`; it validates SHA-256, catalogs and iOS16.
3. Compile release iPhone app, package unsigned `Berry-Block-Blast-v0.5.8-build2-unsigned.ipa`, compile XCTest sources, attempt simulator tests with bounded timeout. Genuine test compilation/assertion failures remain fatal.

## Device checklist (actual iPhone 14 Pro on iOS 16)
- [ ] Cold-launch with music ON: main menu music begins by itself, without skipping in Jukebox.
- [ ] Lock while playing music and SFX: playback stops promptly, with no seconds of background audio.
- [ ] Unlock and foreground: song resumes without restarting twice; swiping away also stops audio.
- [ ] Incoming notification during 24×24: board remains put, touch cancels gracefully and banner remains centered.
- [ ] Nightmare: timer starts at 3:00; when no moves remain, it **freezes immediately** and shows correct score/best.
- [ ] Blitz: 60/120/300/600 second races end only when their timer expires, even after stuck-board recovery.
- [ ] Timed Pause, Help, Settings, lock: countdown freezes without stealing seconds.
- [ ] Story Chapter 2: displays exactly 0/3 through 3/3 lines with clear chapter objective; bubble is short, silent, non-blocking.
- [ ] Strawberry red tiles have real fruit silhouette, not a square with a strawberry overlay. Equip free True Strawberry style; all selected pieces render as fruits.
- [ ] Blueberry Velvet and previous paid cosmetics still appear and remain owned/equipped.
- [ ] Boutique home shows large categories; My Items displays purchases, helper counts and cottage decorations.
- [ ] High-score banner appears centered in viewport while 24×24 board is scrolled toward any edge.
- [ ] Original 51 M4As and 16 WAVs remain bundled byte-for-byte.

### Deliberately deferred
- ElevenLabs dialogue/voice lines. Only text bubbles are included.
- 256×256 garden: current 24×24 renderer must first pass real-device performance tests; 65,536 live cells would be irresponsible.
- Public release: this is a **test candidate** only, not claimed functional until a successful IPA build plus hardware QA.
