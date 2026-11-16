import SwiftUI

struct BerrySchoolView: View {
    let onFinish: () -> Void
    @State private var lesson = 0
    @State private var placed = false
    private let lessons: [(String, String, String)] = [
        ("🍓 Welcome to Strawberry School", "Pick up a piece, then drag it to the garden. You can also tap a piece and tap the board.", "Tap the glowing strawberry to practice."),
        ("🌸 Clear a Row", "Complete all eight squares in a row or column. The full line disappears and makes space for more blocks.", "Every line earns 3 strawberries."),
        ("🍰 Make Sweet Combos", "Clear multiple lines or keep clearing on consecutive turns to increase your rewards.", "Combos grow your berry basket."),
        ("🧺 Visit the Market", "Use your strawberries to buy extra Undo and Shuffle helpers. They are earned through gameplay, never purchased with money.", "You can see rewards in the shop ledger."),
        ("🎀 You're Ready!", "Explore Sweet Endless, Berry Story, Daily Harvest and the More Adventures page. Your progress saves automatically.", "Graduate to collect 25 strawberries!")
    ]
    var body: some View {
        VStack(spacing: 18) {
            HStack { Text("🍓 STRAWBERRY SCHOOL").font(.caption.bold()); Spacer(); Text("\(lesson + 1) / 5").font(.caption.bold()) }
                .foregroundStyle(BerryStyle.leaf)
            Spacer()
            Text(lessons[lesson].0).font(.system(size: 27, weight: .black, design: .rounded)).foregroundStyle(BerryStyle.strawberry).multilineTextAlignment(.center)
            Text(lessons[lesson].1).font(.system(size: 17, weight: .medium, design: .rounded)).foregroundStyle(BerryStyle.chocolate).multilineTextAlignment(.center)
            if lesson == 0 {
                HStack(spacing: 5) {
                    ForEach(0..<8, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 7).fill(index == 7 ? (placed ? BerryStyle.strawberry : Color.white) : BerryStyle.strawberry.opacity(0.7))
                            .frame(height: 35)
                            .overlay { if index == 7 && !placed { Text("🍓").font(.caption) } }
                    }
                }.onTapGesture { placed = true }
            } else {
                Text(["", "🍓 +3 per line", "🍓 More lines = more rewards", "🧺 Undo • Shuffle", "🍓 +25 graduation gift"][lesson])
                    .font(.title3.bold()).foregroundStyle(BerryStyle.strawberry)
            }
            Text(lessons[lesson].2).font(.subheadline).foregroundStyle(BerryStyle.chocolate.opacity(0.7)).multilineTextAlignment(.center)
            Spacer()
            Button(lesson == 4 ? "Graduate! 🍓" : "Next Lesson") {
                if lesson < 4 { lesson += 1 } else { onFinish() }
            }.buttonStyle(.borderedProminent).tint(BerryStyle.strawberry).controlSize(.large)
            Button("Skip School") { onFinish() }.foregroundStyle(BerryStyle.chocolate)
        }
        .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [BerryStyle.cream, Color(red: 1, green: 0.82, blue: 0.88)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}
