import XCTest
@testable import POTSTracker

final class InstalledBuildTests: XCTestCase {
    func testVersionComesFromInstalledAppMetadata() {
        let info: [String: Any] = [
            "CFBundleShortVersionString": "0.1.2",
            "CFBundleVersion": "42"
        ]
        XCTAssertEqual(InstalledBuild.version(in: info), "0.1.2")
        XCTAssertEqual(InstalledBuild.number(in: info), "42")
    }

    func testUnexpectedMetadataHasClearFallback() {
        XCTAssertEqual(InstalledBuild.version(in: [:]), "?")
        XCTAssertEqual(InstalledBuild.number(in: [:]), "?")
        XCTAssertEqual(InstalledBuild.number(in: ["CFBundleVersion": NSNumber(value: 24)]), "24")
    }
}