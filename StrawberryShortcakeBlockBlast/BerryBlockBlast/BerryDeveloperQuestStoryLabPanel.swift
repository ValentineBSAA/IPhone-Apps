import SwiftUI

#if BERRY_INTERNAL_QA
/// Developer-only one-tap real quest/Story/Village tests. No owner data writes.
struct BerryDeveloperQuestStoryLabPanel: View {
    @State private var lab = BerryDeveloperQuestStoryLab()
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 12) {
            Text("REAL QUESTS & STORY • TEMPORARY GARDENS")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.leaf)
                .multilineTextAlignment(.center)

            Text("Run a complete quest or Story progression check with one tap. These tests use temporary strawberries, a pretend calendar date and separate saved data. Your actual story, quests and wallet are not used.")
                .font(.caption)
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BerryQAQuestStoryScenario.allCases) { choice in
                    Button {
                        lab.prepare(choice)
                        _ = lab.run()
                    } label: {
                        VStack(spacing: 7) {
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
                        .frame(maxWidth: .infinity, minHeight: 78)
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

            if let result = lab.latest {
                VStack(spacing: 9) {
                    Text(result.passed ? "PASS • REAL QUEST & STORY RULES" :
                         "FAIL • INVESTIGATE")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(result.passed ? BerryStyle.leaf : Color.red)
                    Text(result.scenario.explanation)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Text("Expected: \(result.expected)")
                        .font(.caption.bold())
                        .multilineTextAlignment(.center)
                    Text("Actual: \(result.actual)")
                        .font(.caption.monospacedDigit())
                        .multilineTextAlignment(.center)
                    Text(result.playerDataUnchanged
                         ? "Your real quest progress, berry wallet and saved games were unchanged."
                         : "CAUTION: Real player data changed. Do not release.")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(result.playerDataUnchanged
                                         ? BerryStyle.leaf : Color.red)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityElement(children: .combine)
            } else {
                Text("Select a two-column card to run its complete isolated scenario.")
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
                .disabled(lab.latest == nil)

                Button("Discard & reset") {
                    lab.reset()
                }
                .buttonStyle(.bordered)
                .tint(BerryStyle.strawberry)
            }

            Text("Internal QA calls real progression and purchase handlers against disposable local state. It does not perform native Story or quest-button taps, edit your phone clock, or prove crash-proof payments.")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.78))
                .multilineTextAlignment(.center)
        }
        .onDisappear { lab.reset() }
    }
}
#endif
