import SwiftUI

/// Small, non-blocking feedback for tappable cards; honors Reduce Motion.
struct BerryPolishPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .brightness(configuration.isPressed ? 0.035 : 0)
            .shadow(color: BerryStyle.strawberry.opacity(configuration.isPressed ? 0.14 : 0),
                    radius: configuration.isPressed ? 7 : 0, y: 2)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.19),
                       value: configuration.isPressed)
    }
}
