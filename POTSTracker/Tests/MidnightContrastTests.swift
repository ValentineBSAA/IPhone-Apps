import XCTest
import SwiftUI
import UIKit
@testable import POTSTracker

final class MidnightContrastTests: XCTestCase {
    private let dark = UITraitCollection(userInterfaceStyle: .dark)
    private let light = UITraitCollection(userInterfaceStyle: .light)

    private func components(_ color: UIColor, traits: UITraitCollection) -> (Double, Double, Double) {
        let resolved = color.resolvedColor(with: traits)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        XCTAssertTrue(resolved.getRed(&r, green: &g, blue: &b, alpha: &a))
        return (Double(r), Double(g), Double(b))
    }
    private func luminance(_ color: UIColor, traits: UITraitCollection) -> Double {
        let (r,g,b) = components(color, traits: traits)
        func linear(_ x: Double) -> Double {
            x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }
    private func contrast(_ one: UIColor, _ two: UIColor, traits: UITraitCollection) -> Double {
        let a = luminance(one, traits: traits)
        let b = luminance(two, traits: traits)
        return (max(a,b)+0.05)/(min(a,b)+0.05)
    }
    func testMutedTextAcrossAllMidnightSurfaces() {
        let secondary = UIColor(Color.potsSecondary)
        let tertiary = UIColor(Color.potsTertiary)
        let backgrounds = [UIColor(Color.potsBackground),
                           UIColor(Color.potsSurface),
                           UIColor(Color.potsSurfaceMuted)]
        for bg in backgrounds {
            XCTAssertGreaterThanOrEqual(contrast(secondary, bg, traits: dark), 4.5)
            XCTAssertGreaterThanOrEqual(contrast(tertiary, bg, traits: dark), 4.5)
        }
    }
    func testMidnightRoseAccentAndReadableButtonLabels() {
        XCTAssertGreaterThanOrEqual(contrast(
            UIColor(Color.potsTeal), UIColor(Color.potsSurfaceMuted), traits: dark), 4.5)
        XCTAssertGreaterThanOrEqual(contrast(
            UIColor.white, UIColor(Color.potsButtonFill), traits: dark), 4.5)
    }
    func testRaisedCardsAndUnchangedStrawberryBlossomLightBase() {
        XCTAssertGreaterThanOrEqual(contrast(
            UIColor(Color.potsBackground), UIColor(Color.potsSurface), traits: dark), 1.3)
        let bg=components(UIColor(Color.potsBackground), traits: light)
        XCTAssertEqual(bg.0, 1.00, accuracy: 0.02)
        XCTAssertEqual(bg.1, 0.970, accuracy: 0.02)
        XCTAssertEqual(bg.2, 0.980, accuracy: 0.02)
    }
}
