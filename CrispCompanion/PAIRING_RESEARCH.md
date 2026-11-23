# Native first-time pairing research · iPhone-only
Updated 2026-11-22. **Not an implemented provisioning feature.**

## Firm owner constraints
- No Android phone/tablet available.
- No second Apple Account; do not recommend creating or switching to one.
- Apple's App Store cannot be used on the existing account because of outstanding charges.
- No third-party untrusted IPA hunt. Work through the existing signed Crisp Companion IPA.
- Existing hardware: an iPhone + Windows computer + always-on Synology NAS DS418.

## Evidence and limits
- The owner has **never paired** the air fryer to VeSync; `pyvesync` cannot discover it before account provisioning.
- COSORI CAF-P583S-KUS device data reported to `webdjoe/pyvesync#477` contains `connectionType = WiFi+BTOnboarding+BTNotify`: https://github.com/webdjoe/pyvesync/issues/477 . This suggests Bluetooth participates in onboarding but **does not document the BLE protocol**. Only use this as a hypothesis until owner's sticker and on-device advertisement confirm.
- Manufacturer's user manual requires VeSync for adding device and documents a 15-second Wi-Fi reset/disconnect action. Do **not** instruct owner to reset without verifying model and consequences: https://device.report/m/b7de2b864169da5eb67a1f582f5a68af0d08f150590129b120d0ce79ed069a91
- Apple CoreBluetooth scanForPeripherals(withServices:nil) can discover nearby BLE advertisers (not all Wi-Fi devices): https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/scanforperipherals%28withservices%3Aoptions%3A%29 .
- VeSync cloud account registration is **separate** from obtaining Wi-Fi credentials, even if BLE onboarding succeeds.

## Stage D0: Safe discovery (implemented in source; not yet physical-tested)
- Permission prompted only after explicit Start scan; `NSBluetoothAlwaysUsageDescription`.
- Scan from the real iPhone only, while app open; Stop and leaving page ends scan.
- Show local name, signal strength, advertised GATT service UUIDs where broadcast.
- Manufacturer name matches are *unverified hints*. Other BLE devices may appear.
- No connecting/pairing, no characteristic reads/writes, no network credentials, no heater commands.
- No permanent storage, log upload, analytics or automatic identifier sharing.

## Stage D1: Discovery QA on owner hardware
- [ ] Validate exact sticker model and hardware firmware if displayed.
- [ ] Install the diagnostic IPA using owner's existing AltStore workflow.
- [ ] Enable Bluetooth and choose Settings > Find my fryer > Start scan.
- [ ] Observe permission prompt and accessible errors when denied or Bluetooth off.
- [ ] Power fryer at outlet but do not initiate cooking; scan near it.
- [ ] If no advert appears, investigate documented pairing-mode behavior rather than guessing.
- [ ] If a name match appears, record only non-sensitive advertised name/services for local investigation; do not publish UUIDs of nearby unrelated devices.
- [ ] Verify scanning never sends packets or changes fryer state.
- [ ] Report scan evidence without asserting device pairing.

## Stage D2: Protocol research (not implemented)
- [ ] Determine whether manufacturer-specific BLE GATT or Wi-Fi SoftAP/SmartConfig is used.
- [ ] Find legitimate documentation or protocol traces that cover *onboarding*, not only post-pair cloud commands.
- [ ] Discover service and characteristic authentication requirements; avoid guessing writes to unknown hardware.
- [ ] Specify credential handling: on-device-only, user-consented, secure Keychain where applicable, never in GitHub or logs.
- [ ] Determine whether VeSync cloud device claim requires proprietary server authorization, signed challenge or account registration.
- [ ] Build a real provisioning flow **only when verified**, with recoverable errors and no heater actuation.

## Stop rules
No claims of "works with fryer" or "native pairing achieved" based only on BLE scan results. Never attempt commands that change heater state. Never ask the owner to post Wi-Fi passwords, account credentials, device MACs or tokens into GitHub.

## Physical results — D0 BLE scan, Nov 22 2026
User screenshots show `CAF-P583S-KUS` at **-57 dBm** and 19 other nearby advertisements. First real-device BLE detection PASSED. Advertised GATT services were not populated for the model in this scan, which is normal when the advertisement omits a service list. This does not imply the device has no services.

### D1: focused iPhone service discovery (source committed, hardware QA pending)
- Show exact name `CAF-P583S-KUS` as a model-name match, not confirmed paired state.
- Put unrelated devices behind a collapsed disclosure. Identify TVs/JBL ONLY by self-advertised name; do not guess unknown hex names.
- With explicit user action, connect temporarily using CoreBluetooth and call `discoverServices(nil)` then `discoverCharacteristics(nil,for:)` on each reported service.
- DO NOT invoke `readValue`, `writeValue`, `setNotifyValue`, descriptor actions or temperature/heat commands.
- Show service UUIDs and characteristic capability flags only, then disconnect.
- This is reconnaissance, not native pairing. It MAY fail if firmware requires authentication. No reset or router password should be requested.
- A real Bluetooth GATT connection is independent of Wi-Fi association and VeSync cloud claim.
