import SwiftUI

#if BERRY_INTERNAL_QA
/// Developer Garden D1c. One tap runs a real GameSession checkout against a
/// disposable, independent preferences suite and its own actual economy ledger.
/// Only the receipt enters SwiftUI state. No mock balance or saved game mutation.
struct BerryDeveloperCommerceLabPanel: View {
    @State private var lab = BerryDeveloperCommerceLab()
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 12) {
            Text("REAL CHECKOUT • DISPOSABLE TEST WALLET")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.leaf)
                .multilineTextAlignment(.center)

            Text("Tap a scenario to run the game's actual shop methods instantly. These are temporary test berries and items, not your saved purchases or earned rewards.")
                .font(.caption)
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BerryQACommerceScenario.allCases) { choice in
                    Button {
                        lab.prepare(choice)
                        _ = lab.run()
                    } label: {
                        VStack(spacing: 6) {
                            Text(choice.rawValue)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            Text(lab.latest?.scenario == choice
                                 ? (lab.latest?.passed == true ? "PASS" : "FAIL")
                                 : "RUN TEST")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(lab.latest?.scenario == choice && lab.latest?.passed == true
                                                 ? BerryStyle.leaf : BerryStyle.strawberry)
                        }
                        .frame(maxWidth: .infinity, minHeight: 77)
                        .padding(.horizontal, 6)
                        .background(lab.latest?.scenario == choice
                                    ? BerryStyle.softPink : Color.white,
                                    in: RoundedRectangle(cornerRadius: 15))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(BerryStyle.strawberry.opacity(0.4), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Run \(choice.rawValue): \(choice.expected)")
                }
            }

            if let receipt = lab.latest {
                VStack(spacing: 9) {
                    Text(receipt.passed ? "PASS • REAL CHECKOUT TEST" : "FAIL • REVIEW NEEDED")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(receipt.passed ? BerryStyle.leaf : Color.red)
                    Text(receipt.scenario.detail)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Text("Expected: \(receipt.expected)")
                        .font(.caption.bold())
                        .multilineTextAlignment(.center)
                    Text("Actual: \(receipt.actual)")
                        .font(.caption.monospacedDigit())
                        .multilineTextAlignment(.center)
                    Text(receipt.playerDataUnchanged
                         ? "Your real wallet and saved-game keys were unchanged."
                         : "CAUTION: A normal saved key changed. Do not publish.")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(receipt.playerDataUnchanged ? BerryStyle.leaf : Color.red)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .combine)
            } else {
                Text("No test has run yet. Choose any card above.")
                    .font(.caption)
                    .foregroundStyle(BerryStyle.chocolate)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                Button("Run selected again") {
                    _ = lab.run()
                }
                .buttonStyle(.borderedProminent)
                .tint(BerryStyle.leaf)

                Button("Discard & reset") {
                    lab.discard()
                }
                .buttonStyle(.bordered)
                .tint(BerryStyle.strawberry)
            }

            Text("D1c checks actual Cottage, premium and saved-garden purchase handlers. This is not a replacement for physical shop tapping, process-kill durability, Story/Daily testing or the full game release checklist.")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.78))
                .multilineTextAlignment(.center)
        }
        .onDisappear { lab.discard() }
    }
}
#endif
