import XCTest
@testable import POTSTracker

final class PosiesPremiumCareTests: XCTestCase {
    func testVitalsMetadataCanReadOldManualRecords() {
        let old = PosiesVitalsContext.read("manual")
        XCTAssertTrue(old.source.isEmpty)
        XCTAssertNil(old.secondSystolic)
        XCTAssertNil(old.average(firstSystolic: 118, firstDiastolic: 76))
    }

    func testPairedPressurePreservesTwoReadingsAndCalculatesAverage() {
        var value = PosiesVitalsContext()
        value.source = "Upper-arm cuff"
        value.timing = "Resting"
        value.secondSystolic = 122
        value.secondDiastolic = 80
        value.monitorPulse = 75
        let decoded = PosiesVitalsContext.read(value.stored())
        XCTAssertEqual(decoded, value)
        let average = decoded.average(firstSystolic: 118, firstDiastolic: 76)
        XCTAssertEqual(average?.0, 120)
        XCTAssertEqual(average?.1, 78)
        XCTAssertEqual(decoded.secondSystolic, 122)
    }

    func testFlareSessionIsOptionalAndRejectsBadPairedMeasurements() {
        var session = PosiesFlareContext()
        session.startedAt = Date(timeIntervalSince1970: 1795260000)
        session.triggers = ["Heat", "After food"]
        session.pulse = 109
        session.whatHelped = "Rest"
        XCTAssertTrue(session.isValid)
        XCTAssertEqual(PosiesFlareContext.read(session.stored()), session)
        session.systolic = 119
        XCTAssertFalse(session.isValid)
        session.diastolic = 81
        XCTAssertTrue(session.isValid)
        session.pulse = 500
        XCTAssertFalse(session.isValid)
    }

    func testMedicationProfileValidationAndPreservedUserChoice() {
        let profile = PosiesMedicationProfile(name: "Example medication")
        XCTAssertTrue(profile.safeToSave)
        XCTAssertEqual(profile.schedule, "As needed")
        XCTAssertTrue(profile.labelDose.isEmpty)
        XCTAssertFalse(PosiesMedicationProfile(name: "  ").safeToSave)
    }

    func testMedicationCabinetRoundTripAndUuidDuplicateProtection() {
        let suite = "com.valentinebsaa.potstracker.tests.cabinet." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var item = PosiesMedicationProfile(name: "Test only")
        item.labelDose = "As on label"
        item.remainingSupply = 10
        XCTAssertTrue(PosiesMedicationLibrary.save([item], to: defaults))
        XCTAssertEqual(PosiesMedicationLibrary.load(from: defaults), [item])
        XCTAssertEqual(PosiesMedicationLibrary.merge([item], into: defaults), 0)
        let newItem = PosiesMedicationProfile(name: "Another test")
        XCTAssertEqual(PosiesMedicationLibrary.merge([newItem], into: defaults), 1)
        XCTAssertEqual(PosiesMedicationLibrary.load(from: defaults).count, 2)
    }

    func testOldArchivesDecodeWithoutMedicationProfiles() throws {
        let original = try PosiesDataTransfer.encoder().encode(PosiesBackupFile(records: []))
        let legacy = try PosiesDataTransfer.decoder().decode(PosiesBackupFile.self, from: original)
        XCTAssertEqual(legacy.schemaVersion, 1)
        XCTAssertTrue(legacy.records.isEmpty)
    }

    func testProfileArchiveIsStillVersionOneWithOptionalProfiles() throws {
        var bundle = PosiesBackupFile(records: [])
        bundle.medicationProfiles = [PosiesMedicationProfile(name: "Example")]
        let data = try PosiesDataTransfer.encoder().encode(bundle)
        let result = try PosiesDataTransfer.decoder().decode(PosiesBackupFile.self, from: data)
        XCTAssertEqual(result.schemaVersion, 1)
        XCTAssertEqual(result.medicationProfiles?.count, 1)
    }

    func testPrivateNotificationTextDoesNotRevealMedicationOrDose() {
        let hidden = PosiesReminderPresentation.title(for: "Medication", revealType: false)
        XCTAssertEqual(hidden, "POTS & Posies 🌸")
        let shown = PosiesReminderPresentation.title(for: "Medication", revealType: true)
        XCTAssertTrue(shown.contains("medication"))
        XCTAssertFalse(shown.contains("dose"))
        XCTAssertEqual(PosiesReminderPresentation.body,
                       "Your reminder is here whenever you're ready.")
    }

    func testNewReminderCategoriesAreAvailableWithPreviousOnes() {
        for category in ["Medication", "Refill", "Heart Rate", "Blood Pressure", "Hydration",
                         "Rest", "Check-in", "Journal", "Personal"] {
            XCTAssertTrue(PosiesReminder.supportedCategories.contains(category))
        }
    }

    func testGuidanceDoesNotImplyDiagnosisOrPrescribedTargets() {
        XCTAssertTrue(PosiesGentleGuidance.pressureSteps.contains {
            $0.contains("five minutes")
        })
        XCTAssertTrue(PosiesGentleGuidance.pulseSteps.contains {
            $0.contains("cannot") || $0.contains("diagnose")
        })
    }
}
