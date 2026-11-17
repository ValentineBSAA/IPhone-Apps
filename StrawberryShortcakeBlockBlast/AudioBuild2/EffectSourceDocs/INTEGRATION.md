# iOS implementation guidance • sound effects

- Use event keys in `SFX_MANIFEST.json`, not hard-coded UI labels, when wiring the 16 effects to the game's mechanics.
- Preload short WAV effects in AVFoundation for fast touch/block reaction; allow controlled polyphony for combinations without accidentally layering the same event many times.
- Use separate, persistently stored SFX volume from music volume. Consider reduced music volume for major celebrations, but avoid interrupting the song on normal taps.
- `block_pickup` fires on a successful pick-up, `block_place` on **valid placement only**, `invalid_placement` on rejection, and `row_clear` or `berry_combo` on their actual outcomes. Prevent duplicate triggers from drag end + touch end.
- `new_high_score` should fire once when the displayed record is first surpassed, not on each point gained afterward.
- `ten_seconds_left` should fire only when the Berry Blitz timer passes the 10-second threshold; `final_countdown_tick` is **about 2 seconds long in the uploaded source**, not a short metronomic click. It was intentionally retained untrimmed. Avoid starting multiple instances on every one-second tick. Use single-instance retrigger, cancellation, or deliberate timing so it cannot stack. `time_up` fires once on timer expiration.
- Test every effect on physical iPhone hardware with music enabled and with headphones and speaker; assess output balance, latency, interruptions, and perceptual loudness.
- Preserve existing gameplay logic and existing UI. Sound effects must be driven by game state, not guessed from animations alone.
