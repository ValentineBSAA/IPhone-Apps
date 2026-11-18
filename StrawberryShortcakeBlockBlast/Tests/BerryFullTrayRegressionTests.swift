import SwiftUI
import UIKit
import XCTest
@testable import BerryBlockBlast

/// Guard the complete interactive three-slot tray, not only isolated pieces.
@MainActor
final class BerryFullTrayRegressionTests: XCTestCase {
    private func piece(_ cells: [BerryPoint], tint: Int) -> BerryPiece {
        BerryPiece(points: cells, tint: tint)
    }

    private let variants: [[BerryPoint]] = [
        [.init(row: 0, col: 0)],
        (0..<3).map { BerryPoint(row: 0, col: $0) },
        (0..<5).map { BerryPoint(row: 0, col: $0) },
        (0..<7).map { BerryPoint(row: 0, col: $0) },
        (0..<9).map { BerryPoint(row: 0, col: $0) },
        (0..<9).map { BerryPoint(row: $0, col: 0) },
        (0..<3).flatMap { r in (0..<3).map { c in BerryPoint(row: r, col: c) } },
        [.init(row: 0, col: 0), .init(row: 1, col: 0),
         .init(row: 2, col: 0), .init(row: 2, col: 1)]
    ]

    func testMysteryGardenNeverMakesCarriedPieceInvisible() {
        for style in ["mystery", "ghost", "outline", "", "unknown"] {
            XCTAssertTrue(BerryGameplayLayout.showsCarriedPiece(
                previewStyle: style, dragging: true, fingerKnown: true), style)
            XCTAssertFalse(BerryGameplayLayout.showsCarriedPiece(
                previewStyle: style, dragging: false, fingerKnown: true), style)
            XCTAssertFalse(BerryGameplayLayout.showsCarriedPiece(
                previewStyle: style, dragging: true, fingerKnown: false), style)
        }
    }

    func testFixedTrayCardsNeverOverlapOrClimbOutOfViewport() {
        for width: CGFloat in [320, 375, 393, 430] {
            for cardHeight: CGFloat in [58, 65] {
                let available = width - 10
                let slot = BerryThreePieceTray.slotWidth(for: available)
                XCTAssertEqual(slot * 3 + BerryThreePieceTray.spacing * 2,
                               available, accuracy: 0.01)
                for shape in variants {
                    let p = piece(shape, tint: 0)
                    let unit = BerryThreePieceTray.tileUnit(
                        piece: p, slotWidth: slot, slotHeight: cardHeight)
                    XCTAssertGreaterThanOrEqual(unit, 3)
                    XCTAssertLessThanOrEqual(CGFloat(p.width) * unit,
                                             slot - 12 + 0.01, "Horizontal overflow")
                    XCTAssertLessThanOrEqual(CGFloat(p.height) * unit,
                                             cardHeight - 8 + 0.01, "Vertical overflow")
                }
            }
        }
    }

    func testFullThreeCardTrayDrawsAllLivePiecesAndUsedMarker() {
        // Two real phone widths plus small/large regression boundaries.
        for width: CGFloat in [320, 375, 393, 430] {
            for cardHeight: CGFloat in [58, 65] {
                for variant in [0, 2, 4, 5, 6] {
                    let colors = [0, 3, 5]
                    let three = (0..<3).map { i in
                        piece(variants[(variant + i) % variants.count], tint: colors[i])
                    }
                    let image = render(
                        pieces: three, width: width - 10, height: cardHeight)
                    for slot in 0..<3 {
                        let count = coloredPixelsNearCenter(
                            image, slot: slot, cardWidth:
                                BerryThreePieceTray.slotWidth(for: width - 10),
                            cardHeight: cardHeight)
                        XCTAssertGreaterThan(count, 5,
                            "Rendered slot \(slot) was blank at \(width)pt, \(cardHeight)pt, variant \(variant)")
                    }
                    if width == 393 && cardHeight == 65 && variant == 2 {
                        let capture = XCTAttachment(image: image)
                        capture.name = "Complete-iPhone-three-piece-tray"
                        capture.lifetime = .keepAlways
                        add(capture)
                    }
                }
                // Refilling or placing any one piece must not affect the two
                // remaining live pieces or their 1/3-width touch cards.
                let used = render(
                    pieces: [piece(variants[3], tint: 0), nil,
                             piece(variants[5], tint: 5)],
                    width: width - 10, height: cardHeight)
                XCTAssertGreaterThan(
                    coloredPixelsNearCenter(used, slot: 0,
                        cardWidth: BerryThreePieceTray.slotWidth(for: width - 10),
                        cardHeight: cardHeight), 5)
                XCTAssertGreaterThan(
                    coloredPixelsNearCenter(used, slot: 2,
                        cardWidth: BerryThreePieceTray.slotWidth(for: width - 10),
                        cardHeight: cardHeight), 5)
            }
        }
    }

    private func render(pieces: [BerryPiece?], width: CGFloat, height: CGFloat) -> UIImage {
        let root = BerryThreePieceTray(
            pieces: pieces, availableWidth: width, height: height,
            selectedSlot: nil, draggingSlot: nil, mode: .classic,
            strawberryUnlocked: false, canMakeMove: true,
            onTouch: { _, _ in }, onAccessibilitySelect: { _ in }
        ).frame(width: width, height: height)
         .background(Color.white)
        let host = UIHostingController(rootView: root)
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        host.view.backgroundColor = .white
        let window = UIWindow(frame: host.view.frame)
        window.rootViewController = host
        window.isHidden = false
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        // Render synchronously: no waiting for a future offscreen refresh.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.015))
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
            .image { ctx in host.view.layer.render(in: ctx.cgContext) }
        window.isHidden = true
        return image
    }

    private func coloredPixelsNearCenter(
        _ image: UIImage, slot: Int, cardWidth: CGFloat,
        cardHeight: CGFloat) -> Int {
        guard let cg = image.cgImage else { return 0 }
        let w = cg.width, h = cg.height
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        let ok = bytes.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(
                data: raw.baseAddress, width: w, height: h,
                bitsPerComponent: 8, bytesPerRow: w * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard ok else { return 0 }
        let scale = CGFloat(w) / image.size.width
        let start = CGFloat(slot) * (cardWidth + BerryThreePieceTray.spacing)
        let x0 = max(0, Int((start + cardWidth * 0.25) * scale))
        let x1 = min(w, Int((start + cardWidth * 0.75) * scale))
        let y0 = max(0, Int(cardHeight * 0.25 * scale))
        let y1 = min(h, Int(cardHeight * 0.75 * scale))
        var count = 0
        for y in y0..<y1 {
            for x in x0..<x1 {
                let at = (y * w + x) * 4
                let r = Int(bytes[at]), g = Int(bytes[at+1]), b = Int(bytes[at+2])
                if max(r,g,b) - min(r,g,b) > 43 && min(r,g,b) < 215 {
                    count += 1
                }
            }
        }
        return count
    }
}
