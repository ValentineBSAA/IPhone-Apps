import UIKit
import SwiftUI
import XCTest
@testable import BerryBlockBlast

/// Integration test: render the ENTIRE game, not an isolated piece.
/// The UIKit tracking views are the same hit-target views used by real
/// devices, so their rectangles must line up with the visible board/tray.
@MainActor
final class BerryFullScreenGameplayTests: XCTestCase {
    func testCompleteClassicLayoutAndRealTouchFramesOnBothPhones() {
        let originalWelcome = UserDefaults.standard.object(forKey: "berryblockblast.welcomed.v3")
        UserDefaults.standard.set(true, forKey: "berryblockblast.welcomed.v3")
        defer {
            if let originalWelcome {
                UserDefaults.standard.set(originalWelcome, forKey: "berryblockblast.welcomed.v3")
            } else {
                UserDefaults.standard.removeObject(forKey: "berryblockblast.welcomed.v3")
            }
        }
        // iPhone 14 Pro and iPhone 16 share 393x852pt hardware
        // coordinates. Compare the safe-area height after the 59pt
        // Dynamic Island/status and 34pt home-indicator reserves.
        // Render EVERY game mode, not just Classic.
        for mode in BerryMode.allCases {
        for (label, width, height) in [
            ("iPhone-14-Pro", CGFloat(393), CGFloat(759)),
            ("iPhone-16", CGFloat(393), CGFloat(759))
        ] {
            let view = BerryGameView(mode: mode, onExit: {})
                .frame(width: width, height: height)
            let host = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
            window.rootViewController = host
            window.isHidden = false
            host.view.frame = window.bounds
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.12))
            host.view.layoutIfNeeded()

            let children = allDescendants(host.view)
            let boards = children.compactMap { $0 as? BerryBoardWindowTrackingView }
            let trays = children.compactMap { $0 as? BerryTouchTrackingView }
            XCTAssertFalse(boards.isEmpty, "\(label): live board view not found")
            XCTAssertEqual(trays.count, 3, "\(label): must have 3 actual touch targets")
            if let board = boards.first {
                let rect = board.convert(board.bounds, to: window)
                XCTAssertGreaterThan(rect.width, 350,
                    "\(label): game board is too small inside available width")
                XCTAssertGreaterThan(rect.height, 350,
                    "\(label): game board is too small inside available height")
                XCTAssertGreaterThanOrEqual(rect.minX, 0)
                XCTAssertLessThanOrEqual(rect.maxX, width + 1)
                XCTAssertGreaterThanOrEqual(rect.minY, 0)
                XCTAssertLessThanOrEqual(rect.maxY, height + 1)
            }

            let frames = trays.map { $0.convert($0.bounds, to: window) }
                .sorted { $0.midX < $1.midX }
            if frames.count == 3 {
                for frame in frames {
                    XCTAssertGreaterThan(frame.width, 80, "\(label): squeezed touch target")
                    XCTAssertGreaterThan(frame.height, 50, "\(label): squeezed touch height")
                    XCTAssertGreaterThanOrEqual(frame.minX, 0)
                    XCTAssertLessThanOrEqual(frame.maxX, width + 1)
                    XCTAssertGreaterThanOrEqual(frame.minY, 0)
                    XCTAssertLessThanOrEqual(frame.maxY, height + 1)
                }
                XCTAssertLessThanOrEqual(frames[0].maxX, frames[1].minX + 1)
                XCTAssertLessThanOrEqual(frames[1].maxX, frames[2].minX + 1)
                if let board = boards.first {
                    let boardRect = board.convert(board.bounds, to: window)
                    XCTAssertLessThan(boardRect.maxY, frames[0].minY,
                        "\(label): board overlaps tray")
                }
            }

            // Keep the screenshot in CI so designers can inspect the actual
            // board placement and surrounding whitespace before release.
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { renderer in
                host.view.layer.render(in: renderer.cgContext)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "Full-Game-\(label)-\(mode.id)-393pt"
            attachment.lifetime = .keepAlways
            add(attachment)
            window.isHidden = true
        }
        }
    }

    private func allDescendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { allDescendants($0) }
    }
}
