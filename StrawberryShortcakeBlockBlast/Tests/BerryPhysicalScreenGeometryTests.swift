import UIKit
import SwiftUI
import XCTest
@testable import BerryBlockBlast

/// Run this test separately on actual 14 Pro and 16 simulator profiles.
/// A 393x759 dummy UIWindow is NOT a substitute for a simulator screen:
/// safe areas, Dynamic Island and the home indicator belong to the OS.
@MainActor
final class BerryPhysicalScreenGeometryTests: XCTestCase {
    private let epsilon: CGFloat = 2

    func testClassicAndNightmareRespectActualPhoneSafeAreaAndTray() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else {
            XCTFail("No UIKit UIWindowScene. A real device simulator is mandatory.")
            return
        }
        let screen = scene.screen
        let bounds = screen.bounds
        let oldWelcome = UserDefaults.standard.object(forKey: "berryblockblast.welcomed.v3")
        let oldSound = UserDefaults.standard.object(forKey: "berryblockblast.sound")
        let oldMusic = UserDefaults.standard.object(forKey: "berryblockblast.music")
        UserDefaults.standard.set(true, forKey: "berryblockblast.welcomed.v3")
        UserDefaults.standard.set(false, forKey: "berryblockblast.sound")
        UserDefaults.standard.set(false, forKey: "berryblockblast.music")
        defer {
            restore("berryblockblast.welcomed.v3", oldWelcome)
            restore("berryblockblast.sound", oldSound)
            restore("berryblockblast.music", oldMusic)
        }

        XCTAssertGreaterThan(bounds.width, 300, "Device must have a real usable display")
        XCTAssertLessThan(bounds.width, bounds.height, "Portrait iPhone required")
        // Same logical width, but actual safe area comes from the OS,
        // rather than a hardcoded approximation.
        XCTAssertEqual(bounds.width, 393, accuracy: 1,
                       "Run this gate on iPhone 14 Pro and iPhone 16 simulators")
        XCTAssertEqual(bounds.height, 852, accuracy: 2,
                       "Wrong simulator device profile or display configuration")

        for mode: BerryMode in [.classic, .superHard] {
            let previousKeyWindow = scene.windows.first(where: { $0.isKeyWindow })
            let host = UIHostingController(
                rootView: BerryGameView(mode: mode, onExit: {})
            )
            let window = UIWindow(windowScene: scene)
            window.frame = bounds
            window.windowLevel = .normal + 1
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.frame = window.bounds
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            // Allow scene safe areas and SwiftUI/UIKit coordinates to settle.
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
            host.view.layoutIfNeeded()
            window.layoutIfNeeded()

            let safe = window.safeAreaLayoutGuide.layoutFrame
            let views = descendants(host.view)
            let boardViews = views.compactMap { $0 as? BerryBoardWindowTrackingView }
            let touchViews = views.compactMap { $0 as? BerryTouchTrackingView }
            XCTAssertEqual(boardViews.count, 1, "\(mode): one visible puzzle board")
            XCTAssertEqual(touchViews.count, 3, "\(mode): exactly three touch-accurate tray cards")
            guard let board = boardViews.first, touchViews.count == 3 else {
                window.isHidden = true
                previousKeyWindow?.makeKey()
                continue
            }
            let grid = board.convert(board.bounds, to: window)
            let trayRects = touchViews.map { $0.convert($0.bounds, to: window) }
                .sorted { $0.minX < $1.minX }
            let safeBounds = safe.isEmpty ? window.bounds : safe

            XCTAssertGreaterThanOrEqual(grid.width,
                safeBounds.width * 0.92, "\(mode): playable board wastes horizontal space")
            XCTAssertEqual(grid.width, grid.height, accuracy: epsilon,
                "\(mode): cells may not be stretched")
            assertInside(grid, safeBounds, context: "\(mode) board")
            for (slot, rect) in trayRects.enumerated() {
                assertInside(rect, safeBounds, context: "\(mode) tray slot \(slot)")
                XCTAssertGreaterThan(rect.width, 85, "\(mode): unreadable tray slot")
                XCTAssertGreaterThan(rect.height, 50, "\(mode): touch card collapsed")
                XCTAssertEqual(rect.width, trayRects[0].width, accuracy: epsilon,
                    "\(mode): cards must have the same measured width")
            }
            XCTAssertLessThanOrEqual(trayRects[0].maxX, trayRects[1].minX + epsilon)
            XCTAssertLessThanOrEqual(trayRects[1].maxX, trayRects[2].minX + epsilon)
            XCTAssertLessThan(grid.maxY + 2, trayRects[0].minY,
                "\(mode): board visually overlaps the pieces")

            // Structured values help compare the two real simulator profiles.
            let result: [String: Any] = [
                "mode": mode.rawValue,
                "screenPoints": [bounds.width, bounds.height],
                "screenScale": screen.scale,
                "safeAreaInsets": [
                    window.safeAreaInsets.top, window.safeAreaInsets.left,
                    window.safeAreaInsets.bottom, window.safeAreaInsets.right
                ],
                "safeFrame": [safeBounds.minX, safeBounds.minY,
                              safeBounds.width, safeBounds.height],
                "board": [grid.minX, grid.minY, grid.width, grid.height],
                "tray": trayRects.map { [$0.minX, $0.minY, $0.width, $0.height] }
            ]
            let data = try? JSONSerialization.data(
                withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            if let data, let json = String(data: data, encoding: .utf8) {
                print("BERRY_DEVICE_GEOMETRY\n\(json)")
                let attachment = XCTAttachment(
                    data: data, uniformTypeIdentifier: "public.json")
                attachment.name = "Measured-\(mode.rawValue)-Geometry"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            let screenshot = UIGraphicsImageRenderer(size: bounds.size)
                .image { renderer in
                    host.view.layer.render(in: renderer.cgContext)
                }
            let shot = XCTAttachment(image: screenshot)
            shot.name = "Full-\(mode.rawValue)-Actual-iPhone-SafeArea"
            shot.lifetime = .keepAlways
            add(shot)
            window.isHidden = true
            previousKeyWindow?.makeKey()
        }
    }

    private func assertInside(_ actual: CGRect, _ bounds: CGRect,
                              context: String) {
        XCTAssertGreaterThanOrEqual(actual.minX, bounds.minX - epsilon, context)
        XCTAssertGreaterThanOrEqual(actual.minY, bounds.minY - epsilon, context)
        XCTAssertLessThanOrEqual(actual.maxX, bounds.maxX + epsilon, context)
        XCTAssertLessThanOrEqual(actual.maxY, bounds.maxY + epsilon, context)
    }

    private func restore(_ key: String, _ original: Any?) {
        if let original {
            UserDefaults.standard.set(original, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { descendants($0) }
    }
}
