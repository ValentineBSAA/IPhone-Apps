import Foundation

/// Local, auditable log. Never stores signing credentials, provisioning
/// documents, pairing files, or personally identifying Apple account data.
enum RenewalAudit {
    struct Entry: Codable, Identifiable {
        enum Event: String, Codable {
            case initialSignature
            case selfSignatureRenewed
            case profileChanged
            case automationAttempt
        }

        var id: UUID = UUID()
        var date: Date = .now
        var event: Event
        var message: String
    }

    private static let historyKey = "daysix.audit.history.v1"
    private static let lastExpiryKey = "daysix.audit.ownExpiry.v1"

    static var lastObservedExpiry: Date? {
        UserDefaults.standard.object(forKey: lastExpiryKey) as? Date
    }

    static var entries: [Entry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let result = try? JSONDecoder().decode([Entry].self, from: data)
        else { return [] }
        return result.sorted(by: { $0.date > $1.date })
    }

    static var lastVerifiedSelfRenewal: Date? {
        entries.first(where: { $0.event == .selfSignatureRenewed })?.date
    }

    static func record(_ event: Entry.Event, _ message: String) {
        var list = entries
        list.insert(Entry(event: event, message: message), at: 0)
        if let value = try? JSONEncoder().encode(Array(list.prefix(50))) {
            UserDefaults.standard.set(value, forKey: historyKey)
        }
    }

    /// Calling repeatedly is safe. A verified self-refresh is recorded ONLY
    /// when the app actually launches with a later embedded provisioning
    /// expiration than its previously observed expiration.
    static func reconcileSelfSignature() {
        guard let currentExpiry = SelfProvisioning.expiresAt else { return }
        let previous = lastObservedExpiry

        if let previous {
            if currentExpiry.timeIntervalSince(previous) > 60 {
                record(.selfSignatureRenewed, "DaySix's embedded Apple provisioning expiration increased; renewal verified.")
            } else if previous.timeIntervalSince(currentExpiry) > 60 {
                record(.profileChanged, "Provisioning expiration decreased. Verify the current signing account in SideStore.")
            }
        } else {
            record(.initialSignature, "DaySix established its first on-device provisioning baseline.")
        }

        if previous == nil || abs(currentExpiry.timeIntervalSince(previous!)) > 60 {
            UserDefaults.standard.set(currentExpiry, forKey: lastExpiryKey)
        }
    }
}
