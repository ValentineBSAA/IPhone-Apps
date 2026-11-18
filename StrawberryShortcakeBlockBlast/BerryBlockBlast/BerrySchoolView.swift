import SwiftUI

/// Five illustrated, offline teaching cards. The mini practice row is visual
/// and independent from saved gameplay, wallet and tutorial rewards.
struct BerrySchoolView: View {
    let onFinish: (Bool) -> Void
    @State private var lesson = 0
    @State private var practiceFilled = false
    private let lessons: [(title: String, explanation: String, tip: String, art: String)] = [
        ("🍓 Welcome to Strawberry School",
         "Drag a block onto an EMPTY square. You can also tap a block, then tap its destination.",
         "Tap the empty square in the practice row to plant your first block.",
         "StrawberrySchool"),
        ("🌸 Complete a Row",
         "Fill all eight squares in any horizontal row or vertical column. A complete line clears and makes room for new shapes.",
         "Try completing the last square to see the row clear.",
         "HarvestReward"),
        ("🍰 Plan Sweet Combos",
         "Clearing multiple lines or clearing on consecutive turns grows your score and earned strawberries.",
         "Try to save space for your next three pieces.",
         "Milestone"),
        ("🧺 Shop, Save & Decorate",
         "Your strawberries buy optional helpers and cosmetics. Original square blocks and the original board are always available for free.",
         "Undo and Shuffle help in supported modes; the Golden Strawberry is one emergency continue per run.",
         "ShopBasket"),
        ("🎀 Your First Harvest",
         "Sweet Endless saves each garden size. Daily Harvest gives one attempt a day, win or lose; leaving early saves your unfinished attempt.",
         "Graduation gives its one-time strawberry reward. Now grow something lovely!",
         "Champion")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                HStack {
                    Text("🍓 STRAWBERRY SCHOOL")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.strawberry)
                    Spacer()
                    BerryCandyNumber(value: "\(lesson + 1) / 5", size: 18,
                                     label: "Lesson")
                }
                BerryIcon(name: lessons[lesson].art, size: 104)
                    .frame(height: 108)
                Text(lessons[lesson].title)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                    .multilineTextAlignment(.center)
                Text(lessons[lesson].explanation)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if lesson <= 2 {
                    VStack(spacing: 10) {
                        Text(lesson == 2 ? "COMBO PREVIEW" : "TAP THE EMPTY GRID SQUARE")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                        HStack(spacing: 3) {
                            ForEach(0..<8, id: \.self) { index in
                                Button {
                                    if index == 7 && lesson < 2 { practiceFilled = true }
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.white.opacity(0.76))
                                            .overlay(RoundedRectangle(cornerRadius: 5)
                                                .strokeBorder(.white.opacity(0.58), lineWidth: 1))
                                        if lesson == 2 || (lesson == 0 && (index < 7 || practiceFilled)) ||
                                           (lesson == 1 && index < 7 && !practiceFilled) {
                                            BerryTile(tint: index % 6, mode: .classic,
                                                     strawberryUnlocked: false,
                                                     skinOverride: "default")
                                        } else if index == 7 && !practiceFilled {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundStyle(BerryStyle.strawberry)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                }
                                .buttonStyle(.plain)
                                .disabled(index != 7 || lesson == 2 || practiceFilled)
                                .accessibilityLabel(index == 7 ? "Place practice block" :
                                                    "Occupied sample square")
                            }
                        }
                        if practiceFilled && lesson == 1 {
                            Text("✨ Line cleared! The row is empty again.")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(BerryStyle.leaf)
                        } else if practiceFilled && lesson == 0 {
                            Text("✓ Your block fits into the square!")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(BerryStyle.leaf)
                        } else if lesson == 2 {
                            BerryCandyNumber(value: "COMBO ×2", size: 25, label: "Combo example")
                        }
                    }
                    .padding(12)
                    .background(BerryStyle.softPink, in: RoundedRectangle(cornerRadius: 18))
                } else if lesson == 3 {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        BerryGridInfoTile(title: "Shuffle", detail: "Fresh playable pieces",
                                         art: "ShuffleIcon", value: "🍓 50")
                        BerryGridInfoTile(title: "Golden Strawberry", detail: "One continue per run",
                                         art: "GoldenStrawberry", value: "🍓 250")
                    }
                } else {
                    BerryCandyNumber(value: "🍓 25", size: 32, label: "One-time graduation gift")
                }
                Text(lessons[lesson].tip)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.78))
                    .multilineTextAlignment(.center)
                Button(lesson == 4 ? "Graduate! 🍓" : "Next Lesson") {
                    if lesson < 4 {
                        lesson += 1
                        practiceFilled = false
                    } else {
                        onFinish(true)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(BerryStyle.strawberry)
                .controlSize(.large)
                Button("Skip School") { onFinish(false) }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
            }
            .frame(maxWidth: 510)
            .padding(22)
            .frame(maxWidth: .infinity)
        }
        .background(LinearGradient(colors: [
            BerryStyle.cream, Color(red: 1, green: 0.82, blue: 0.88)
        ], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}
