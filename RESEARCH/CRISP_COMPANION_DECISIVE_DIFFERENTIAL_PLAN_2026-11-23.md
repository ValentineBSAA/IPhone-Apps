# Crisp Companion — decision-gated local status experiment

Date: 2026-11-23. Scope: **read-only design and evidence gate, not a new IPA or working protocol**.

## Why change direction

Repeated v0.1.5–v0.1.8 tests have produced a consistent incoming FFF1 10-byte A5-framed message with the same anonymous type across Air Fry and Reheat and changing only sequence/checksum-like bytes. Another test of those same predicates has little expected information value. The owner reports Air Fry panel default 10 minutes and Reheat 5 minutes. This is a valuable independent physical contrast, **not** proof that BLE includes the time.

## One falsifiable question

When the owner changes **only the selected duration**, while the fryer remains idle and never starts heating, does any subscribed, non-firmware notification contain a repeatable field change after excluding the frame's apparent sequence (zero-based offset 2) and dependent checksum-like offset 5?

A **positive result** would require:
- Three or more physically confirmed 10→11→10-minute transitions, with a baseline and a no-op same-setting control if physically possible;
- Event acquisition timing associated with each physical action, not just a scheduled on-screen prompt;
- Repeatable, same-direction non-counter field differences between 10 and 11 and reversal back to 10, across more than one cycle;
- Comparison of FFF1 and any previously verified **notify-only** channel separately; never discover/subscribe to TI OAD or issue characteristic read/write commands;
- No capture of personally identifying BLE device details or secrets; raw payloads remain in bounded volatile memory, never copied, logged, persisted or transmitted;
- Negative results reported honestly, including if the hardware emits no notification for a time adjustment.

A **negative result** means only that the currently observed notification channel does not expose an identifiable duration field in this experiment. It does **not** prove the device has no local protocol, since paired/authenticated status or another transport might exist.

## Experiment implementation gate

Before writing v0.1.9:
1. Confirm the physical fryer allows a time-only +1-minute adjustment **without pressing Start** and without changing its selected mode.
2. Inspect the existing FFF1 observer's lifecycle and make a simulator-only analysis fixture that masks zero-based offsets 2 and 5 and rejects uncorrelated/short frames.
3. Decide whether the existing notification path can provide new evidence. If the only output remains identical masked bytes for each change, **stop this research line**; do not ship repeated probes.
4. If the owner approves, add exactly one foreground-only, one-start differential diagnostic with physical step acknowledgment, automatically disconnecting and wiping transient bytes on completion/Stop/background/exit. Strict no characteristic value writes/reads, no OAD, no heating and no cloud.
5. Keep original iOS bundle ID, recipes and timer. Verify CI and IPA artifact before distributing. Do not interpret bytes as live state without independent repeatability.

## Alternative if local BLE path fails

Prioritize exact-model manufacturer documentation or permissioned public firmware/protocol analysis to establish whether legitimate local status/control is even supported. Avoid a false promise of feature parity. Continue premium standalone kitchen planner, recipes and independent timer only as a **separate** product improvement track, not a substitute for appliance connectivity.

## Current action

This document is a **go/no-go protocol**. The immediate owner question is whether the Air Fry time can be changed from 10 to 11 minutes while idle, with no Start. Until confirmed, do not create a v0.1.9 IPA or require a new multi-preset test.

Related evidence: [v0.1.8 field verdict](CRISP_COMPANION_FFF1_FIELD_VERDICT_2026-11-23.md).
