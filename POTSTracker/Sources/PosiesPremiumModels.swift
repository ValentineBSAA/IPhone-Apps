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

/// An optional guided flare-up session saved inside a symptom record.
/// It does not request a diagnostic standing test or an exercise challenge.
struct PosiesFlareContext: Codable, Equatable {
    static let marker = "posies-flare-v1:"
    var startedAt: Date?
    var endedAt: Date?
    var pulse: Int?
    var systolic: Int?
    var diastolic: Int?
    var triggers: [String] = []
    var whatHelped: String = ""

    static func read(_ value: String) -> Self? {
        guard value.hasPrefix(marker),
              let data = Data(base64Encoded: String(value.dropFirst(marker.count))) else { return nil }
        return try? PosiesDataTransfer.decoder().decode(Self.self, from: data)
    }
    func stored() -> String {
        guard let data = try? PosiesDataTransfer.encoder().encode(self) else { return "manual" }
        return Self.marker + data.base64EncodedString()
    }
    var isValid: Bool {
        (pulse == nil || (1...400).contains(pulse!)) &&
        (systolic == nil || (1...400).contains(systolic!)) &&
        (diastolic == nil || (1...400).contains(diastolic!)) &&
        ((systolic == nil) == (diastolic == nil)) &&
        (endedAt == nil || startedAt == nil || endedAt! >= startedAt!) &&
        triggers.count <= 20 && whatHelped.count <= 2000
    }
}

struct PosiesMedicationProfile: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var labelDose: String = ""
    /// Optional structured display metadata. Missing keys in v0.2.x backup
    /// files decode as nil; legacy labelDose text is never guessed or rewritten.
    var strengthAmount: String? = nil
    var strengthUnit: String? = nil
    var dosageForm: String? = nil
    var supplyAmount: String? = nil
    var supplyUnit: String? = nil
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
            (remainingSupply == nil || (0...100000).contains(remainingSupply!)) &&
            PosiesMedicationMeasurements.validPair(
                amount: strengthAmount, unit: strengthUnit,
                units: PosiesMedicationMeasurements.strengthUnits, max: 1000000) &&
            PosiesMedicationMeasurements.validPair(
                amount: supplyAmount, unit: supplyUnit,
                units: PosiesMedicationMeasurements.supplyUnits, max: 100000) &&
            (dosageForm == nil || PosiesMedicationMeasurements.forms.contains(dosageForm!))
    }

    var displayStrength: String {
        if let strengthAmount, let strengthUnit, !strengthAmount.isEmpty {
            return "\(strengthAmount) \(strengthUnit)"
        }
        return labelDose.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var displaySupply: String? {
        if let supplyAmount, let supplyUnit, !supplyAmount.isEmpty {
            return "\(supplyAmount) \(supplyUnit) on hand"
        }
        if let remainingSupply { return "\(remainingSupply) units on hand (older entry)" }
        return nil
    }
}

/// User-entered bottle-label and inventory measurements. No medication
/// strengths, schedules, concentrations, or doses are suggested.
enum PosiesMedicationMeasurements {
    static let strengthUnits = ["mg", "mcg", "g", "mL", "IU", "units", "mEq", "%"]
    static let supplyUnits = ["tablets", "capsules", "mL", "US fl oz", "patches",
                              "puffs", "drops", "packets", "vials", "doses",
                              "bottles", "tubes", "units"]
    static let forms = ["Tablet", "Capsule", "Liquid", "Drops", "Inhaler",
                        "Patch", "Topical", "Injection", "Powder", "Other"]
    static let schedules = ["Daily", "Several times daily", "Weekly", "As needed", "Other"]

    static func validPositiveDecimal(_ value: String, max: Decimal) -> Bool {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count <= 20,
              cleaned.range(of: #"^(0|[1-9][0-9]*)(\.[0-9]{1,4})?$"#,
                            options: .regularExpression) != nil,
              let number = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
        else { return false }
        return number > 0 && number <= max
    }
    static func validPair(amount: String?, unit: String?, units: [String],
                          max: Decimal) -> Bool {
        let value = amount?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let selected = unit ?? ""
        if value.isEmpty && selected.isEmpty { return true }
        return !selected.isEmpty && units.contains(selected) &&
               validPositiveDecimal(value, max: max)
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
