import XCTest
@testable import POTSTracker

final class PosiesHomeAndCloudBackupTests: XCTestCase {
    func testCarouselHasFourDistinctUsefulPages() {
        XCTAssertEqual(PosiesHomePage.allCases.map(\.title),
                       ["Today", "Your week", "Daily wellbeing", "Coming up"])
        XCTAssertEqual(Set(PosiesHomePage.allCases.map(\.id)).count, 4)
    }

    func testCardOrderPreservesExistingHomeModuleIdentifier() {
        XCTAssertEqual(HomeModule.today.id, "today")
        XCTAssertEqual(HomeLayout.orderedModules(from: HomeLayout.moduleDefault).first, .today)
        XCTAssertEqual(HomeModule.today.title, "Home carousel")
    }

    func testCloudBackupDefaultsRequireExplicitOptIn() {
        let uniqueSuite = "com.valentinebsaa.posies.backup.unit." + UUID().uuidString
        let userDefaults = UserDefaults(suiteName: uniqueSuite)!
        defer { userDefaults.removePersistentDomain(forName: uniqueSuite) }
        XCTAssertFalse(userDefaults.bool(forKey: PosiesBackupPolicy.automaticConsentKey))
        XCTAssertEqual(PosiesBackupPolicy.preferenceKey, "posiesBackupDestinationV025")
        XCTAssertNil(PosiesBackupPolicy.lastSuccessful(userDefaults))
    }

    func testOnlyVerifiedBackupsHaveSuccessfulDates() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let sample = Date(timeIntervalSince1970: 1795230788)
        XCTAssertNil(PosiesBackupPolicy.lastSuccessful(defaults))
        defaults.set(sample, forKey: PosiesBackupPolicy.lastSuccessfulKey)
        XCTAssertEqual(PosiesBackupPolicy.lastSuccessful(defaults), sample)
    }

    func testForegroundRetryDoesNotClaimSuccess() {
        let sample = Date(timeIntervalSince1970: 1795230788)
        XCTAssertTrue(PosiesBackupPolicy.needsForegroundCheck(now: sample, last: nil))
        XCTAssertFalse(PosiesBackupPolicy.needsForegroundCheck(now: sample, last: sample))
        XCTAssertFalse(PosiesBackupPolicy.needsForegroundCheck(
            now: sample.addingTimeInterval(3600), last: sample))
        XCTAssertTrue(PosiesBackupPolicy.needsForegroundCheck(
            now: sample.addingTimeInterval(7 * 3600), last: sample))
    }

    func testDoNotReplaceGoodArchiveWithEmptyStore() {
        XCTAssertFalse(PosiesBackupPolicy.safeToReplacePreviousBackup(newCount: 0, priorCount: 27))
        XCTAssertFalse(PosiesBackupPolicy.safeToReplacePreviousBackup(newCount: 0, priorCount: 0))
        XCTAssertTrue(PosiesBackupPolicy.safeToReplacePreviousBackup(newCount: 1, priorCount: 27))
    }

    func testExistingJSONBackupFormatRemainsRestoreCompatible() throws {
        let payload = PosiesBackupFile(records: [])
        let contents = try PosiesDataTransfer.encoder().encode(payload)
        let preview = try PosiesDataTransfer.inspect(contents, existingIDs: [],
                                                     journalUnlocked: true)
        XCTAssertEqual(preview.archive.format, "pots-posies-local-backup")
        XCTAssertEqual(preview.archive.schemaVersion, 1)
        XCTAssertEqual(preview.additions, 0)
    }

    func testManualExportRemainsAvailableWithoutICloudCapability() {
        // The manual Files exporter must not depend on either backup preference.
        let jsonData = try? PosiesDataTransfer.encodeBackup([])
        XCTAssertNotNil(jsonData)
        XCTAssertTrue(jsonData?.starts(with: Data("{".utf8)) ?? false)
    }
}
