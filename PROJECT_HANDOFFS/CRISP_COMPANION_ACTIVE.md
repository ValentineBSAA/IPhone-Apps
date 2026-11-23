# CRISP COMPANION active development handoff
As of 2026-11-22. Read this before making a claim about the build.

Project folder: `CrispCompanion/` in `ValentineBSAA/IPhone-Apps`. Work branch: `feature/crisp-companion-build-1`. Proposed app name: Crisp Companion. iPhone-first, iOS 16+, bundle ID `com.valentinebsaa.crispcompanion`.

## User's actual goal
Replacement for the **VeSync fryer-related iPhone app features** because App Store downloads are blocked by outstanding Apple Account billing. User wants beautiful premium UI, practical cooking features, AltStore sideload, optional always-on Synology DS418 bridge, extensive roadmap, and as much code as safely achievable now. User expressly wants durable GitHub handoff; avoid 'continue' loops that forget progress. Other projects are Berry Berry Blast and POTS & Posies; NEVER change their paths or workflows.

## Scope and honesty
Community support for COSORI Dual Blaze **CAF-P583S-KUS** exists in `RedsGT/hass-vesync-enhanced` and `RedsGT/pyvesync@wfon-caf-p583s`; **verify that owner's actual model matches**. Manufacturer docs prohibit remote cooking start: disallow remote heater activation despite a community software bypass. pyvesync cloud API requires account/device already paired. The user may NOT have been able to pair due blocked App Store, so native first-time setup is still a major unknown, not solved by this implementation.

## Source added in Build 1 branch
- SwiftUI four-tab premium screens, no fake device state, eleven planning presets, custom recipes, manual timer and local notifications.
- Preview-mode default. Optional HTTPS-only `GET /v1/status` client, bridge secret in iOS Keychain.
- Python read-only FastAPI backend, pinned compatible pyvesync fork, env-only server credentials, bearer token, no write routes.
- XcodeGen iOS16 project, XCTest source, bridge Python tests, temporary original generated icon, macOS CI unsigned IPA workflow, detailed roadmap and QA checklist.

## Current verification gates (MUST check live workflow result)
- Source committed is NOT equivalent to compiled app.
- CI success or failure must be checked using GitHub Actions after workflow addition.
- Physical iPhone install, owner design review, account setup, NAS deployment and actual fryer status remain unverified.
- Need verify build toolchain, generated icons, no accidental secret disclosure, network mode label behavior.
- Do not claim finished IPA until a real passing workflow artifact exists.

## Next actions
1. Review CI build and fix Swift compiler or test errors, not cosmetic iteration.
2. Review screenshot/UI on iPhone, including dynamic type and tab scrolling.
3. Legally provision VeSync account/fryer, determine NAS runtime.
4. Confirm read-only status with exact model/firmware.
5. Implement ONLY verified safe control features with hardware testing.
6. Update `ROADMAP.md`, `BUILD_1_QA.md`, and this handoff after every substantive change.

## New owner constraint / discovery milestone (2026-11-22)
Do not suggest Android phones, another Apple Account or third-party IPA hunting. Owner rejects all these routes. Work on native iPhone discovery through CoreBluetooth only, as a protocol-research prerequisite. Technical evidence: `WiFi+BTOnboarding+BTNotify` in webdjoe/pyvesync#477 for a reported CAF-P583S-KUS device. The new independent draft branch `feature/crisp-native-ble-discovery` adds a read-only, no-connect diagnostic page. This is **not real pairing**; hardware, services, authentication and VeSync account claim are unknown. See `CrispCompanion/PAIRING_RESEARCH.md`.

## Physical BLE scan PASS and D1 UI improvement (2026-11-22)
Owner's seven screenshots confirm native iPhone BLE scan, 20 advertisements, candidate `CAF-P583S-KUS` at -57 dBm. Owner says general list does not identify devices. Do not lose this real-world validation. Latest draft stacked branch `feature/crisp-fryer-focus-gatt-d1` adds fryer-first category and collapses other devices, plus explicit temporary GATT UUID-only inspection with no characteristic reads/writes, no heat commands and no claiming Wi-Fi setup. App version bumped to 0.1.1. CI and real GATT results pending. Earlier D0 branch/pr #103 is still draft, Build1 base PR #101.

## D2 + D3 final observed/technical checkpoint (2026-11-22)
- Owner physically demonstrated flashing Wi-Fi icon after 5-sec control hold, no obvious branded SoftAP on iPhone Wi-Fi listing, BLE `CAF-P583S-KUS` signal -50 dBm while flashing, and identical three GATT services/six characteristic properties vs normal mode. These are hardware-verified, no Wi-Fi association yet.
- D3 independent research is recorded in `CrispCompanion/PROVISIONING_PROTOCOL_RESEARCH.md`. **No exact-model complete first-time BLE protocol or VeSync cloud claim path found**. Other VeSync devices' encrypted BLE key exchange or older COSORI SoftAP setup cannot be copied without verification.
- Official VeSync account portal exists but browser signup/device claims NOT verified. A VeSync account is separate from an Apple Account; do not suggest second Apple Account.
- Next seek sanitized exact-model onboarding trace/spec from pyvesync #477 contributors or a supported SDK from VeSync; do not request repeated scans or build another IPA without new testable information.
- Keep no remote heat start, no firmware OAD writes, no Wi-Fi/password leaks, and no claims of functional fryer control.

## D4 owner-directed cloud-free control study (2026-11-22)
User explicitly prioritizes real device control **without VeSync cloud**, on existing iPhone. FCC 2021 internal photos visibly show ESP32-WROOM-32U board, but owner's current revision not confirmed. Original manual states manufacturer remote cooking start prohibited; retain physical-start safeguard. Stock Espressif BluFi uses FFFF / FF01 / FF02, absent from actual three GATT services; generic BluFi not supported by present evidence. No documented CAF-P583S local BLE control or LAN service found. Best next optional test: allowlisted *passive notify* observation on FFF1 and F000FFE2 while idle, explicitly noting notification subscription changes CCCD; avoid all OAD characteristics, all cooking-command writes, and any forced heating. Model's 12 factory defaults differ from current 11-presets planner; must correct in future app build. Read `CrispCompanion/LOCAL_ONLY_CONTROL_RESEARCH.md` before any implementation. No new IPA or physical control declared from research alone.

## Build 1.2 source change / owner test handoff (2026-11-22)
Branch `feature/crisp-ble-event-observatory-v0.1.2` stacked on research D4. Source adds `BLEEventObservatory.swift` and a separate Settings link; exact-name-only scan `CAF-P583S-KUS`, foreground 45 seconds, subscribes only `FFF1` + `F000FFE2` CCCD, counts metadata (elapsed seconds, channel, byte length), no characteristic value read/write, no OAD/heat command, disconnects when stopped/backgrounded. Also updates manual-planning factory presets to 12 and adds Keep Warm without modifying recipe persistence or bundle ID. New CI unit/static tests; **never claim CI green/IPA ready without inspecting run results**. The app is still not a working local control replacement. Read `CrispCompanion/BUILD_1_2_QA.md` for physical testing.
