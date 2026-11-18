import SwiftUI
import UIKit
import XCTest
@testable import BerryBlockBlast

@MainActor
final class BerryResultTextReliabilityTests: XCTestCase {
    func testNoMovesCopyOnlyPromisesAvailableRescues() {
        let none = BerryRescueAvailability(shuffle: false, golden: false)
        XCTAssertFalse(none.hasAny)
        XCTAssertEqual(BerryGameOverCopy.heading(for: none), "PLANT A FRESH GARDEN")
        XCTAssertFalse(BerryGameOverCopy.explanation(for: none).contains("Shuffle"))
        XCTAssertFalse(BerryGameOverCopy.explanation(for: none).contains("Golden Strawberry"))
        XCTAssertTrue(BerryGameOverCopy.noRescueNotice.contains("free"))

        let shuffle = BerryRescueAvailability(shuffle: true, golden: false)
        XCTAssertTrue(BerryGameOverCopy.explanation(for: shuffle).contains("Shuffle"))
        XCTAssertFalse(BerryGameOverCopy.explanation(for: shuffle).contains("Golden Strawberry"))

        let golden = BerryRescueAvailability(shuffle: false, golden: true)
        XCTAssertFalse(BerryGameOverCopy.explanation(for: golden).contains("Shuffle"))
        XCTAssertTrue(BerryGameOverCopy.explanation(for: golden).contains("Golden Strawberry"))

        let both = BerryRescueAvailability(shuffle: true, golden: true)
        XCTAssertEqual(BerryGameOverCopy.heading(for: both), "KEEP YOUR GARDEN & SCORE")
        XCTAssertTrue(BerryGameOverCopy.explanation(for: both).contains("Shuffle"))
        XCTAssertTrue(BerryGameOverCopy.explanation(for: both).contains("Golden Strawberry"))
        XCTAssertFalse(BerryGameOverCopy.explanation(for: none, daily: true).contains("Shuffle"))
    }

    func testNoRescueNoticeWrapsInsteadOfClippingAtCompactWidths() {
        for (width, font) in [(CGFloat(260), DynamicTypeSize.large),
                              (CGFloat(300), .accessibility2),
                              (CGFloat(330), .accessibility3)] {
            let view = BerryNoRescueNotice(message: BerryGameOverCopy.noRescueNotice)
                .frame(width: width)
                .environment(\.dynamicTypeSize, font)
            let host = UIHostingController(rootView: view)
            let size = host.sizeThatFits(in: CGSize(width: width, height: 1500))
            XCTAssertLessThanOrEqual(size.width, width + 1, "Notice exceeds width \(width)")
            XCTAssertGreaterThan(size.height, 58, "Notice collapsed into a clipped line at \(width)")
            XCTAssertLessThan(size.height, 260, "Notice unexpectedly overflows at \(width)")
        }
    }

    func testResultsContainerActuallyScrollsWithLongTextAndLargeType() {
        for (label, height) in [("iPhone-14-Pro", CGFloat(759)),
                                ("iPhone-16", CGFloat(759)),
                                ("Compact", CGFloat(620))] {
            let view = BerryResultScrollContainer {
                VStack(spacing: 16) {
                    Text("No More Moves!").font(.largeTitle.bold())
                    Text(String(repeating: "Long results and explanatory copy must remain readable. ",
                                count: 13))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                    BerryNoRescueNotice(message: BerryGameOverCopy.noRescueNotice)
                    Button("Plant a Fresh Garden") {}
                    Button("Return to Strawberry Village") {}
                }
                .padding(24)
                .frame(maxWidth: 360)
                .padding(.horizontal, 22)
                .padding(.vertical, 22)
            }
            .environment(\.dynamicTypeSize, .accessibility2)
            .frame(width: 393, height: height)

            let host = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: height))
            window.rootViewController = host
            window.isHidden = false
            host.view.frame = window.bounds
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
            host.view.layoutIfNeeded()
            let scrolls = descendants(host.view).compactMap { $0 as? UIScrollView }
            guard let scroll = scrolls.first(where: { $0.bounds.height > 300 }) else {
                XCTFail("\(label): results overlay is not scrollable")
                window.isHidden = true
                continue
            }
            XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height + 20,
                                 "\(label): long result text cannot scroll to the actions")
            let screenshot = UIGraphicsImageRenderer(size: window.bounds.size)
                .image { host.view.layer.render(in: $0.cgContext) }
            let attachment = XCTAttachment(image: screenshot)
            attachment.name = "Result-Text-Reflow-\(label)"
            attachment.lifetime = .keepAlways
            add(attachment)
            window.isHidden = true
        }
    }

    private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { descendants($0) }
    }
}
