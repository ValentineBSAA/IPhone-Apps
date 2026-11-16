import SwiftUI

enum BerryMode: String, CaseIterable, Identifiable {
    case endless = "Sweet Endless"
    case story = "Berry Story"
    case daily = "Daily Harvest"
    case cozy = "Cozy Cottage"
    case challenge = "Berry Blitz"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .endless: "infinity"
        case .story: "map.fill"
        case .daily: "calendar"
        case .cozy: "cup.and.saucer.fill"
        case .challenge: "bolt.fill"
        }
    }
    var description: String {
        switch self {
        case .endless: "A timeless garden. How high can you score?"
        case .story: "Earn stars, complete chapters, unlock the next!"
        case .daily: "One fresh strawberry challenge every day."
        case .cozy: "Take it easy in a cozy garden."
        case .challenge: "Race to a sweet high-score target."
        }
    }
}

struct BerryHomeView: View {
    @State private var activeMode: BerryMode?
    @State private var showSettings = false
    @AppStorage("berryblockblast.music") private var music = false
    @AppStorage("berryblockblast.sound") private var sound = true
    @AppStorage("berryblockblast.haptics") private var haptics = true
    private var version: String { "🍓 v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev") • \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")" }
    @AppStorage("berryblockblast.story.level") private var storyLevel = 1
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1, green: 0.86, blue: 0.91), Color(red: 1, green: 0.97, blue: 0.88), Color(red: 1, green: 0.78, blue: 0.84)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            if let activeMode {
                BerryGameView(mode: activeMode, onExit: { self.activeMode = nil })
            } else {
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 12) {
                            HStack {
                                Text(version).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.strawberry).padding(10).background(.white.opacity(0.9), in: Capsule())
                                Spacer()
                                Button { showSettings = true } label: { Image(systemName: "gearshape.fill").font(.title2).foregroundStyle(BerryStyle.strawberry).frame(width: 46, height: 46).background(.white, in: Circle()) }.accessibilityLabel("Settings")
                            }
                            Text("🍓 ✨ 🍰 ✨ 🍓").font(.title2)
                            Text("✿ WELCOME TO STRAWBERRY VILLAGE ✿").font(.system(size: 12, weight: .black, design: .rounded)).tracking(2).foregroundStyle(BerryStyle.leaf)
                            BerryGirlView().frame(width: 135, height: 135).clipped()
                            Text("Berry Block Blast!").font(.system(size: 34, weight: .black, design: .rounded)).minimumScaleFactor(0.65).lineLimit(1).foregroundStyle(BerryStyle.strawberry)
                            Text("PICK • PLANT • POP • CELEBRATE").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(BerryStyle.chocolate)
                            Text("What shall we bake up today? 🍰").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.chocolate).padding(.vertical, 8)
                            ForEach(BerryMode.allCases) { mode in
                                Button { BerryAudio.shared.setMusic(music); activeMode = mode } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: mode.icon).font(.system(size: 23, weight: .bold)).foregroundStyle(.white).frame(width: 53, height: 53).background(mode == .story ? BerryStyle.leaf : BerryStyle.strawberry, in: RoundedRectangle(cornerRadius: 16))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mode.rawValue).font(.system(size: 20, weight: .black, design: .rounded))
                                            Text(mode.description).font(.system(size: 12, weight: .medium, design: .rounded)).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
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
                            HStack {
                                Text(music ? "🎶 Music box playing" : "🎶 Music box paused")
                                Spacer()
                                Button(music ? "Pause" : "Play") { music.toggle(); BerryAudio.shared.setMusic(music) }.fontWeight(.bold)
                            }.font(.system(size: 12, design: .rounded)).foregroundStyle(BerryStyle.strawberry).padding(12).background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
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
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                Form {
                    Section("Strawberry Sound Studio 🎶") {
                        Toggle("Music box melody", isOn: $music).onChange(of: music) { _, enabled in BerryAudio.shared.setMusic(enabled) }
                        Toggle("Sweet sound effects", isOn: $sound)
                        Toggle("Haptic feedback", isOn: $haptics)
                        Button("Test berry chimes 🍓") { BerryAudio.shared.play(.clear) }
                    }
                    Section("About") { LabeledContent("Version", value: version); Text("Original offline strawberry puzzle. No ads or purchases.") }
                }
                .navigationTitle("Berry Settings")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSettings = false } } }
            }.presentationDetents([.medium, .large])
        }
        .preferredColorScheme(.light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}
