import SwiftUI

/// Full-width, responsive horizontal swipe for card-based layouts.
/// Unlike List.swipeActions, this works in grids/scroll views without
/// converting the user's preferred card UI into a List.
///
/// Drag from anywhere on the card. A short swipe reveals a named action;
/// a decisive swipe opens that action directly. Destructive actions only
/// request a confirmation from a stable parent, never delete on swipe.
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

            Button {
                if restingOffset != 0 {
                    close()
                } else {
                    onTap()
                }
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
            DragGesture(minimumDistance: 12, coordinateSpace: .local)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > 8, abs(dx) > abs(dy) * 1.12 else { return }
                    draggingOffset = dx
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    defer { draggingOffset = 0 }
                    guard abs(dx) > 22, abs(dx) > abs(dy) * 1.12 else { return }

                    // One decisive flick invokes the action, no holding,
                    // second swipe or precision starting point required.
                    if dx > 135 {
                        restingOffset = 0
                        onLeading()
                    } else if dx < -135 {
                        restingOffset = 0
                        onTrailing()
                    } else {
                        let target = restingOffset + dx
                        withAnimation(.easeOut(duration: 0.17)) {
                            restingOffset = target > 43 ? actionWidth : (target < -43 ? -actionWidth : 0)
                        }
                    }
                }
        )
        .contextMenu {
            Button {
                close()
                onLeading()
            } label: { Label(leadingTitle, systemImage: leadingSymbol) }
            Button(role: .destructive) {
                close()
                onTrailing()
            } label: { Label(trailingTitle, systemImage: "trash") }
        }
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
        withAnimation(.easeOut(duration: 0.16)) { restingOffset = 0 }
    }
}
