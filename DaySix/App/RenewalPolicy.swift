import Foundation

/// ReProvision-style scheduling policy for stock iOS.
///
/// This controls DaySix's *decision* to request a refresh through the user's
/// configured SideStore Shortcut. It is NOT a jailbreak daemon and cannot
/// force iOS to run a particular background task at a specific time.
enum RenewalPolicy {
    static let hoursKey = "daysix.renewal.windowHours.v1"
    static let autoKey = "daysix.renewal.autoEnabled.v1"

    static let supportedHours = [12, 24, 36, 48]
    static let defaultHours = 24

    static var hoursBeforeExpiry: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: hoursKey) as? Int
            guard let stored, supportedHours.contains(stored) else { return defaultHours }
            return stored
        }
        set {
            UserDefaults.standard.set(
                supportedHours.contains(newValue) ? newValue : defaultHours,
                forKey: hoursKey)
        }
    }

    /// Default true: "Check DaySix Refresh" can request the external signer
    /// when a signature enters its renewal window.
    static var automaticallyRequestRefresh: Bool {
        get {
            guard UserDefaults.standard.object(forKey: autoKey) != nil else { return true }
            return UserDefaults.standard.bool(forKey: autoKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: autoKey) }
    }

    static func renewAt(expiration: Date) -> Date {
        expiration.addingTimeInterval(-Double(hoursBeforeExpiry) * 60 * 60)
    }

    static func isDue(expiration: Date, now: Date = .now) -> Bool {
        now >= renewAt(expiration: expiration)
    }

    /// Prevent an unsuccessful external Shortcuts action from repeatedly
    /// requesting Apple provisioning operations in a tight loop. This is a
    /// *minimum interval* between requests, not a background retry daemon.
    static let minimumAttemptSpacing: TimeInterval = 6 * 60 * 60

    static func retryAllowed(lastAttempt: Date?, now: Date = .now) -> Bool {
        guard let lastAttempt else { return true }
        // Future timestamps can result from clock changes; wait rather than
        // requesting multiple provisioning attempts immediately.
        return now.timeIntervalSince(lastAttempt) >= minimumAttemptSpacing
    }

    static func dueAndRetryable(expiration: Date,
                                lastAttempt: Date?,
                                now: Date = .now) -> Bool {
        expiration > now
            && isDue(expiration: expiration, now: now)
            && retryAllowed(lastAttempt: lastAttempt, now: now)
    }

    static func shouldRunAutomaticRenewal(expirations: [Date], now: Date = .now) -> Bool {
        automaticallyRequestRefresh && expirations.contains {
            // Do not advertise signing an already expired app as an on-time
            // renewal. Expired apps require explicit recovery in the signer.
            $0 > now && isDue(expiration: $0, now: now)
        }
    }
}
