import Foundation

/// These fields are attached to an existing manual vitals entry in source.
/// Older records with source == "manual" decode as an empty context.
struct PosiesVitalsContext: Codable, Equatable {
    static let marker = "posies-vitals-v1:"
    var source: String = ""
    var timing: String = ""
    var arm: String = ""
    var resting: String = ""
    var secondSystolic: Int?
    var secondDiastolic: Int?
    var monitorPulse: Int?
    var observedTriggers: [String] = []

    static func read(_ value: String) -> Self {
        guard value.hasPrefix(marker),
              let data = Data(base64Encoded: String(value.dropFirst(marker.count))),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return decoded
    }
    func stored() -> String {
        guard let data = try? JSONEncoder().encode(self) else { return "manual" }
        return Self.marker + data.base64EncodedString()
    }

    var hasSecondReading: Bool { secondSystolic != nil && secondDiastolic != nil }
    func average(firstSystolic: Int, firstDiastolic: Int) -> (Int, Int)? {
        guard let secondSystolic, let secondDiastolic,
              (1...400).contains(secondSystolic), (1...400).contains(secondDiastolic) else { return nil }
        // Display-only average rounded to the nearest mmHg. Both source
        // measurements are retained for historical/report fidelity.
        return ((firstSystolic + secondSystolic + 1) / 2,
                (firstDiastolic + secondDiastolic + 1) / 2)
    }
}

struct PosiesMedicationProfile: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var labelDose: String = ""
    var instructions: String = ""
    var schedule: String = "As needed"
    var refillDate: Date?
    var remainingSupply: Int?
    var notes: String = ""

    var safeToSave: Bool {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleaned.isEmpty && cleaned.count <= 150 &&
            labelDose.count <= 120 && instructions.count <= 1000 &&
            notes.count <= 3000 &&
            (remainingSupply == nil || (0...100000).contains(remainingSupply!))
    }
}

enum PosiesMedicationLibrary {
    static let storageKey = "posiesMedicationProfilesV028"
    static let maximumProfiles = 100

    static func load(from defaults: UserDefaults = .standard) -> [PosiesMedicationProfile] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? PosiesDataTransfer.decoder().decode([PosiesMedicationProfile].self, from: data) else {
            return []
        }
        return Array(decoded.prefix(maximumProfiles))
    }

    @discardableResult
    static func save(_ profiles: [PosiesMedicationProfile], to defaults: UserDefaults = .standard) -> Bool {
        guard profiles.count <= maximumProfiles,
              Set(profiles.map(\.id)).count == profiles.count,
              profiles.allSatisfy(\.safeToSave),
              let encoded = try? PosiesDataTransfer.encoder().encode(profiles) else { return false }
        defaults.set(encoded, forKey: storageKey)
        return true
    }

    static func missing(_ profiles: [PosiesMedicationProfile], from existing: [PosiesMedicationProfile]) -> [PosiesMedicationProfile] {
        let ids = Set(existing.map(\.id))
        return profiles.filter { !ids.contains($0.id) }
    }

    @discardableResult
    static func merge(_ profiles: [PosiesMedicationProfile], into defaults: UserDefaults = .standard) -> Int {
        let old = load(from: defaults)
        let additions = missing(profiles, from: old)
        guard old.count + additions.count <= maximumProfiles,
              save(old + additions, to: defaults) else { return 0 }
        return additions.count
    }
}

enum PosiesGentleGuidance {
    static let pressureSteps = [
        "Use a correctly fitting upper-arm cuff with your monitor, if available.",
        "For a standard seated home reading, rest quietly for five minutes first.",
        "Sit with feet flat, back supported and your arm at heart level.",
        "Take a reading, then another about a minute later if appropriate.",
        "Write down the actual numbers. Do not change medication based on this app."
    ]
    static let pulseSteps = [
        "Use your own heart-rate monitor or a manual pulse count.",
        "Record when the reading was taken and your position if useful.",
        "A single reading cannot explain symptoms or diagnose POTS."
    ]
}
