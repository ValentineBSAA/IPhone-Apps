# iOS implementation guidance • music

1. Use **AVFoundation** (e.g. `AVAudioPlayer` or `AVAudioEngine`) and bundle all 51 AAC `.m4a` resources locally in the app. No network dependency.
2. Use `AUDIO_MANIFEST.json` as the source of truth for song IDs and categories. Don't infer category from numerical track order.
3. Assign `main_menu` to menus, `relaxed_gameplay` and `upbeat_gameplay` to respective playlists/modes, `victory_results` to results/achievement **music screens**, and `berry_blitz` to timed mode. The victory files are FULL songs, not sound effects.
4. Shuffle within a playlist while avoiding back-to-back song repeats. On screen changes, avoid unnecessary restarts; for intentional category changes, apply subtle crossfades. No simultaneous duplicate music players.
5. Provide persistent **Music On/Off**, music volume, and playlist preferences (Cozy/Balanced/Arcade) separate from sound-effect volume. Proposed weights are preferences, not hardcoded audio tracks.
6. On timed mode, the music should remain musical; countdown ticks are supplied separately in the SFX ZIP. Duck/pause the current music briefly under major SFX only when appropriate.
7. Follow iOS audio session behavior for mute switch, interruptions, app backgrounding, and resumption according to the app's chosen policy.
8. Do not alter existing block placement, drag-and-drop mechanics, score logic, graphics, notifications, or other modes when adding music.
9. Verify durations, track-end advancement, re-entry to menu, app suspension/resume, volume persistence, and all 51 bundled paths in a built IPA.
10. Preserve existing app signing, bundle ID, and version conventions; increment the app's current version/build when all updates are integrated.

**Note:** Playlist music can be volume balanced during gameplay; the source-supplied performances were not loudness-normalized here. Listen before shipping.
