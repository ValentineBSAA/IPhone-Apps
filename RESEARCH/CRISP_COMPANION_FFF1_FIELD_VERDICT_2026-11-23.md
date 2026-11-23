# Crisp Companion: FFF1 passive packet investigation checkpoint (2026-11-23)

**Evidence:** physical iPhone test reports from owner for v0.1.2–v0.1.8, the project's read-only BLE source and the separate kettle-family research. This is a protocol *hypothesis* note, not a decoded protocol, proof of pairing, or authorization to send commands.

## v0.1.8 physical owner report (2026-11-23)

- Hardware was **idle; no physical Start**. Initial physical preset Reheat. Automatic prompted sequence Air Fry → Reheat → Air Fry.
- Untouched initial FFF1 baseline: **0** notifications.
- FFF1 notifications per prompted window: **1, 1, 1**.
- Total frames **3**. All **10 bytes**. No frames shorter than 6. Frame cap not reached.
- Byte 0 A5 predicate: **3/3**. Header-declared payload length matches frame length minus 6: **3/3**. Both predicates: **3/3**.
- *Different COSORI kettle* documented type predicates 12/22: **0/3**, full documented kettle header/type predicate **0/3**.
- Exactly **one anonymous byte-1 category (A)**, present one time in **each** of Air Fry 1, Reheat, Air Fry 2. This is only a within-session label, **not the original byte-1 value**.
- Of **2 adjacent equal-length pairs**: same anonymous category **2/2**, byte 2 increments by one modulo 256 **2/2**, and byte 2 plus byte 5 stays constant modulo 256 **2/2**.
- No idle category. No raw payloads, values, BLE IDs, MACs, account tokens, Wi-Fi details, firmware fingerprints or commands supplied.

**Additional owner-observed physical panel defaults:** Air Fry **10 minutes**, Reheat **5 minutes**; both were selected while not heating. These are *observed physical UI defaults*, not proven coded BLE values or new manufacturer-spec claims. The app's preset planner is separate from live hardware telemetry.

## Cross-version triangulation

- v0.1.2/0.1.3: notifications observed on physical selections; untouched baseline yielded zero in the completed comparison. Correlation is not decoding.
- v0.1.4: all 12 preset windows each yielded a notification across two passes; whole-packet repetition was zero, leaving the possibility of continuously varying sequence/check bytes.
- v0.1.5: four Air Fry/Reheat alternating prompted notifications, each 10 bytes, with only zero-based positions **2 and 5** varying in that four-frame comparison, including repeated same-preset selections. This is particularly important: there was no observed field varying with mode, despite modes having distinct displayed default durations.
- v0.1.6: three frames, changing byte positions 2 and 5, byte 2 +1 at both transitions, byte2+byte5 constant; no stable preset-specific positions.
- v0.1.7: one A5/length-compatible ten-byte FFF1 incoming frame, but not either documented kettle type; sequence comparisons not available with only one frame.
- v0.1.8: three frames with **identical anonymous byte-1 type category** across modes, and repeated sequence/checksum-like relations.

## Interpretation / confidence

1. **Strong observational finding:** during these controlled, idle, physical preset selections, a 10-byte FFF1 notification followed each physical prompt while hands-off baselines produced none.
2. **Strong across these samples:** the detected incoming messages do **not expose an identifiable Air Fry versus Reheat type category**. With v0.1.5's stable non-2/5 positions, there is no demonstrated preset or duration field in the sampled FFF1 messages.
3. **Plausible, unproven:** byte 2 acts as a sequence counter, and byte 5 is coupled by a checksum-like relation. Header structure resembles another COSORI BLE family but does not establish compatible payload semantics.
4. **Unknown:** whether packets are acknowledgments, key event envelopes, keepalives triggered by local interaction, status requests, or something else; whether another characteristic/paired session contains status; whether meaningful local commands exist for this hardware revision.
5. **Not established:** current set temperature, remaining time, cooking state, Wi-Fi provisioning, VeSync claiming or safe device control.

## Decision and efficient next step

**Stop issuing a new IPA for another generic A5/type/sequence/byte2+byte5 probe.** We have reproduced those observations enough; more of the same would be churn, not progress. Preserve v0.1.8 as the latest owner-tested passive probe.

Prioritize *independent exact-model protocol evidence* from manufacturer documentation, supported authorized SDK, or permissioned/redacted exact-model implementation/trace. A viable source must demonstrate actual fryer status fields and state changes using independent reference readings, not inferred offsets. Continue app-independent offline recipes, manual timer, accessibility/UI improvements as separate work if desired.

A **single well-designed future differential** could compare a physical time-only increment within *one* preset (e.g. Air Fry display 10 → 11 minutes and back) against no-touch and preset-switch controls, while not heating, but do it only if a new observation mechanism can distinguish message families, payload equality *excluding counter/checksum*, and other notification channels. Do not make the owner repeat old multi-preset sequences with no new discriminatory measurement. Consent, privacy, GATT characteristic write prohibition, firmware exclusion and app foreground-only safeguards still apply. Default time difference alone does not justify claiming protocol decoding.

Never send speculative FFF2 writes, replicate kettle commands, access TI OAD, provision Wi-Fi by guessing, or enable remote heater start. Bluetooth `setNotifyValue` configures CCCD; it is not a cooking command.

## Verification state

GitHub Actions run [45129017719](https://github.com/ValentineBSAA/IPhone-Apps/actions/runs/45129017719) completed **successfully** on 2026-11-23: simulator build, XCTest, unsigned iPhone device build, package/upload, read-only bridge tests and static no-characteristic-command guard all reported success. Artifact `CrispCompanion-v0.1.8-iOS16-unsigned` exists in the run. **The ZIP's contents and digest were not independently inspected here**, and user did not specifically report post-test stop/background cleanup, recipe-data migration, or actual appliance control. Do not mark those gates passed.

Next continuity source: `PROJECT_HANDOFFS/CRISP_COMPANION_ACTIVE.md`, `CrispCompanion/ROADMAP.md`, `CrispCompanion/BUILD_1_8_QA.md`.
