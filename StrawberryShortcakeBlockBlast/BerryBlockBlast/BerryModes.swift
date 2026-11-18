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
        case .challenge: "One, two, five and ten-minute score races. Keep racing until time runs out!"
        case .superHard: "Three minutes in a 12 × 12 nightmare garden. Every move counts!"
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
    @State private var showHomeShop = false
    @State private var showHomeCottage = false
    @State private var showVillage = false
    @State private var showQuests = false
    @State private var showJournal = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showBoutiqueAfterCollection = false
    @StateObject private var villageSession = BerryGameSession()
    @AppStorage("berryblockblast.quoteIndex.v057") private var quoteIndex = 0
    private let gardenQuotes = [
        "A sweeter day begins with one little berry.",
        "Every lovely garden starts with a single seed.",
        "Little blocks, big berry dreams.",
        "Make room for something wonderful to bloom.",
        "The sweetest harvest is the one you grow."
    ]
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
    private func villageLink(_ title: String, detail: String, icon: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(BerryStyle.strawberry)
                    .frame(width: 59, height: 59)
                    .background(BerryStyle.softPink, in: RoundedRectangle(cornerRadius: 17))
                Text(title).font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                Text(detail).font(.system(size: 10, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.7))
            }
            .frame(maxWidth: .infinity, minHeight: 147)
            .padding(9)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(BerryStyle.strawberry.opacity(0.28)))
        }
        .buttonStyle(.plain)
    }
    private var version: String { "🍓 v0.5.9 • 1" }
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
                                BerryWalletPill(berries: villageSession.berries)
                                Button { showHomeShop = true } label: {
                                    BerryIcon(name: "ShopBasket", size: 39)
                                        .frame(width: 43, height: 43)
                                }.accessibilityLabel("Open Berry Boutique")
                                Button { showSettings = true } label: { Image(systemName: "gearshape.fill").font(.title2).foregroundStyle(BerryStyle.strawberry).frame(width: 46, height: 46).background(.white, in: Circle()) }.accessibilityLabel("Settings")
                            }
                            Text("🍓 ✨ 🍰 ✨ 🍓").font(.title2)
                                .accessibilityLabel("Strawberry sweets")
                            Text("✿ WELCOME TO BERRY VILLAGE ✿").font(.system(size: 12, weight: .black, design: .rounded)).tracking(2).foregroundStyle(BerryStyle.leaf)
                            BerryGirlView().frame(width: 174, height: 180)
                                .background(Circle().fill(.white.opacity(0.45)).shadow(color: BerryStyle.strawberry.opacity(0.2), radius: 18, y: 6))
                                .frame(maxWidth: .infinity, alignment: .center)
                            Group {
                                if UIImage(named: "BerryBerryBlastLogo") != nil {
                                    Image("BerryBerryBlastLogo").resizable().scaledToFit()
                                        .frame(maxWidth: 330).frame(height: 82)
                                } else {
                                    Text("Berry Berry Blast!")
                                        .font(.system(size: 34, weight: .black, design: .rounded))
                                        .minimumScaleFactor(0.65).lineLimit(1)
                                        .foregroundStyle(BerryStyle.strawberry)
                                }
                            }
                            Text("PICK • PLANT • POP • CELEBRATE").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(BerryStyle.chocolate)
                            Text("What shall we bake up today? 🍰").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(BerryStyle.chocolate).padding(.vertical, 8)
                            Button {
                                BerryAudio.shared.setMusic(music)
                                audio.play(.gameStart)
                                activeMode = .classic
                            } label: {
                                HStack(spacing: 13) {
                                    BerryIcon(name: "BerryClassic", size: 56)
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
                                        BerryIcon(name: mode == .endless ? "SweetEndless" : mode == .story ? "BerryStory" : "DailyHarvest", size: 56)
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
                            Button {
                                audio.play(.menuSelect)
                                showHomeCottage = true
                            } label: {
                                HStack(spacing: 12) {
                                    BerryIcon(name: "CottageDecorations", size: 53)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("My Strawberry Cottage").font(.headline)
                                        Text("Decorate your garden and arrange your collection")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .padding(12)
                                .background(.white, in: RoundedRectangle(cornerRadius: 19))
                            }.buttonStyle(.plain)
                            Button {
                                audio.play(.menuSelect)
                                showMore = true
                            } label: {
                                HStack(spacing: 12) {
                                    BerryIcon(name: "MoreAdventures", size: 52)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("More Adventures").font(.headline)
                                        Text("Blitz • Cozy Cottage • Nightmare").font(.caption)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle(BerryStyle.chocolate)
                                .padding(12)
                                .background(.white, in: RoundedRectangle(cornerRadius: 19))
                            }.buttonStyle(.plain)
                            HStack(spacing: 12) {
                                Button { showCollection = true } label: {
                                    VStack(spacing: 4) {
                                        BerryIcon(name: "BerryCollection", size: 65)
                                        Text("Collection").font(.caption.bold())
                                    }.frame(maxWidth: .infinity).padding(10)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 17))
                                }
                                Button { showSchool = true } label: {
                                    VStack(spacing: 4) {
                                        BerryIcon(name: "StrawberrySchool", size: 65)
                                        Text("Strawberry School").font(.caption.bold())
                                    }.frame(maxWidth: .infinity).padding(10)
                                        .background(.white, in: RoundedRectangle(cornerRadius: 17))
                                }
                            }
                            .foregroundStyle(BerryStyle.chocolate)
                            .buttonStyle(.plain)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                villageLink("Berry Village", detail: "Watch our little world grow", icon: "house.fill") { showVillage = true }
                                villageLink("Berry Quests", detail: "Three fresh daily goals", icon: "checklist") { showQuests = true }
                                villageLink("Berry Journal", detail: "Your berry scrapbook", icon: "book.closed.fill") { showJournal = true }
                                villageLink("Daily Streak", detail: "Rewards up to 50 berries", icon: "calendar") {
                                    activeMode = .daily
                                }
                            }
                            Button {
                                audio.play(.menuSelect)
                                showJukebox = true
                            } label: {
                                HStack(spacing: 10) {
                                    BerryIcon(name: "StrawberryJukebox", size: 45)
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
                            HStack(spacing: 7) {
                                Image(systemName: "quote.bubble.fill")
                                Text(gardenQuotes[quoteIndex % gardenQuotes.count])
                                    .id(quoteIndex)
                                    .transition(.opacity)
                                    .multilineTextAlignment(.center)
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .padding(.vertical, 5)
                            .accessibilityLabel("A strawberry garden thought")
                        }
                        .padding(22)
                        .frame(maxWidth: 530)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height, alignment: .center)
                    }
                }
            }
        }
        .sheet(isPresented: $showCollection, onDismiss: {
            if showBoutiqueAfterCollection {
                showBoutiqueAfterCollection = false
                showHomeShop = true
            }
        }) {
            NavigationStack {
                BerryCollectionView(session: villageSession, lifetimeLines: lifetimeLines) {
                    showBoutiqueAfterCollection = true
                    showCollection = false
                }
                .navigationTitle("Berry Collection")
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showCollection = false }
                }}
            }
        }
        .sheet(isPresented: $showHomeShop, onDismiss: {
            villageSession.refreshEconomyFromDisk()
        }) {
            NavigationStack {
                ScrollView {
                    BerryBoutiqueView(session: villageSession)
                        .padding(.horizontal, 16).padding(.vertical, 18)
                }
                .background(BerryStyle.cream.ignoresSafeArea())
                .navigationTitle("Market")
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showHomeShop = false }
                }}
            }
        }
        .sheet(isPresented: $showHomeCottage) {
            BerryCottageGardenView(session: villageSession)
        }
        .sheet(isPresented: $showVillage, onDismiss: { villageSession.refreshEconomyFromDisk() }) {
            BerryVillageView(session: villageSession)
        }
        .sheet(isPresented: $showQuests, onDismiss: { villageSession.refreshEconomyFromDisk() }) {
            BerryQuestBoardView(session: villageSession)
        }
        .sheet(isPresented: $showJournal) {
            BerryJournalView(session: villageSession)
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
                                    BerryIcon(name: mode == .cozy ? "CottageDecorations" :
                                             mode == .challenge ? "Milestone" : "MoreAdventures", size: 55)
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
                            Text("A berry-sweet puzzle garden. Earn strawberries and decorate your world!")
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
            villageSession.refreshEconomyFromDisk()
        }
        .onReceive(Timer.publish(every: 18, on: .main, in: .common).autoconnect()) { _ in
            guard activeMode == nil, scenePhase == .active else { return }
            withAnimation(reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled ?
                          nil : .easeInOut(duration: 0.25)) {
                quoteIndex = (quoteIndex + 1) % gardenQuotes.count
            }
        }
        .onChange(of: activeMode) { selected in
            if selected == nil {
                villageSession.refreshEconomyFromDisk()
                savedEndlessSizes = Set([8, 12, 24].filter { BerryGameSession.hasResumableEndless(side: $0) })
            }
            audio.setScreen(selected == nil ? .menu : selected == .challenge ? .blitz : .gameplay)
        }
        .animation(reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled ?
                   nil : .easeOut(duration: 0.18), value: activeMode)
        .preferredColorScheme(.light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}
