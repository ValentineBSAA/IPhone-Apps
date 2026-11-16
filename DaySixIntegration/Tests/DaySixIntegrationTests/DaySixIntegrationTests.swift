import XCTest
@testable import DaySixIntegration

private actor TestInstaller: SigningInstalling {
    private var calls = 0
    let returnValue: InstallationDisposition
    init(_ value: InstallationDisposition) { returnValue = value }
    func signAndInstall(ipa: URL) async throws -> InstallationDisposition {
        calls += 1
        return returnValue
    }
    func callCount() -> Int { calls }
}

final class DaySixIntegrationTests: XCTestCase {
    private func makeIPA(valid: Bool = true) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let app = folder.appendingPathComponent("Payload/Test.app", isDirectory: true)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let contents = Data("<?xml version=\"1.0\"?><plist></plist>".utf8)
        try contents.write(to: app.appendingPathComponent(valid ? "Info.plist" : "Other.txt"))
        let target = folder.appendingPathComponent("import.ipa")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-q", "-r", target.path, "Payload"]
        process.currentDirectoryURL = folder
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        return target
    }

    func testAcceptsValidIPAs() throws {
        let ipa = try makeIPA()
        let result = try IPAInspector.inspect(ipa)
        XCTAssertEqual(result.appBundleName, "Test.app")
        XCTAssertGreaterThan(result.fileSize, 0)
    }

    func testRejectsMissingAppBundle() throws {
        let ipa = try makeIPA(valid: false)
        XCTAssertThrowsError(try IPAInspector.inspect(ipa)) { error in
            XCTAssertEqual(error as? IPAInspectionError, .missingAppBundle)
        }
    }

    func testRejectsFakeIPAs() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        try Data("not a zip".utf8).write(to: file)
        XCTAssertThrowsError(try IPAInspector.inspect(file))
    }

    func testFileImportTriggersSigningBackend() async throws {
        let ipa = try makeIPA()
        let installer = TestInstaller(.submittedForInstallation)
        let result = try await DaySixImportService(backend: installer).signAndInstall(ipa: ipa)
        let count = await installer.callCount()
        XCTAssertEqual(count, 1)
        XCTAssertEqual(result.disposition, .submittedForInstallation)
    }

    func testInstallationNotMisreportedAsConfirmed() async throws {
        let ipa = try makeIPA()
        let installer = TestInstaller(.submittedForInstallation)
        let result = try await DaySixImportService(backend: installer).signAndInstall(ipa: ipa)
        XCTAssertNotEqual(result.disposition, .installedAndVerified)
    }

    func testInvalidIPADoesNotCallBackend() async throws {
        let ipa = try makeIPA(valid: false)
        let installer = TestInstaller(.installedAndVerified)
        do { _ = try await DaySixImportService(backend: installer).signAndInstall(ipa: ipa)
            XCTFail("Expected IPA validation to fail")
        } catch { }
        let count = await installer.callCount()
        XCTAssertEqual(count, 0)
    }

    func testDaySixReminders() throws {
        let issued = Date(timeIntervalSince1970: 1_700_000_000)
        let expiry = issued.addingTimeInterval(7 * 86_400)
        let plan = try RenewalPlanner.plan(issuedAt: issued, expiresAt: expiry)
        XCTAssertEqual(plan.firstAttemptAt, issued.addingTimeInterval(6 * 86_400))
        XCTAssertFalse(plan.shouldAttempt(at: issued.addingTimeInterval(5 * 86_400)))
        XCTAssertTrue(plan.shouldAttempt(at: issued.addingTimeInterval(6 * 86_400)))
        XCTAssertFalse(plan.shouldAttempt(at: expiry))
        XCTAssertTrue(plan.isExpired(at: expiry))
    }

    func testShorterProfilePrioritizesExpiry() throws {
        let issued = Date(timeIntervalSince1970: 1_700_000_000)
        let expiry = issued.addingTimeInterval(4 * 86_400)
        let plan = try RenewalPlanner.plan(issuedAt: issued, expiresAt: expiry)
        XCTAssertEqual(plan.firstAttemptAt, issued.addingTimeInterval(3 * 86_400))
    }
}