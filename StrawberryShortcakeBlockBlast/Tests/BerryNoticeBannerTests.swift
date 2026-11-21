import SwiftUI
import UIKit
import XCTest
@testable import BerryBlockBlast

/// Reusable strawberry-themed in-app notices are presentation-only.
/// They never grant berries, modify saves or dispatch system notifications.
@MainActor
final class BerryNoticeBannerTests: XCTestCase {
    func testThreeNoticeVariantsHaveStableLabelsAndSymbols() {
        XCTAssertEqual(BerryNoticeKind.allCases.count, 3)
        XCTAssertEqual(BerryNoticeKind.success.rawValue, "Success")
        XCTAssertEqual(BerryNoticeKind.information.rawValue, "Information")
        XCTAssertEqual(BerryNoticeKind.caution.rawValue, "Attention")
        XCTAssertEqual(Set(BerryNoticeKind.allCases.map(\.icon)).count, 3)
        XCTAssertNotNil(UIImage(named: "Strawberry_Currency"))
        XCTAssertNotNil(UIImage(named: "Dev_Notification_Test_Berry_Bell"))
        XCTAssertNotNil(UIImage(named: "Dev_Timers_Moon_Clock"))
    }

    func testNoticeRendersWithoutTouchingAnyPersistentEconomyOrSave() {
        let suite = "berry.notice.viewonly.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let wallet = "berryblockblast.inventory.v3"
        let save = "berryblockblast.endless.saved-8.v056b2"
        let sentinel = Data([0x42, 0x45, 0x52, 0x52, 0x59])
        defaults.set(sentinel, forKey: wallet)
        defaults.set(sentinel, forKey: save)

        for kind in BerryNoticeKind.allCases {
            let host = UIHostingController(rootView: BerryNoticeBanner(
                message: "Safe visual-only preview", kind: kind
            ))
            host.loadViewIfNeeded()
            XCTAssertNotNil(host.view)
            XCTAssertEqual(defaults.data(forKey: wallet), sentinel)
            XCTAssertEqual(defaults.data(forKey: save), sentinel)
        }
    }
}
