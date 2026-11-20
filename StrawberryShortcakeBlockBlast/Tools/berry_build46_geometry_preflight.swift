import Foundation

// Compile the *real* production BerryGameplayLayout.swift on Linux.
// Only the SwiftUI-owned mode enum is substituted. This catches board-width
// policy and safe-geometry failures before allocating an iOS simulator.
enum BerryMode: CaseIterable {
    case classic, endless, story, daily, cozy, challenge, superHard
}

@main struct BerryBuild46GeometryPreflight {
    static func main() {
        let ratio = BerryGameplayLayout.boardWidthFraction
        precondition(ratio >= 0.90 && ratio <= 0.93,
                     "Build 4.6 approved board width must remain around 92%")
        let outer = BerryGameplayLayout.boardTouchMargin +
                    BerryGameplayLayout.gardenFrameInset
        precondition(outer == 11, "Board touch margin or exterior Blossom frame changed")

        let screens: [(String, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            ("iPhone 16e", 390, 751, 59, 34),
            ("393pt layout", 393, 759, 59, 34),
            ("compact 320pt", 320, 650, 47, 34),
            ("wide 430pt", 430, 835, 62, 34)
        ]
        var checked = 0
        for (name, width, height, top, bottom) in screens {
            for mode in BerryMode.allCases {
                for mega in [false, true] where !mega || mode == .endless {
                    let normal = BerryGameplayLayout.boardSize(
                        width: width, height: height, topInset: top,
                        bottomInset: bottom, mode: mode, megaGarden: mega)
                    let diagnostic = BerryGameplayLayout.boardSize(
                        width: width, height: height, topInset: top,
                        bottomInset: bottom, mode: mode, megaGarden: mega,
                        touchDiagnostics: true)
                    precondition(normal.isFinite && normal >= 150,
                                 "\(name) \(mode) board collapsed")
                    precondition(normal <= width * ratio + 0.01,
                                 "\(name) \(mode) exceeds approved width fraction")
                    precondition(normal + 2 * outer + 6 <= width + 0.5,
                                 "\(name) \(mode) Blossom frame overflows screen")
                    precondition(normal + 2 * outer <= height - 110,
                                 "\(name) \(mode) lacks room for HUD/tray")
                    precondition(diagnostic <= normal + 0.01,
                                 "\(name) \(mode) touch diagnostic row overflows")
                    checked += 1
                }
            }
        }

        for width: CGFloat in [390, 393, 430] {
            let classic = BerryGameplayLayout.boardSize(
                width: width, height: 759, topInset: 0, bottomInset: 0,
                mode: .classic)
            precondition(classic >= width * 0.89,
                         "Build 4.6 Classic board too small")
            precondition(classic <= width * ratio + 0.01,
                         "Build 4.6 Classic board too wide")
        }
        print("PASS: production Swift BerryGameplayLayout validates \(checked) mode/screen combinations, 16e safe geometry, and exterior-only frame before simulator allocation")
    }
}
