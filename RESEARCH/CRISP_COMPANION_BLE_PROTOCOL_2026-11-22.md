# Crisp Companion — Public BLE protocol research, 2026-11-22

Status: **public-source comparison + owner's hardware observations, not a decoded CAF-P583S protocol**. This document is a source-backed research note and does not change or ship the iPhone app.

## Question
Are the owner's repeated 10-byte `FFF1` notifications from COSORI CAF-P583S-KUS compatible with a documented framing protocol? Is a local, VeSync-independent status/control interface demonstrated?

**Answer:** A *different* COSORI product, a BLE kettle, has an open-source protocol using identical `FFF0` service, `FFF1` notify and `FFF2` write identifiers. It uses a six-byte header with sequence at offset 2 and checksum-like field at offset 5. In its source, one 10-byte *outgoing poll/command builder* computes `check = (0xB4 - seq) & 0xFF`. The resulting relationship `seq + check = constant (mod 256)` strongly resembles the owner's FFF1 observation. However no matching **air fryer packet header** has been confirmed, and kettle status notifications are typically *18 or 35 bytes*, unlike the owner's 10-byte fryer messages. The link is a plausible research hypothesis, not protocol proof or compatible control code.

## Owner's direct observations (read-only, idle/non-heating, no raw values retained)
- Advertised exact name: `CAF-P583S-KUS`.
- Discovered GATT `FFF0/FFF1/FFF2`, `F000FFE0-.../FFE1/FFE2`, `F000FFC0-.../FFC1/FFC2`.
- v0.1.4: 12 presets x 2 passes: one FFF1 packet per five-second window; zero identical whole-packet patterns for corresponding presets.
- v0.1.5 completed follow-up: four valid 10-byte FFF1 packets, no idle notifications, changing zero-based positions **2, 5** in both cross-preset and same-preset comparisons.
- v0.1.6 completed three-prompt experiment: one 10-byte FFF1 packet per physical-action window, none in 10-second untouched baseline. Only byte positions **2 and 5** changed, offset 2 increased by +1 on both adjacent packet transitions, offsets 2+5 sum constant modulo 256 in those three frames. Offset 5 did not increase by +1. First-event time was 2.3s/1.3s/1.2s from prompt onset, **not from the actual touch**. No stable preset code identified.

## Public-source comparison, with limitations

| Evidence | What it supports | What it does NOT support |
|---|---|---|
| [CosoriKettleBLE implementation](https://github.com/barrymichels/CosoriKettleBLE/blob/main/components/cosori_kettle_ble/cosori_kettle_ble.cpp) | Different COSORI kettle uses BLE `FFF0` service, `FFF1` notifications, `FFF2` writes. Parser recognizes `0xA5` header, packet type at 1, sequence at 2, declared payload length bytes 3-4, a checksum-like byte 5, payload thereafter. `make_poll_` sends a 6+4=10-byte packet with `checksum=(0xB4-seq)&0xFF`; other message builders also subtract the sequence. | Does **not** demonstrate that CAF-P583S firmware uses this protocol, or that an *incoming fryer* 10-byte notification is the kettle's 10-byte **outgoing** poll. Never replay kettle examples at the fryer. |
| [CosoriKettleBLE PROTOCOL.md](https://github.com/barrymichels/CosoriKettleBLE/blob/main/PROTOCOL.md) | Describes kettle status frames with 6-byte headers. Compact status: 18 bytes; extended status: 35 bytes, further suggesting 10-byte fryer notifications are not directly a confirmed kettle status structure. | Its generic checksum prose says it is a direct sum, yet builder code uses a constant *minus* sequence. **Source conflict**: do not trust the prose equation as validated for all packet types. |
| [Generic BLE FFF1/FFF2 usage](https://blog.cubable.date/reverse-engineering-my-aroma-diffuser-inside-the-araams-bluetooth-protocol/) | These standard-base 16-bit GATT numbers occur across unrelated electronics. | Identical UUIDs do not establish the same higher-level packet semantics, authentication or capabilities. |
| [TI OAD evidence](https://e2echina.ti.com/blogs_/b/the_process/posts/cc2640r2-ti-ble-oad-ota-android-ios-app) and [TI SensorTag UUID list](https://github.com/pybricks/technical-info/blob/master/assigned-numbers.md) | The user's `F000FFC0/FFC1/FFC2` service/characteristics match TI Over-the-Air Download identifiers. `F000FFE0` may correspond to TI SensorTag simple-key service, **not** a proven fryer-control characteristic. | Does not prove exact SoC part or firmware family. Never interact with firmware-update characteristics in app research. |
| [Home Assistant VeSync integration](https://www.home-assistant.io/integrations/vesync) and [Cosori integration](https://www.home-assistant.io/integrations/cosori/) | Supported integrations expect the device to be registered with VeSync app first. | Do not confuse VeSync cloud endpoints with an authenticated direct BLE or LAN interface. |
| [RedsGT VeSync Enhanced CAF-P583S integration](https://github.com/RedsGT/hass-vesync-enhanced) | Community supports this air fryer through a pyvesync cloud-based flow for previously enrolled devices. | It is not documented first-time BLE provisioning or verified local/offline control. Do not adopt remote heater-start functionality. |
| [Arovast / CAF-P583S FCC filing](https://fccid.io/2ARBY-CAF-P583S) | Public equipment filing confirms this radio-enabled product family and exposes internal photos/test reports. | Does not publish a protocol or prove which BLE chipset emitted the observed notifications. |
| [Espressif BluFi documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/ble/blufi.html) | BluFi is a particular ESP32 Wi-Fi provisioning scheme. | No evidence that this fryer's actual UUIDs, handshake or device protocol match BluFi. Do not send speculative onboarding writes. |

## Research judgment

1. **Strongest connection:** the observed math `b2+1, b5-1`, constant modulo-256 sum, precisely resembles **one documented kettle frame-builder pattern** using `b2=seq`, `b5=K-seq`. This is worth testing, not assuming.
2. **Critical missing discriminator:** unknown fryer `FFF1` byte 0/1 values and whether bytes 3-4 encode length. The kettle has `[A5, type, seq, lenLo, lenHi, check]` followed by payload. All four fixed / variable bytes could be a generic idle ACK or acknowledgment, not cooking status.
3. **Length mismatch:** a 10-byte kettle poll is a *command sent to* the kettle, whereas its documented compact and extended *incoming status notifications* are 18 and 35 bytes. Don't describe the fryer's 10-byte notifications as cooked-state telemetry without proof.
4. **General status:** No directly verified, documented **CAF-P583S-KUS BLE** decoder or authenticated local LAN API was found in the inspected sources. User's installed v0.1.6 remains a passive diagnostic app, not a replacement for VeSync registration.

## Next experiment gate (PROPOSED ONLY; no new IPA approved by this note)

Create a tiny **read-only in-memory header-compatibility checker** attached to FFF1 with one physically chosen setting change (NOT Start / heat). It must not export raw packet bytes, only report booleans and counts:
- Observed packet lengths, and fraction that are exactly 10.
- Whether each incoming 10-byte packet has expected kettle-style `byte[0]==0xA5`, and whether `byte[1]` matches a documented type such as `0x12`/`0x22`; don't treat absence as no local protocol.
- Whether `littleEndian(byte[3:5]) == packet.count-6`, which would be `4` for 10-byte frames.
- Whether the first six positions are stable except 2/5; whether byte 2 increments +1 and b2+b5 is constant across three or more *sequential* frames.
- Count packets during untouched idle vs physical input; no exact touch-timestamp claims.
- Build **synthetic XCTest** and source static guards proving no `CBPeripheral.writeValue` / `readValue` / OAD. CCCD notification descriptor configuration is the sole allowed BLE write.
- No auto-pair, no passwords, no Wi-Fi setup, no serial TX, no cooking/heater commands. Explicit owner opt-in and immediate disconnect on Stop, exit, app background or timeout; keep ephemeral buffers bounded and erase them on finish.

Only if this header shape matches consistently should we consider a more comprehensive *passive status parser*; even then, require independently validated temperature/time fields before showing any live appliance value. Preserve manual offline planning, existing AltStore identifier and saved recipes. Avoid more preset marathons. A failed header match means the kettle analogy is not applicable, not that no local BLE status is possible.

## Links
- Kettle source and documented format: https://github.com/barrymichels/CosoriKettleBLE/blob/main/PROTOCOL.md and https://github.com/barrymichels/CosoriKettleBLE/blob/main/components/cosori_kettle_ble/cosori_kettle_ble.cpp
- CAF-P583S cloud-focused integration: https://github.com/RedsGT/hass-vesync-enhanced
- CAF-P583S FCC filing and open exhibits: https://fccid.io/2ARBY-CAF-P583S
- TI firmware-update OAD identifiers: https://e2echina.ti.com/blogs_/b/the_process/posts/cc2640r2-ti-ble-oad-ota-android-ios-app
