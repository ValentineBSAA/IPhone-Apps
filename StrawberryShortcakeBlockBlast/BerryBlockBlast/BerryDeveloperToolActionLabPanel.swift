import SwiftUI

#if BERRY_INTERNAL_QA
/// One-tap actual tool-use QA with no change to player saves or inventory.
struct BerryDeveloperToolActionLabPanel: View {
    @State private var lab = BerryDeveloperToolActionLab()
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 12) {
            Text("REAL TOOLS • ISOLATED SAVE TESTS")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.leaf)
                .multilineTextAlignment(.center)

            Text("Tap a card to run an actual premium tool on a temporary garden, reopen that test save, and see the result. Your own strawberries, tool charges and saved gardens are not used.")
                .font(.caption)
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BerryQAToolActionScenario.allCases) { choice in
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
                                .foregroundStyle(lab.latest?.scenario == choice &&
                                                 lab.latest?.passed == true
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
                    Text(receipt.passed ? "PASS • REAL TOOL AND SAVE" : "FAIL • INVESTIGATE")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(receipt.passed ? BerryStyle.leaf : Color.red)
                    Text(receipt.scenario.explanation)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Text("Expected: \(receipt.expected)")
                        .font(.caption.bold())
                        .multilineTextAlignment(.center)
                    Text("Actual: \(receipt.actual)")
                        .font(.caption.monospacedDigit())
                        .multilineTextAlignment(.center)
                    Text(receipt.realPlayerDataUnchanged
                         ? "Your actual wallet and saved-game keys were unchanged."
                         : "CAUTION: A normal player key changed. Do not release.")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(receipt.realPlayerDataUnchanged ? BerryStyle.leaf : Color.red)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .combine)
            } else {
                Text("Select a scenario to test a real tool and restore its temporary save.")
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

            Text("This Developer Garden lab directly calls real game logic against temporary test saves. It does not tap through the normal gameplay UI or prove crash-proof multi-key saves, seasonal features, or Night Market completion.")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.78))
                .multilineTextAlignment(.center)
        }
        .onDisappear { lab.discard() }
    }
}
#endif
