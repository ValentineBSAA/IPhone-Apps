# Crisp Companion — Master roadmap
Updated 2026-11-22. Keep this file as the source of truth; do not treat planned work as tested.

## Product objective
A premium, genuinely useful, no-subscription iPhone companion for the owner's COSORI fryer, without relying on an App Store download. The full goal is safe feature parity for fryer-relevant VeSync functionality **where public interfaces and legitimate account/device access allow it**. Protect human safety and accurate status above cosmetics.

## Phase 0: Preconditions and uncertainties
- [x] Inspect existing `IPhone-Apps` repository, XcodeGen and macOS workflows.
- [x] Locate supported community CAF-P583S pyvesync integration and source.
- [ ] **Confirm exact hardware sticker/model** (CAF-P583S-KUS is *candidate*, not verified from the owner in this workflow).
- [ ] Confirm iOS phone version, user's current VeSync-account status and whether fryer is already provisioned.
- [ ] Find a legitimate first-pairing path without forcing an App Store download: another authorized phone, temporary permitted account, or documented provisioning workflow. No speculative cloned firmware pairing.
- [ ] Determine NAS DS418 Python compatibility, HTTPS/Tailscale reverse-proxy topology, protected credential store and restart persistence.
- [ ] Record unit conversions, Wi-Fi network dependencies, account cloud access, firmware version and hardware errors; no secrets in GitHub.

## Build 1, v0.1.0: Solid UI and trustworthy offline tools
- [x] Native SwiftUI iPhone architecture; separate folder and stable ID.
- [x] Warm charcoal/amber premium design with accessible headings, rounded cards, transparent connection state, four tabs.
- [x] Dashboard with live-status placeholder that **does not fabricate readings**.
- [x] Eleven preset planning choices; suggested settings deliberately marked non-manufacturer and NON-COMMAND.
- [x] Local personal recipes create/save/delete; independent from company cloud catalog.
- [x] Local manual kitchen countdown and user-initiated optional notifications; clearly not physical cook progress.
- [x] Preview mode default; read-only bridge client with HTTPS validation and token in Keychain.
- [x] Experimental FastAPI read-only bridge using a pinned compatible pyvesync revision, with bearer authentication, no write routes.
- [x] Initial XCTest models, bridge unit test source, generated temporary original app artwork, GitHub workflow source, this roadmap, QA and handoff documents.
- [ ] Automated workflow terminal green (both device and simulator builds).
- [ ] XCTest suite passed in simulator and Python bridge tests passed.
- [ ] Owner screenshots approved for readability, spacing, premium finish and accessibility.
- [ ] Physical iPhone install via existing AltStore signing successful; seven-day refresh and upgrade verified.
- [ ] Production-grade iPhone icon artwork reviewed by owner (current icon is programmatically generated placeholder).
- [ ] Full VoiceOver, dynamic type, reduced motion, 320-pt width, dark contrast and safe-area audit.
- [ ] Real fryer status; blocked pending pairing/credentials.

## Build 2: Hardware read-only proof
- [ ] Account exists and fryer paired legitimately; confirm model, exact device ID privately and correct account.
- [ ] NAS securely serves HTTPS bridge with stable restart; no open WAN exposure, no password in app.
- [ ] Validate successful login and real device discovery; no bogus online indicators.
- [ ] Verify idle, preheat, cook, pause, disconnected, cloud-down and manual heater activation on physical hardware.
- [ ] Confirm Fahrenheit vs Celsius, displayed **set** temperature versus actual sensor temperature, and minute/second behavior.
- [ ] Keep device identifiers out of public diagnostics; timestamp and stale polling shown prominently.
- [ ] Poll limited to safe rate when app active; app background behavior reviewed against iOS limits.

## Build 3: Safe commands after explicit verification
- [ ] Document exact model/firmware-specific command schema and presets. Test each on hardware with supervision.
- [ ] Command acknowledgements, timeout/retry idempotency, error feedback and audit log.
- [ ] Stage safe device presets, temperature and duration **only** if manufacturer behavior supports them.
- [ ] Stop/end and pause/resume only after controlled tests and appropriate confirmation.
- [ ] **Never remote-start heating from this app.** No hot-start bypass.
- [ ] Persistent last-known state marked STALE, not falsely live.
- [ ] Robust token expiry, rate limits, local network disconnection and NAS reboot recovery.

## Build 4: Premium experience
- [ ] Appliance-verified preset details, custom favorites, serving and food category tags.
- [ ] Cook-session history from real device events, explicitly separate from manual timer.
- [ ] Real completion notifications from authorized status events once proven (not guessing in background).
- [ ] Theme options, high-contrast and large touch targets, haptics, small tasteful animations.
- [ ] Manual JSON backup/export and restore with validation, no secret or account token exports.
- [ ] Owner-approved app icon and screenshot assets, without brand impersonation.
- [ ] Optional shortcuts/widgets only if iOS provisions allow; privacy review.

## Build 5: Official-feature gap analysis
- [ ] Compare real app screenshots, legitimate documented recipes, device settings and remote functions one by one.
- [ ] Determine which official catalog features are licensed/proprietary and cannot be duplicated.
- [ ] Explore approved first-time provisioning path or document an unavoidable official-app pairing dependency.
- [ ] Evaluate offline/local control only if verified supported; never claim it exists merely because Wi-Fi does.
- [ ] Version migration, signed IPA workflow and real-device regression suite.

## Release gates
- Do not label Build 1 a working VeSync replacement until pairing and authenticated hardware status pass.
- A compile result is not a physical test pass.
- No heater actuation capability via remote start.
- No shared source code may contain device credentials, tokens, cloud responses with IDs, or personal account history.
- Own recipes and timer are genuinely usable offline even if real device integration remains blocked.
- Keep every new milestone tied to measurable CI results, owner screenshots, and regression checkboxes.

## Native-only pairing route (new owner direction, 2026-11-22)
- [x] Owner **explicitly excludes** Android and a second Apple Account; do not reopen these routes.
- [x] Research actual CAF-P583S-KUS metadata: `WiFi+BTOnboarding+BTNotify`, but **no verified BLE provisioning protocol**.
- [x] Create an opt-in, foreground-only CoreBluetooth discovery lab in Settings. Source exists; real iPhone detection and iOS compilation are pending CI/owner test.
- [ ] Confirm the fryer's actual sticker model before any onboarding implementation.
- [x] Discover genuine BLE advertisements on owner's iPhone; model-name match `CAF-P583S-KUS`, physical scan verified.
- [ ] Determine protocol details and VeSync account claiming without relying on an official app; feasibility uncertain.
- [ ] When the documented method is known, implement an explicit pairing wizard with secure credential handling and recovery.

Reference: [PAIRING_RESEARCH.md](PAIRING_RESEARCH.md). Discovery is NOT pairing.

## D1: REAL iPhone discovery result and next diagnostics (2026-11-22)
- [x] Owner physically installed v0.1.0 native BLE discovery IPA and showed screenshots: 20 advertisements, with `CAF-P583S-KUS` at top and RSSI **-57 dBm**.
- [x] Exact model name is an observed BLE advertisement; device identity is **strongly supported but NOT cryptographically verified**. No connection or Wi-Fi provisioning yet.
- [x] Owner feedback: generic flat list of 20 devices is too technical and does not identify unrelated products; focus only on air fryer by default.
- [x] Source improvement: separate highlighted COSORI card, collapsed unrelated devices, description based ONLY on advertised name, no guessed identities.
- [x] Source improvement: explicit `Inspect Bluetooth services` action to temporarily connect and discover **GATT service and characteristic UUID metadata only**, then disconnect; no values read, no notify, no writes.
- [x] D1 simulator/device CI pass and real iPhone GATT discovery verified: 3 services, 6 characteristics. Owner supplied screenshots.
- [x] GATT metadata reviewed: OAD is firmware update, FFF0/FFE0 message formats unknown. No basis for actual provisioning from UUIDs alone.
- [x] D2 physical configuration-mode comparison: 5-second hold -> blinking Wi-Fi icon; BLE name remains; GATT services unchanged; no obvious fryer hotspot in a single iPhone Wi-Fi scan. No passwords requested.

## D3 protocol documentation investigation (2026-11-22)
- [x] Search exact-model public integrations, cloud issue #477, VeSync BLE device provisioning work, Talos legacy COSORI reports, Levoit BLE study, TI UUID documentation and FCC index.
- [x] Establish strongest analogous BLE architecture: encrypted session exchange + Wi-Fi credentials + cloud config has been observed in an **unrelated VeSync power socket**; cannot be reused on CAF-P583S-KUS without exact-model proof.
- [x] Identify **separate VeSync cloud device-claim/config-key obstacle**; account.vesync.com portal exists, registration and device onboarding options unverified.
- [x] Record a no-go for speculative writes, OAD, firmware operations, remote heating and pretending scans equal pairing.
- [ ] Get **exact-model**, consented, fully redacted first-time pairing documentation/trace from community or vendor.
- [ ] Verify whether iPhone-only onboarding and cloud claiming can occur without official VeSync app; may be technically unavailable without vendor support.
- [ ] Only then implement offline parser fixtures and a controlled first-time setup flow.

See [PROVISIONING_PROTOCOL_RESEARCH.md](PROVISIONING_PROTOCOL_RESEARCH.md). **No new IPA is justified by the present evidence.**
