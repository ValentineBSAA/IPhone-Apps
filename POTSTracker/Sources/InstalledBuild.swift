import Foundation

/// Reads the installed app's Info.plist, not a hard-coded UI label.
/// CI stamps CFBundleVersion with its monotonically increasing GitHub run number.
/// Offline-safe: this identifies the installed build; it does not check for new releases.
enum InstalledBuild {
    static func version(in info: [String: Any]) -> String {
        let value = info["CFBundleShortVersionString"] as? String
        return (value?.isEmpty == false) ? value! : "?"
    }

    static func number(in info: [String: Any]) -> String {
        let value = info["CFBundleVersion"]
        if let text = value as? String, !text.isEmpty { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return "?"
    }

    static var version: String { version(in: Bundle.main.infoDictionary ?? [:]) }
    static var number: String { number(in: Bundle.main.infoDictionary ?? [:]) }

    static var shortLabel: String { "v\(version) · \(number)" }
    static var fullLabel: String { "Version \(version) · Build \(number)" }
}
