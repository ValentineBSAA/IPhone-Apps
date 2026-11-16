import Foundation

/// Standalone Foundation-only smoke tests: no simulator or paid Apple team
/// needed. These exercise both the CMS-wrapper extraction and date parsing.
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

let expected = Date(timeIntervalSince1970: 1_800_000_000)
let dict: [String: Any] = [
    "ExpirationDate": expected,
    "Name": "DaySix smoke test",
    "TeamIdentifier": ["TEST123456"]
]
let xml = try PropertyListSerialization.data(
    fromPropertyList: dict, format: .xml, options: 0)
let wrapped = Data([0x30, 0x82, 0x01, 0x00, 0x00, 0xFF]) + xml +
    Data([0x00, 0xFE, 0x82, 0x30])
let parsed = SelfProvisioning.expirationDate(in: wrapped)

expect(parsed != nil, "CMS-wrapped XML profile must be parsed")
expect(abs(parsed!.timeIntervalSince(expected)) < 1,
       "Profile expiration date must equal embedded plist value")
expect(SelfProvisioning.expirationDate(in: Data([0x30, 0x80, 0xFF])) == nil,
       "Malformed profiles must yield unknown rather than a fabricated date")

var noExpiration = try PropertyListSerialization.data(
    fromPropertyList: ["Name": "No expiration"], format: .xml, options: 0)
noExpiration.append(contentsOf: [0x00, 0x01])
expect(SelfProvisioning.expirationDate(in: noExpiration) == nil,
       "Profiles without ExpirationDate must yield unknown")

if SelfProvisioning.expiresAt == nil {
    let future = Date.now.addingTimeInterval(3 * 86_400)
    SelfProvisioning.setManualExpiry(future)
    expect(SelfProvisioning.effectiveExpiry != nil,
           "Manual fallback must provide the expiry when the embedded profile is absent")
    expect(!SelfProvisioning.isDue,
           "Manual fallback with three days remaining must not trigger refresh yet")
    SelfProvisioning.setManualExpiry(Date.now.addingTimeInterval(12 * 3_600))
    expect(SelfProvisioning.isDue,
           "Manual fallback must trigger refresh with less than 24 hours remaining")
    SelfProvisioning.setManualExpiry(Date.now.addingTimeInterval(-3_600))
    expect(SelfProvisioning.isExpired,
           "Expired manual fallback must indicate expiration")
    UserDefaults.standard.removeObject(forKey: "daysix.self.manuallyEnteredExpiry.v1")
}

// ReProvision-style configurable scheduling: day-six default, guardrails,
// manual disable and longer lead times. No access to Apple credentials.
RenewalPolicy.hoursBeforeExpiry = 24
RenewalPolicy.automaticallyRequestRefresh = true
let now = Date.now

let expiresIn25 = now.addingTimeInterval(25 * 3600)
let expiresIn23 = now.addingTimeInterval(23 * 3600)
expect(!RenewalPolicy.isDue(expiration: expiresIn25, now: now),
       "25 hours left should be outside the default renewal window")
expect(RenewalPolicy.isDue(expiration: expiresIn23, now: now),
       "23 hours left should be inside the default day-six window")
expect(!RenewalPolicy.shouldRunAutomaticRenewal(expirations: [expiresIn25], now: now),
       "A healthy app must not trigger automatic signing")
expect(RenewalPolicy.shouldRunAutomaticRenewal(expirations: [expiresIn23], now: now),
       "Day-six expiry must trigger the external signer request")

RenewalPolicy.hoursBeforeExpiry = 48
expect(RenewalPolicy.isDue(
           expiration: now.addingTimeInterval(36 * 3600), now: now),
       "48-hour mode must refresh before a 36-hour expiration")

RenewalPolicy.hoursBeforeExpiry = 999
expect(RenewalPolicy.hoursBeforeExpiry == 24,
       "Unsupported renewal windows must revert to the day-six default")

RenewalPolicy.automaticallyRequestRefresh = false
expect(!RenewalPolicy.shouldRunAutomaticRenewal(
           expirations: [expiresIn23], now: now),
       "Disabling automatic requests must actually suppress Shortcuts activation")

RenewalPolicy.automaticallyRequestRefresh = true
expect(!RenewalPolicy.shouldRunAutomaticRenewal(
           expirations: [now.addingTimeInterval(-3600)], now: now),
       "Already expired signing must not be falsely reported as an on-time renewal")

// Cooldown protects against repeated Apple account provisioning requests
// when SideStore's App Intent silently fails on iOS 27.
RenewalPolicy.hoursBeforeExpiry = 24
expect(RenewalPolicy.dueAndRetryable(
    expiration: expiresIn23, lastAttempt: nil, now: now),
    "An app with no previous attempt should be retryable on day six")
expect(!RenewalPolicy.retryAllowed(
    lastAttempt: now.addingTimeInterval(-2 * 3600), now: now),
    "A two-hour-old attempt must not trigger a new automatic signature")
expect(RenewalPolicy.retryAllowed(
    lastAttempt: now.addingTimeInterval(-7 * 3600), now: now),
    "A seven-hour-old attempt must allow a later retry")
expect(!RenewalPolicy.dueAndRetryable(
    expiration: now.addingTimeInterval(-3600),
    lastAttempt: nil, now: now),
    "An expired signing window should require manual recovery")

UserDefaults.standard.removeObject(forKey: RenewalPolicy.hoursKey)
UserDefaults.standard.removeObject(forKey: RenewalPolicy.autoKey)

print("DaySix provisioning and ReProvision-style scheduling smoke tests PASSED")
