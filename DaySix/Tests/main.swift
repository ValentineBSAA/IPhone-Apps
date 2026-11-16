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

print("DaySix self-provisioning smoke tests PASSED")
