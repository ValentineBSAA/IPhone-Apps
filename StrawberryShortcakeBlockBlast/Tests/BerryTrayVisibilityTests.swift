import SwiftUI
import UIKit
import XCTest
@testable import BerryBlockBlast

@MainActor
final class BerryTrayVisibilityTests: XCTestCase {
    /// A regression guard: an available piece must occupy real, colored
    /// pixels. It is not enough to be present in the engine or tappable.
    func testEveryColorAndPieceShapeRendersPixelsInTray() {
        let shapes: [[BerryPoint]] = [
            [.init(row: 0, col: 0)],
            (0..<3).map { .init(row: 0, col: $0) },
            (0..<4).map { .init(row: $0, col: 0) },
            [.init(row: 0, col: 0), .init(row: 1, col: 0),
             .init(row: 1, col: 1), .init(row: 1, col: 2)],
            (0..<3).flatMap { row in (0..<3).map { col in BerryPoint(row: row, col: col) } },
            (0..<5).map { .init(row: 0, col: $0) }
        ]
        for tint in 0..<6 {
            for (shapeIndex, cells) in shapes.enumerated() {
                let piece = BerryPiece(points: cells, tint: tint)
                XCTAssertFalse(piece.points.isEmpty)
                XCTAssertGreaterThan(piece.width, 0)
                XCTAssertGreaterThan(piece.height, 0)
                let tileUnit: CGFloat = 17
                let size = CGSize(width: CGFloat(piece.width) * tileUnit + 12,
                                  height: CGFloat(piece.height) * tileUnit + 12)
                let image = renderedImage(piece: piece, tileUnit: tileUnit, size: size)
                let visible = nonWhitePixels(image)
                XCTAssertGreaterThan(visible, 20,
                                     "Invisible tray glyph: tint \(tint), shape \(shapeIndex), count \(cells.count)")
                if tint == 0 && shapeIndex == 3 {
                    let shot = XCTAttachment(image: image)
                    shot.name = "Four-square-tray-shape-with-canvas-safety-net"
                    shot.lifetime = .keepAlways
                    add(shot)
                }
            }
        }
    }

    func testSeededEngineAlwaysDealsThreeNonEmptyRenderablePieces() {
        for seed in 1...120 {
            let game = BerryEngine(seed: UInt64(seed))
            XCTAssertEqual(game.tray.count, 3)
            for piece in game.tray {
                guard let piece else {
                    XCTFail("Seed \(seed) generated a missing starting piece")
                    continue
                }
                XCTAssertFalse(piece.points.isEmpty)
                XCTAssertTrue(piece.points.allSatisfy { $0.row >= 0 && $0.col >= 0 })
                XCTAssertGreaterThan(piece.width, 0)
                XCTAssertGreaterThan(piece.height, 0)
            }
        }
    }

    private func renderedImage(piece: BerryPiece, tileUnit: CGFloat, size: CGSize) -> UIImage {
        let root = BerryPieceGlyph(piece: piece, unit: tileUnit,
                                  mode: .classic, strawberryUnlocked: false)
            .padding(6)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .background(Color.white)
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .white
        host.view.frame = CGRect(origin: .zero, size: size)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.isHidden = false
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.045))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        // Do not ask a detached simulator window to wait for a future
        // screen refresh: on CI that can hang indefinitely. Render the
        // already laid-out hierarchy synchronously instead.
        let image = UIGraphicsImageRenderer(size: size, format: format).image { output in
            host.view.layer.render(in: output.cgContext)
        }
        window.isHidden = true
        return image
    }

    private func nonWhitePixels(_ image: UIImage) -> Int {
        guard let cg = image.cgImage else { return 0 }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let painted = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let ctx = CGContext(data: bytes.baseAddress, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return false
            }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard painted else { return 0 }
        var total = 0
        for pixel in stride(from: 0, to: pixels.count, by: 4) {
            let r = Int(pixels[pixel]), g = Int(pixels[pixel + 1]), b = Int(pixels[pixel + 2])
            if min(r, g, b) < 205 { total += 1 }
        }
        return total
    }
}
