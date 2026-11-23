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
