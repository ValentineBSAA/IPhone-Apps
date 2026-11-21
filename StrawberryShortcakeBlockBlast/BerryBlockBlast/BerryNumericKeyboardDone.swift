import SwiftUI

/// iOS number pads have no Return/Done key. Attach in the same
/// NavigationStack as numeric fields, backed by the owning @FocusState.
/// Does not save, submit, or change the bound amount.
struct BerryNumericKeyboardDone: ToolbarContent {
    var onDone: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button {
                onDone()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .tint(BerryStyle.strawberry)
            .accessibilityIdentifier("berry.numeric.keyboard.done")
        }
    }
}
