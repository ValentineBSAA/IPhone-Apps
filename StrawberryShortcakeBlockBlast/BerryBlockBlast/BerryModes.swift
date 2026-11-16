import SwiftUI

enum BerryMode: String, CaseIterable, Identifiable {
    case endless = "Sweet Endless"
    case story = "Berry Story"
    case daily = "Daily Harvest"
    case cozy = "Cozy Cottage"
    case challenge = "Berry Blitz"
    case superHard = "Strawberry Nightmare"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .endless: "infinity"
        case .story: "book.closed.fill"
        case .daily: "calendar"
        case .cozy: "cup.and.saucer.fill"
        case .challenge: "bolt.fill"
        case .superHard: "square.grid.3x3.fill"
        }
    }
    var description: String {
        switch self {
        case .endless: "A timeless garden. How high can you score?"
        case .story: "Earn stars, complete chapters, unlock the next!"
        case .daily: "One fresh strawberry challenge every day."
        case .cozy: "Take it easy in a cozy garden."
        case .challenge: "Race to a sweet high-score target."
        case .superHard: "A 12 × 12 garden with bigger pieces. Every move counts!"
        }
    }
}

struct BerryHomeView: View {
    @State private var activeMode: BerryMode?
    @State private var showSettings = false
    @State private var showMore = false
    @State private var showSchool = false
    @State private var showCollection = false
    @State private var jukeboxRefresh = 0
    @AppStorage("berryblockblast.lifetime-lines") private var lifetimeLines = 0
    @AppStorage("berryblockblast.strawberry-unlocked") private var strawberryUnlocked = false
    @AppStorage("berryblockblast.music") private var music = true
    @AppStorage("berryblockblast.sound") private var sound = true
    @AppStorage("berryblockblast.haptics") private var haptics = true
    @AppStorage("berryblockblast.musicVolume") private var musicVolume = 0.22
    @AppStorage("berryblockblast.effectVolume") private var effectVolume = 0.65
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
                                .accessibilityLabel("Strawberry sweets")
                            Text("✿ WELCOME TO STRAWBERRY VILLAGE ✿").font(.system(size: 12, weight: .black, design: .rounded)).tracking(2).foregroundStyle(BerryStyle.leaf)
                            BerryGirlView().frame(width: 174, height: 180)
                                .background(Circle().fill(.white.opacity(0.45)).shadow(color: BerryStyle.strawberry.opacity(0.2), radius: 18, y: 6))
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text("Berry Block Blast!").font(.system(size: 34, weight: .black, design: .rounded)).minimumScaleFactor(0.65).lineLimit(1).foregroundStyle(BerryStyle.strawberry)
                            Text("PICK • PLANT • POP • CELEBRATE").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(BerryStyle.chocolate)
                            Text("What shall we bake up today? 🍰").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.chocolate).padding(.vertical, 8)
                            ForEach(Array(BerryMode.allCases.prefix(3))) { mode in
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
                            Button("🧺 More Adventures  •  Strawberry Nightmare") { showMore = true }
                                .font(.title3.bold()).foregroundStyle(BerryStyle.strawberry)
                                .frame(maxWidth: .infinity).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20))
                            Button("📖 Berry Collection") { showCollection = true }
                                .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.strawberry)
                            Button("🍓 Strawberry School • Learn to Play") { showSchool = true }
                                .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.leaf)
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
        .sheet(isPresented: $showCollection) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("🍓 The Berry Collection").font(.title.bold()).foregroundStyle(BerryStyle.strawberry)
                        Text("🌸 🍓 🎀 🍰 🌿").font(.title2)
                        Text("Collect new berry blocks by clearing lines in any garden.")
                        ProgressView(value: Double(min(10, lifetimeLines)), total: 10).tint(BerryStyle.strawberry)
                        Text("\(lifetimeLines) lifetime lines harvested")
                        Label("Classic Blocks • Unlocked", systemImage: "checkmark.seal.fill")
                        Text(strawberryUnlocked ? "🍓 Strawberry Blocks • Unlocked" : "🔒 Strawberry Blocks • Clear 10 lines")
                            .font(.headline).foregroundStyle(BerryStyle.leaf)
                    }.padding(24)
                }.background(BerryStyle.cream.ignoresSafeArea())
                .navigationTitle("Berry Collection")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showCollection = false } } }
            }
        }
        .sheet(isPresented: $showSchool) { BerrySchoolView(onFinish: { graduated in showSchool = false; if graduated { BerryGameSession().rewardTutorial() } }) }
        .sheet(isPresented: $showMore) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 18) {
                        Text("🍓 More Sweet Adventures").font(.title.bold()).foregroundStyle(BerryStyle.strawberry)
                        Text("🌸 A basket of new adventures 🌸").font(.subheadline.bold()).foregroundStyle(BerryStyle.leaf)
                        ForEach(Array(BerryMode.allCases.dropFirst(3))) { mode in
                            Button {
                                showMore = false
                                activeMode = mode
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 52, height: 52)
                                        .background(mode == .superHard ? BerryStyle.chocolate : BerryStyle.strawberry,
                                                    in: RoundedRectangle(cornerRadius: 16))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(mode.rawValue)
                                            .font(.system(size: 19, weight: .black, design: .rounded))
                                        Text(mode.description)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.leading)
                                        if mode == .superHard {
                                            Text("12 × 12  •  144 squares  •  Larger pieces")
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundStyle(BerryStyle.strawberry)
                                        }
                                    }
                                    Spacer(minLength: 4)
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.bold())
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 22))
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                        Text("🎶 Strawberry Jukebox").font(.title2.bold())
                        Text(BerryAudio.shared.currentTrackName).font(.headline).foregroundStyle(BerryStyle.chocolate)
                        Text("Track \(BerryAudio.shared.currentTrackNumber) of 15").font(.caption)
                        HStack(spacing: 14) {
                            Button { BerryAudio.shared.previousTrack(); jukeboxRefresh += 1 } label: { Label("Previous", systemImage: "backward.end.fill") }
                            Button { music.toggle(); BerryAudio.shared.setMusic(music); jukeboxRefresh += 1 } label: { Image(systemName: music ? "pause.fill" : "play.fill") }
                            Button { BerryAudio.shared.nextTrack(); jukeboxRefresh += 1 } label: { Label("Next", systemImage: "forward.end.fill") }
                        }.buttonStyle(.borderedProminent).tint(BerryStyle.strawberry)
                        Button(BerryAudio.shared.isShuffling ? "Shuffle On" : "Play in Order") {
                            BerryAudio.shared.toggleShuffle(); jukeboxRefresh += 1
                        }.buttonStyle(.bordered)
                        ForEach(Array(BerryAudio.trackNames.enumerated()), id: \.offset) { index, title in
                            Button {
                                if !music { music = true; BerryAudio.shared.setMusic(true) }
                                BerryAudio.shared.selectTrack(index)
                                jukeboxRefresh += 1
                            } label: {
                                HStack {
                                    Text("\(index + 1). \(title)").multilineTextAlignment(.leading)
                                    Spacer()
                                    if BerryAudio.shared.currentTrackNumber == index + 1 { Image(systemName: "music.note") }
                                }
                            }.buttonStyle(.plain).foregroundStyle(BerryStyle.chocolate).padding(.vertical, 5)
                        }
                        Text("Original synthesized melodies made for Berry Block Blast.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(22)
                }.background(BerryStyle.cream.ignoresSafeArea())
                .navigationTitle("More Adventures")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showMore = false } } }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 18) {
                        Text("🍓 🎶 🌸")
                            .font(.system(size: 38))
                        Text("Strawberry Sound Studio")
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                        VStack(alignment: .leading, spacing: 18) {
                            Toggle("Music box melody", isOn: $music)
                                .onChange(of: music) { _, enabled in BerryAudio.shared.setMusic(enabled) }
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🎵 Music Volume").font(.subheadline.bold())
                                Slider(value: $musicVolume, in: 0...1)
                                    .onChange(of: musicVolume) { _, value in BerryAudio.shared.setMusicVolume(Float(value)) }
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🍓 Berry Sounds Volume").font(.subheadline.bold())
                                Slider(value: $effectVolume, in: 0...1)
                                    .onChange(of: effectVolume) { _, value in BerryAudio.shared.setEffectVolume(Float(value)) }
                            }
                            Toggle("Sweet sound effects", isOn: $sound)
                            Toggle("Haptic feedback", isOn: $haptics)
                            Button { BerryAudio.shared.play(.clear) } label: {
                                Label("Test berry chimes", systemImage: "music.note")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(BerryStyle.strawberry)
                        }
                        .tint(BerryStyle.strawberry)
                        .foregroundStyle(BerryStyle.chocolate)
                        .padding(20)
                        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white, lineWidth: 2))
                        VStack(spacing: 6) {
                            Text(version).font(.subheadline.bold())
                            Text("Original offline strawberry puzzle. No ads or purchases.")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
                    }
                    .padding(22)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .background(LinearGradient(colors: [BerryStyle.cream, Color(red: 1, green: 0.85, blue: 0.90)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
                .navigationTitle("🍓 Berry Settings")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSettings = false } } }
            }.presentationDetents([.medium, .large])
        }
        .onAppear { BerryAudio.shared.setMusicVolume(Float(musicVolume)); BerryAudio.shared.setEffectVolume(Float(effectVolume)); BerryAudio.shared.setMusic(music) }
        .preferredColorScheme(.light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}
