import XCTest
@testable import LastSeen

/// Reject old app metadata even when the IPA filename or GitHub artifact says
/// the correct version. Jailbreak package managers depend on these plist keys.
@MainActor
final class BuildIdentityTests: XCTestCase {
    func testShippedAppVersionIsOneThreeNineBuildTwentyTwo() throws {
        let bundle = Bundle(for: GameStore.self)
        let marketing = try XCTUnwrap(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        let build = try XCTUnwrap(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        let identifier = try XCTUnwrap(bundle.bundleIdentifier)

        XCTAssertEqual(marketing, "1.3.9", "The actual installed app version must advance")
        XCTAssertEqual(build, "22", "Every test build must use a strictly newer build number")
        XCTAssertEqual(identifier, "com.valentinebsaa.lastseen.horror")
        XCTAssertFalse((bundle.object(forInfoDictionaryKey: "NSFaceIDUsageDescription") as? String ?? "").isEmpty)
    }

    func testSecondaryContactsUseTheirOwnArtFiles() throws {
        for contact in Neighbor.allCases {
            let name = contact.portraitAssetName
            XCTAssertTrue(name == "Contact_Maya" || name == "Contact_Denise")
            let photo = try XCTUnwrap(PortraitImages.load(name),
                "\(contact.name) has no real bundled portrait")
            XCTAssertGreaterThanOrEqual(photo.size.width, 110)
            XCTAssertGreaterThanOrEqual(photo.size.height, 110)
        }
    }
}
