# DaySix policy smoke tests

Run these Foundation-only tests independently from the Xcode iOS build:

```sh
swiftc DaySix/App/RenewalPolicy.swift DaySix/App/SelfProvisioning.swift DaySix/Tests/main.swift -o /tmp/daysix-tests
/tmp/daysix-tests
```

The Linux workflow exists because macOS iPhone SDK build runners can be queued for longer than a normal coding session. These tests validate date parsing, manual expiration fallback, 12/24/36/48-hour renewal windows, the day-six default, the 6-hour attempt cooldown, and expected expiration behavior.

Passing these tests **does not** prove a signed installation, that an IPA can re-sign itself, or that iOS will wake the app in the background. Those remain physical-device acceptance tests.
