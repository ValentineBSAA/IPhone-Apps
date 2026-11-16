import Foundation

/// Reads the current app's own embedded Apple provisioning profile.
/// Unlike the manual tracking dates for third-party apps, this value changes
/// when DaySix is genuinely re-signed with a new provisioning profile.
///
/// The profile can be missing or encoded differently with some signing flows.
/// In that case we deliberately return nil: UNKNOWN, not a fake "7 days".
enum SelfProvisioning {
    static var expiresAt: Date? {
        let bundleURL = Bundle.main.bundleURL
        for filename in ["embedded.mobileprovision", "embedded.provisionprofile"] {
            let url = bundleURL.appendingPathComponent(filename)
            guard let data = try? Data(contentsOf: url),
                  let expiry = expirationDate(in: data) else { continue }
            return expiry
        }
        return nil
    }

    /// Fallback when a compatible signing profile is not embedded in the
    /// installed app. The user must enter the actual expiration from SideStore.
    /// This manual value is NEVER treated as a verified signature.
    private static let fallbackExpiryKey = "daysix.self.manuallyEnteredExpiry.v1"

    static var manualExpiry: Date? {
        UserDefaults.standard.object(forKey: fallbackExpiryKey) as? Date
    }

    static func setManualExpiry(_ date: Date) {
        UserDefaults.standard.set(date, forKey: fallbackExpiryKey)
    }

    static var effectiveExpiry: Date? { expiresAt ?? manualExpiry }

    static var refreshDueAt: Date? {
        effectiveExpiry?.addingTimeInterval(-24 * 60 * 60)
    }

    static var isDue: Bool {
        guard let refreshDueAt else { return false }
        return Date.now >= refreshDueAt
    }

    static var isExpired: Bool {
        guard let expiry = effectiveExpiry else { return false }
        return Date.now >= expiry
    }

    static func expirationDate(in signedCMSData: Data) -> Date? {
        // Apple's embedded.mobileprovision has historically contained an XML
        // property list inside a CMS envelope. Parse that plist without
        // bypassing OS trust verification or requiring access to credentials.
        let xml = Data("<?xml".utf8)
        let plist = Data("<plist".utf8)
        let endMarker = Data("</plist>".utf8)

        guard let start = signedCMSData.range(of: xml)
                ?? signedCMSData.range(of: plist),
              let end = signedCMSData.range(
                of: endMarker, in: start.lowerBound..<signedCMSData.endIndex)
        else { return nil }

        let slice = Data(signedCMSData[start.lowerBound..<end.upperBound])
        guard let dictionary = try? PropertyListSerialization.propertyList(
            from: slice, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return dictionary["ExpirationDate"] as? Date
    }
}
