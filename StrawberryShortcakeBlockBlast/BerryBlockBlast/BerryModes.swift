import SwiftUI

enum BerryMode: String, CaseIterable, Identifiable {
    case endless = "Sweet Endless"
    case story = "Berry Story"
    case daily = "Daily Harvest"
    case cozy = "Cozy Cottage"
    case challenge = "Berry Blitz"
    case superHard = "Strawberry Nightmare"
    case classic = "Berry Classic"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .endless: "infinity"
        case .story: "book.closed.fill"
        case .daily: "calendar"
        case .cozy: "cup.and.saucer.fill"
        case .challenge: "bolt.fill"
        case .superHard: "square.grid.3x3.fill"
        case .classic: "crown.fill"
        }
    }
    var description: String {
        switch self {
        case .endless: "Your forever garden. Play, save and grow through new seasons!"
        case .story: "Earn stars, complete chapters, unlock the next!"
        case .daily: "One fresh strawberry challenge every day."
        case .cozy: "Take it easy in a cozy garden."
        case .challenge: "One-minute or two-minute score races. The clock is ticking!"
        case .superHard: "A 12 × 12 garden with bigger pieces. Every move counts!"
        case .classic: "Pure 8 × 8 puzzle play with a glowing high score!"
        }
    }
}

struct BerryHomeView: View {
    @State private var activeMode: BerryMode?
    @State private var showSettings = false
    @State private var showMore = false
    @State private var showSchool = false
    @State private var showCollection = false
    @State private var showJukebox = false
    @State private var showBoardPicker = false
    @State private var showBlitzPicker = false
    @State private var launchBlitzAfterMoreDismissal = false
    @State private var savedEndlessSizes = Set([8, 12, 24].filter {
        BerryGameSession.hasResumableEndless(side: $0)
    })
    @AppStorage("berryblockblast.endless.boardSize.v056b2") private var endlessSize = 8
    @AppStorage("berryblockblast.blitz.variant.v056b2") private var selectedBlitz = BerryBlitzVariant.rush120.rawValue
    @ObservedObject private var audio = BerryAudio.shared
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
                            Button {
                                BerryAudio.shared.setMusic(music)
                                audio.play(.gameStart)
                                activeMode = .classic
                            } label: {
                                HStack(spacing: 13) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 25, weight: .black))
                                        .foregroundStyle(.white)
                                        .frame(width: 53, height: 53)
                                        .background(BerryStyle.strawberry, in: RoundedRectangle(cornerRadius: 16))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("🍓 Berry Classic")
                                            .font(.system(size: 21, weight: .black, design: .rounded))
                                        Text("The pure 8 × 8 block puzzle. No timer or power-ups.")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("✨ BIG BRIGHT HIGH SCORE")
                                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                                            .foregroundStyle(BerryStyle.strawberry)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .padding(14)
                                .background(
                                    LinearGradient(colors: [.white, Color(red: 1, green: 0.88, blue: 0.91), Color(red: 1, green: 0.97, blue: 0.85)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: RoundedRectangle(cornerRadius: 21)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(BerryStyle.strawberry.opacity(0.55), lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Play Berry Classic, the endless 8 by 8 block puzzle")
                            ForEach(Array(BerryMode.allCases.prefix(3))) { mode in
                                Button {
                                    audio.setMusic(music)
                                    if mode == .endless { showBoardPicker = true }
                                    else { audio.play(.gameStart); activeMode = mode }
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: mode.icon).font(.system(size: 23, weight: .bold)).foregroundStyle(.white).frame(width: 53, height: 53).background(mode == .story ? BerryStyle.leaf : BerryStyle.strawberry, in: RoundedRectangle(cornerRadius: 16))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(mode.rawValue).font(.system(size: 20, weight: .black, design: .rounded))
                                            Text(mode.description).font(.system(size: 12, weight: .medium, design: .rounded)).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                                            if mode == .story {
                                                Text("Chapter \(storyLevel) ready")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(BerryStyle.leaf)
                                            }
                                            if mode == .endless && !savedEndlessSizes.isEmpty {
                                                Label("🍓 SAVED FOREVER GARDEN", systemImage: "bookmark.fill")
                                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                                    .foregroundStyle(BerryStyle.leaf)
                                            }
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
                            Button("🧺 More Adventures  •  Blitz, Cozy & Nightmare") {
                                audio.play(.menuSelect)
                                showMore = true
                            }
                                .font(.title3.bold()).foregroundStyle(BerryStyle.strawberry)
                                .frame(maxWidth: .infinity).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20))
                            Button("📖 Berry Collection") { showCollection = true }
                                .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.strawberry)
                            Button("🍓 Strawberry School • Learn to Play") { showSchool = true }
                                .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.leaf)
                            Button {
                                audio.play(.menuSelect)
                                showJukebox = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 41, height: 41)
                                        .background(BerryStyle.strawberry, in: RoundedRectangle(cornerRadius: 12))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("🎶 Strawberry Jukebox")
                                            .font(.system(size: 15, weight: .black, design: .rounded))
                                        Text(music ? audio.currentTrackName : "Music paused")
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .padding(12)
                                .background(.white.opacity(0.91), in: RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(.plain)
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
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { audio.play(.menuBack); showCollection = false } } }
            }
        }
        .sheet(isPresented: $showSchool) { BerrySchoolView(onFinish: { graduated in showSchool = false; if graduated { BerryGameSession().rewardTutorial() } }) }
        .sheet(isPresented: $showMore, onDismiss: {
            if launchBlitzAfterMoreDismissal {
                launchBlitzAfterMoreDismissal = false
                showBlitzPicker = true
            }
        }) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 18) {
                        Text("🍓 More Sweet Adventures").font(.title.bold()).foregroundStyle(BerryStyle.strawberry)
                        Text("🌸 A basket of new adventures 🌸").font(.subheadline.bold()).foregroundStyle(BerryStyle.leaf)
                        ForEach(Array(BerryMode.allCases.dropFirst(3).filter { $0 != .classic })) { mode in
                            Button {
                                showMore = false
                                audio.play(.menuSelect)
                                if mode == .challenge {
                                    // Wait for More Adventures to finish closing
                                    // before presenting the Blitz picker.
                                    launchBlitzAfterMoreDismissal = true
                                } else {
                                    audio.play(.gameStart)
                                    activeMode = mode
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 52, height: 52)
                                        .background(mode == .superHard ? Color(red: 0.52, green: 0.35, blue: 0.73) :
                                                        mode == .challenge ? Color(red: 0.96, green: 0.58, blue: 0.14) :
                                                        BerryStyle.leaf,
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
                                .background(
                                    LinearGradient(colors: [.white,
                                        mode == .challenge ? Color(red: 1, green: 0.91, blue: 0.75) :
                                        mode == .superHard ? Color(red: 0.94, green: 0.86, blue: 1) :
                                        Color(red: 0.87, green: 0.97, blue: 0.83)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: RoundedRectangle(cornerRadius: 22))
                                .overlay(RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(BerryStyle.strawberry.opacity(0.35), lineWidth: 1.7))
                            }
                            .buttonStyle(.plain)
                        }
                        Text("🌸 Choose your adventure. The Jukebox has its own home.")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate.opacity(0.63))
                            .multilineTextAlignment(.center)
                    }.padding(22)
                }.background(BerryStyle.cream.ignoresSafeArea())
                .navigationTitle("More Adventures")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { audio.play(.menuBack); showMore = false } } }
            }
        }
        .sheet(isPresented: $showJukebox) { BerryJukeboxView() }
        .sheet(isPresented: $showBoardPicker) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 15) {
                        Text("🍓 Choose Your Garden Size")
                            .font(.system(size: 23, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                        Text("Sweet Endless never ends. Each garden size resumes its own saved run, even after a full board.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        ForEach([8,12,24], id: \.self) { side in
                            Button {
                                endlessSize = side
                                showBoardPicker = false
                                audio.play(.gameStart)
                                activeMode = .endless
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: side == 24 ? "square.grid.4x3.fill" : "square.grid.3x3.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(.white)
                                        .frame(width: 54, height: 54)
                                        .background(side == 24 ? BerryStyle.chocolate : BerryStyle.strawberry,
                                                    in: RoundedRectangle(cornerRadius: 15))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("\(side) × \(side) Garden")
                                            .font(.system(size: 21, weight: .black, design: .rounded))
                                        Text(side == 8 ? "Classic-sized, easy to read" :
                                            side == 12 ? "More planning, bigger puzzles" :
                                            "Mega Garden • pan the zoomed board")
                                            .font(.system(size: 12, weight: .medium))
                                        if savedEndlessSizes.contains(side) {
                                            Label("🍓 CONTINUE SAVED GARDEN", systemImage: "bookmark.fill")
                                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                                .foregroundStyle(BerryStyle.leaf)
                                        } else {
                                            Text("START NEW GARDEN")
                                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                                .foregroundStyle(BerryStyle.strawberry)
                                        }
                                    }
                                    Spacer()
                                    if endlessSize == side { Image(systemName: "checkmark.circle.fill") }
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .padding(14)
                                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                                .overlay(RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(BerryStyle.strawberry.opacity(0.42), lineWidth: 1.7))
                            }.buttonStyle(.plain)
                        }
                    }.padding(20)
                }
                .background(BerryStyle.cream.ignoresSafeArea())
                .navigationTitle("Garden Size")
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showBoardPicker = false }
                }}
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showBlitzPicker) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 15) {
                        Text("⚡ BERRY BLITZ")
                            .font(.system(size: 27, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                        Text("Race the clock, not a fixed score. No saving, no power-ups and no extra time.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        ForEach(BerryBlitzVariant.allCases) { variant in
                            Button {
                                selectedBlitz = variant.rawValue
                                showBlitzPicker = false
                                audio.play(.gameStart)
                                activeMode = .challenge
                            } label: {
                                HStack(spacing: 13) {
                                    Image(systemName: variant.icon)
                                        .font(.system(size: 24))
                                        .foregroundStyle(.white)
                                        .frame(width: 52, height: 52)
                                        .background(BerryStyle.strawberry, in: RoundedRectangle(cornerRadius: 16))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(variant.rawValue)
                                            .font(.system(size: 21, weight: .black, design: .rounded))
                                        Text(variant.subtitle)
                                            .font(.system(size: 12, weight: .medium))
                                        Text("🏆 Best: \(UserDefaults.standard.integer(forKey: variant.bestScoreKey))")
                                            .font(.system(size: 12, weight: .heavy))
                                            .foregroundStyle(BerryStyle.leaf)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .padding(14)
                                .background(.white, in: RoundedRectangle(cornerRadius: 21))
                                .overlay(RoundedRectangle(cornerRadius: 21)
                                    .strokeBorder(BerryStyle.strawberry.opacity(0.5), lineWidth: 1.8))
                            }
                            .buttonStyle(.plain)
                        }
                    }.padding(20)
                }
                .background(BerryStyle.cream.ignoresSafeArea())
                .navigationTitle("Berry Blitz Challenges")
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showBlitzPicker = false }
                }}
            }
            .presentationDetents([.large])
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
                        BerryMusicSettingsView()
                        VStack(spacing: 14) {
                            Toggle("Haptic feedback", isOn: $haptics)
                                .tint(BerryStyle.strawberry)
                            Button {
                                if sound { audio.play(.clear) }
                            } label: {
                                Label("Test berry chimes", systemImage: "music.note")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity).padding(12)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(BerryStyle.strawberry)
                            .disabled(!sound)
                        }
                        .foregroundStyle(BerryStyle.chocolate)
                        .padding(16)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20))
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
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { audio.play(.menuBack); showSettings = false } } }
            }.presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .onAppear {
            audio.setMusicVolume(Float(musicVolume))
            audio.setEffectVolume(Float(effectVolume))
            audio.setScreen(.menu)
            audio.setMusic(music)
            savedEndlessSizes = Set([8, 12, 24].filter { BerryGameSession.hasResumableEndless(side: $0) })
        }
        .onChange(of: activeMode) { selected in
            if selected == nil {
                savedEndlessSizes = Set([8, 12, 24].filter { BerryGameSession.hasResumableEndless(side: $0) })
            }
            audio.setScreen(selected == nil ? .menu : selected == .challenge ? .blitz : .gameplay)
        }
        .preferredColorScheme(.light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}
