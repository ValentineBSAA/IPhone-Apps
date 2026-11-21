import SwiftUI

#if BERRY_INTERNAL_QA
/// D0b internal lab. A sheet-local value struct owns all mock currency,
/// charges, save blobs and virtual date. No game session is passed in.
struct BerryDeveloperStateLabPanel: View {
    @State private var lab = BerryDeveloperStateLab()
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 12) {
            Text("SANDBOX ONLY • NO LIVE CURRENCY OR SAVES")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.leaf)
                .multilineTextAlignment(.center)

            Text("Try a wallet, tool charge, save or countdown edge case without spending real strawberries or changing your phone's clock. These tests use real game prices and timer rules, but not live checkout or gameplay saves.")
                .font(.caption)
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BerryQAStateScenario.allCases) { choice in
                    Button {
                        lab.prepare(choice)
                    } label: {
                        VStack(spacing: 6) {
                            Text(choice.rawValue)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                            Text(lab.scenario == choice ? "SELECTED" : "SET UP")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(lab.scenario == choice ?
                                                 BerryStyle.leaf : BerryStyle.strawberry)
                        }
                        .frame(maxWidth: .infinity, minHeight: 74)
                        .padding(.horizontal, 6)
                        .background(lab.scenario == choice ?
                            BerryStyle.softPink : Color.white,
                            in: RoundedRectangle(cornerRadius: 15))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(BerryStyle.strawberry.opacity(0.45), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(lab.scenario.details)
                .font(.caption)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 10) {
                stat("Sandbox berries", "\(lab.wallet.balance) 🍓")
                stat("Sandbox Undo", "\(lab.wallet.chargeCount(for: .undo)) charge(s)")
                stat("Sandbox Shuffle", "\(lab.wallet.chargeCount(for: .shuffle)) charge(s)")
                stat("Sandbox Hint", "\(lab.wallet.chargeCount(for: .hint)) charge(s)")
            }

            Text("Expected: \(lab.scenario.expected)")
                .font(.caption)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 10) {
                Button("Run scenario") {
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

            if let result = lab.latest {
                VStack(spacing: 6) {
                    Text(result.passed ? "PASS • ISOLATED POLICY" : "FAIL • NEEDS INVESTIGATION")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(result.passed ? BerryStyle.leaf : Color.red)
                    Text(result.actual)
                        .font(.caption.monospacedDigit())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .combine)
            }

            Text("D0b verifies sandbox policies only. The production shop, daily saves, purchase cancellations, and rewards need separate adapter-based tests before they can be called tested.")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.77))
                .multilineTextAlignment(.center)
        }
        .onDisappear { lab.discard() }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 55)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
    }
}
#endif
