import SwiftUI

/// The copy shown in game-over UI depends only on the rescues that are
/// actually usable. Never advertise a paid action that cannot succeed.
struct BerryRescueAvailability: Equatable {
    let shuffle: Bool
    let golden: Bool
    var hasAny: Bool { shuffle || golden }
}

enum BerryGameOverCopy {
    static let noRescueNotice =
        "No rescue is available for this board. Starting a fresh garden is free."

    static func heading(for availability: BerryRescueAvailability) -> String {
        availability.hasAny ? "KEEP YOUR GARDEN & SCORE" : "PLANT A FRESH GARDEN"
    }

    static func explanation(for availability: BerryRescueAvailability,
                            daily: Bool = false) -> String {
        if daily {
            return "No pieces fit. Today's Daily Harvest attempt is complete. Your score is saved."
        }
        switch (availability.shuffle, availability.golden) {
        case (true, true):
            return "No pieces fit. Shuffle the tray or use a Golden Strawberry to clear the board and keep your score."
        case (true, false):
            return "No pieces fit. A Shuffle can refresh your pieces so you can keep your score."
        case (false, true):
            return "No pieces fit. A Golden Strawberry can clear the board so you can keep your score."
        case (false, false):
            return "No pieces fit. Your score is saved, and a fresh garden is ready whenever you are."
        }
    }
}

/// Separate text and icon to avoid Label's compact single-line layout.
/// Multiline text owns its measured height and never truncates to an ellipsis.
struct BerryNoRescueNotice: View {
    let message: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(BerryStyle.leaf)
                .accessibilityHidden(true)
            Text(message)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.88))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(BerryStyle.cream.opacity(0.90),
                    in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityIdentifier("berry.noRescueNotice")
    }
}

/// Shared scroll-safe wrapper for results/restart/victory overlays.
/// Small screens and large Dynamic Type can scroll; buttons remain reachable.
struct BerryResultScrollContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                content
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .center)
            }
            .scrollIndicators(.hidden)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
