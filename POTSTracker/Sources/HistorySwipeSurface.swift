import SwiftUI

/// Full-width, responsive horizontal swipe for card-based layouts.
/// Unlike List.swipeActions, this works in grids/scroll views without
/// converting the user's preferred card UI into a List.
///
/// A deliberate swipe reveals a labeled action and leaves it visible until tapped.
/// Ordinary taps open the card directly and never flash the action rail.
/// No long-press gesture and no irreversible full-swipe deletion.
struct HistorySwipeSurface<Content: View>: View {
    let leadingTitle: String
    let leadingSymbol: String
    let trailingTitle: String
    let accessibilityTitle: String
    let onTap: () -> Void
    let onLeading: () -> Void
    let onTrailing: () -> Void
    let content: Content

    @State private var restingOffset: CGFloat = 0
    @State private var draggingOffset: CGFloat = 0

    private let actionWidth: CGFloat = 88
    private let settleDuration: Double = 0.34

    init(
        leadingTitle: String,
        leadingSymbol: String,
        trailingTitle: String,
        accessibilityTitle: String,
        onTap: @escaping () -> Void,
        onLeading: @escaping () -> Void,
        onTrailing: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.leadingTitle = leadingTitle
        self.leadingSymbol = leadingSymbol
        self.trailingTitle = trailingTitle
        self.accessibilityTitle = accessibilityTitle
        self.onTap = onTap
        self.onLeading = onLeading
        self.onTrailing = onTrailing
        self.content = content()
    }

    private var activeOffset: CGFloat {
        min(max(restingOffset + draggingOffset, -actionWidth), actionWidth)
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                actionButton(
                    title: leadingTitle,
                    symbol: leadingSymbol,
                    color: Color.potsTeal,
                    width: actionWidth
                ) {
                    close()
                    onLeading()
                }
                Spacer(minLength: 0)
                actionButton(
                    title: trailingTitle,
                    symbol: "trash",
                    color: Color.red,
                    width: actionWidth
                ) {
                    close()
                    onTrailing()
                }
            }
            .opacity(abs(activeOffset) > 6 ? 1 : 0)
            .allowsHitTesting(abs(activeOffset) > 6)

            Button {
                close()
                onTap()
            } label: {
                content
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .offset(x: activeOffset)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 23, coordinateSpace: .local)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > 12, abs(dx) > abs(dy) * 1.35 else { return }
                    draggingOffset = dx
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > 30, abs(dx) > abs(dy) * 1.35 else {
                        withAnimation(.easeInOut(duration: settleDuration)) {
                            draggingOffset = 0
                        }
                        return
                    }
                    let target = restingOffset + dx
                    withAnimation(.easeInOut(duration: settleDuration)) {
                        restingOffset = target > 46 ? actionWidth : (target < -46 ? -actionWidth : 0)
                        draggingOffset = 0
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint("Swipe right for \(leadingTitle), left for \(trailingTitle).")
        .accessibilityAction(named: Text(leadingTitle)) { onLeading() }
        .accessibilityAction(named: Text(trailingTitle)) { onTrailing() }
    }

    private func actionButton(title: String, symbol: String, color: Color,
                              width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.white)
            .frame(width: width)
            .frame(minHeight: 64)
            .background(color, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    private func close() {
        draggingOffset = 0
        withAnimation(.easeInOut(duration: settleDuration)) { restingOffset = 0 }
    }
}
