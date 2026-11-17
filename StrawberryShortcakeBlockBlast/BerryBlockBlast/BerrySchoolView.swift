import SwiftUI

struct BerrySchoolView: View {
    let onFinish: (Bool) -> Void
    @State private var lesson = 0
    @State private var placed = false
    private let lessons: [(String, String, String)] = [
        ("🍓 Welcome to Strawberry School", "Pick up a piece, then drag it to the garden. You can also tap a piece and tap the board.", "Tap the glowing strawberry to practice."),
        ("🌸 Clear a Row", "Complete all eight squares in a row or column. The full line disappears and makes space for more blocks.", "Every line earns 3 strawberries."),
        ("🍰 Make Sweet Combos", "Clear multiple lines or keep clearing on consecutive turns to increase your rewards.", "Combos grow your berry basket."),
        ("🧺 Berry Boutique & Inventory", "Earn berries by clearing lines. Buy helpers, block skins, board frames, and cottage decorations in the Boutique. Manage owned cosmetics in Berry Collection's Inventory.", "Use Undo and Shuffle from the game toolbar in supported modes."),
        ("🎀 You're Ready!", "Sweet Endless saves the current board and opens new seasons. Other modes keep records and rewards, but start fresh boards. Daily Harvest has a calendar and daily rewards.", "Graduate to collect 25 strawberries!")
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
                if lesson < 4 { lesson += 1 } else { onFinish(true) }
            }.buttonStyle(.borderedProminent).tint(BerryStyle.strawberry).controlSize(.large)
            Button("Skip School") { onFinish(false) }.foregroundStyle(BerryStyle.chocolate)
        }
        .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [BerryStyle.cream, Color(red: 1, green: 0.82, blue: 0.88)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}
