import XCTest
import SwiftUI
import UIKit
@testable import BerryBlockBlast

@MainActor
final class BerryDailyHarvestAlmanacTests: XCTestCase {
    func testLegacyCompletedDayStillShowsAsWon() {
        let suite = "berry-almanac-tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not isolate test UserDefaults"); return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let past = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        defaults.set([BerryDailyHistory.dateKey(for: past)],
                     forKey: BerryDailyHistory.key)
        XCTAssertEqual(BerryDailyHistory.outcome(on: past, defaults: defaults), .won)
    }

    func testNoHistoricalDayGetsFakeWinOrMultipleDailyAttempts() {
        let suite = "berry-almanac-tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not isolate test UserDefaults"); return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let past = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        XCTAssertNil(BerryDailyHistory.outcome(on: past, defaults: defaults))
        XCTAssertTrue(BerryDailyHistory.beginToday(defaults: defaults))
        XCTAssertEqual(BerryDailyHistory.outcome(defaults: defaults), .active)
        BerryDailyHistory.markLostToday(defaults: defaults)
        XCTAssertEqual(BerryDailyHistory.outcome(defaults: defaults), .lost)
        XCTAssertFalse(BerryDailyHistory.beginToday(defaults: defaults),
                       "Daily Harvest must not allow an extra attempt")
    }

    func testStreakLadderIsStillTheOriginalSevenRewards() {
        XCTAssertEqual((1...7).map(BerryDailyHistory.reward(forStreakDay:)),
                       [10, 15, 20, 25, 30, 40, 50])
        XCTAssertEqual(BerryDailyHistory.reward(forStreakDay: 12), 50)
    }

    func testEntireThemedAlmanacCanRenderAt393PointWidth() {
        let width: CGFloat = 393
        let height: CGFloat = 759
        let view = BerryDailyHarvestView(goal: 155)
            .frame(width: width, height: height)
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.06))
        XCTAssertEqual(host.view.bounds.width, width, accuracy: 0.1)
        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { context in
            host.view.layer.render(in: context.cgContext)
        }
        let shot = XCTAttachment(image: image)
        shot.name = "Harvest-Almanac-Full-Screen-393pt"
        shot.lifetime = .keepAlways
        add(shot)
        window.isHidden = true
    }
}
