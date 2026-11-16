import SwiftUI

enum BerryMode: String, CaseIterable, Identifiable {
    case endless = "Sweet Endless"
    case story = "Berry Story"
    case daily = "Daily Harvest"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .endless: "infinity"
        case .story: "map.fill"
        case .daily: "calendar"
        }
    }
    var description: String {
        switch self {
        case .endless: "A timeless garden. How high can you score?"
        case .story: "Earn stars, complete chapters, unlock the next!"
        case .daily: "One fresh strawberry challenge every day."
        }
    }
}

struct BerryHomeView: View {
    @State private var activeMode: BerryMode?
    @AppStorage("berryblockblast.story.level") private var storyLevel = 1
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1, green: 0.86, blue: 0.91), Color(red: 1, green: 0.97, blue: 0.88), Color(red: 1, green: 0.78, blue: 0.84)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            if let activeMode {
                BerryGameView(mode: activeMode, onExit: { self.activeMode = nil })
            } else {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 15) {
                            Text("✿ WELCOME TO STRAWBERRY VILLAGE ✿").font(.system(size: 12, weight: .black, design: .rounded)).tracking(2).foregroundStyle(BerryStyle.leaf)
                            BerryGirlView().frame(width: 135, height: 135).clipped()
                            Text("Berry Block Blast!").font(.system(size: 34, weight: .black, design: .rounded)).minimumScaleFactor(0.65).lineLimit(1).foregroundStyle(BerryStyle.strawberry)
                            Text("PICK • PLANT • POP • CELEBRATE").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(BerryStyle.chocolate)
                            Text("What shall we bake up today? 🍰").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.chocolate).padding(.vertical, 8)
                            ForEach(BerryMode.allCases) { mode in
                                Button { activeMode = mode } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: mode.icon).font(.system(size: 23, weight: .bold)).foregroundStyle(.white).frame(width: 53, height: 53).background(mode == .story ? BerryStyle.leaf : BerryStyle.strawberry, in: RoundedRectangle(cornerRadius: 16))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mode.rawValue).font(.system(size: 20, weight: .black, design: .rounded))
                                            Text(mode.description).font(.system(size: 12, weight: .medium, design: .rounded)).multilineTextAlignment(.leading)
                                            if mode == .story { Text("Chapter \(storyLevel) ready").font(.system(size: 11, weight: .bold)).foregroundStyle(BerryStyle.leaf) }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundStyle(BerryStyle.chocolate)
                                    .padding(14)
                                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 21))
                                    .overlay(RoundedRectangle(cornerRadius: 21).stroke(.white, lineWidth: 2))
                                }.buttonStyle(.plain)
                            }
                            Text("🍓 No ads • Offline • Just a little sweetness 🍓").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(BerryStyle.chocolate.opacity(0.75)).padding(.top, 10)
                        }
                        .padding(22)
                        .frame(maxWidth: 530)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height, alignment: .center)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}
