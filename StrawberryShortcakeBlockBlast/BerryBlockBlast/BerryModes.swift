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
    @AppStorage(BerryDayNightAppearance.storageKey) private var isNight = false
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
    @State private var showDailyCalendar = false
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
        .buttonStyle(BerryPolishPressStyle())
    }
    private var version: String { BerryBuildIdentity.homeLabel }
    @AppStorage("berryblockblast.story.level") private var storyLevel = 1
    @AppStorage("berryberryblast.birthday.month.v0511") private var birthdayMonth = 0
    @AppStorage("berryberryblast.birthday.day.v0511") private var birthdayDay = 0
    private var birthdayToday: Bool {
        BerryBirthdayPolicy.isBirthday(month: birthdayMonth,
                                       day: birthdayDay, on: Date())
    }
    private var birthdayClaimed: Bool {
        BerryBirthdayPolicy.hasClaimed(on: Date())
    }
    var body: some View {
        ZStack {
            LinearGradient(colors: isNight ?
                [Color(red: 0.80, green: 0.77, blue: 0.95),
                 Color(red: 0.94, green: 0.88, blue: 0.97),
                 Color(red: 0.91, green: 0.70, blue: 0.83)] :
                [Color(red: 1, green: 0.86, blue: 0.91),
                 Color(red: 1, green: 0.97, blue: 0.88),
                 Color(red: 1, green: 0.78, blue: 0.84)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
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
                                BerryCandyToolbarButton(
                                    symbol: "basket.fill", title: "Open Berry Boutique",
                                    size: 41, tint: BerryStyle.leaf) {
                                    showHomeShop = true
                                }
                                BerryCandyToolbarButton(
                                    symbol: "gearshape.fill", title: "Settings",
                                    size: 41) {
                                    showSettings = true
                                }
                            }
                            BerryLiveDayNightClock()
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
                            if birthdayToday {
                                Button {
                                    if BerryBirthdayPolicy.claim(month: birthdayMonth,
                                                                 day: birthdayDay,
                                                                 on: Date(),
                                                                 session: villageSession) {
                                        villageSession.refreshEconomyFromDisk()
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        BerryApprovedArtwork(name: "BBBIconBirthday",
                                                             fallback: "birthday.cake.fill", size: 60)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("🎂 HAPPY BERRY BIRTHDAY!")
                                                .font(.system(size: 14, weight: .black, design: .rounded))
                                            Text(birthdayClaimed ? "Your annual birthday gift was collected!" :
                                                 "Claim your one-time annual gift of 100 strawberries!")
                                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .foregroundStyle(BerryStyle.chocolate)
                                    .padding(12)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 19))
                                    .overlay(RoundedRectangle(cornerRadius: 19)
                                        .strokeBorder(BerryStyle.strawberry.opacity(0.48), lineWidth: 1.4))
                                }
                                .buttonStyle(.plain)
                                .disabled(birthdayClaimed)
                            }
                            Text("PLAY YOUR BERRY GAMES")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(BerryStyle.strawberry)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                                GridItem(.flexible(), spacing: 11)], spacing: 11) {
                                BerryGridNavigationTile(
                                    title: "Berry Classic",
                                    detail: "The pure 8×8 block puzzle. No timer or power-ups.",
                                    art: "BerryClassic",
                                    caption: "High Score"
                                ) {
                                    BerryAudio.shared.setMusic(music)
                                    audio.play(.gameStart)
                                    activeMode = .classic
                                }
                                ForEach(Array(BerryMode.allCases.prefix(3))) { mode in
                                    BerryGridNavigationTile(
                                        title: mode.rawValue,
                                        detail: mode.description,
                                        art: mode == .endless ? "SweetEndless" :
                                             mode == .story ? "BerryStory" : "DailyHarvest",
                                        caption: mode == .daily ?
                                            (BerryDailyHistory.outcome() == .won ? "✓ Completed Today" :
                                             BerryDailyHistory.outcome() == .lost ? "Daily Attempt Used" :
                                             BerryDailyHistory.outcome() == .active ? "Resume Today" : "Play Today") :
                                            mode == .story ? "Chapter \(storyLevel) Ready" :
                                            mode == .endless && !savedEndlessSizes.isEmpty ?
                                            "Saved Forever Garden" : "Play Now") {
                                        audio.setMusic(music)
                                        if mode == .endless {
                                            showBoardPicker = true
                                        } else if mode == .daily &&
                                            (BerryDailyHistory.outcome() == .won ||
                                             BerryDailyHistory.outcome() == .lost) {
                                            showDailyCalendar = true
                                        } else {
                                            audio.play(.gameStart)
                                            activeMode = mode
                                        }
                                    }
                                }
                                BerryGridNavigationTile(
                                    title: "My Strawberry Cottage",
                                    detail: "Arrange your purchased garden decorations",
                                    art: "CottageDecorations", caption: "Decorate") {
                                    audio.play(.menuSelect)
                                    showHomeCottage = true
                                }
                                BerryGridNavigationTile(
                                    title: "More Adventures",
                                    detail: "Berry Blitz, Cozy Cottage and Nightmare",
                                    art: "MoreAdventures", caption: "Explore") {
                                    audio.play(.menuSelect)
                                    showMore = true
                                }
                            }
                            Text("EXPLORE YOUR STRAWBERRY VILLAGE")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(BerryStyle.strawberry)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                                GridItem(.flexible(), spacing: 11)], spacing: 11) {
                                BerryGridNavigationTile(
                                    title: "Berry Collection", detail: "Inventory, awards and personal records",
                                    art: "BerryCollection", caption: "My Treasures") {
                                    showCollection = true
                                }
                                BerryGridNavigationTile(
                                    title: "Strawberry School", detail: "Learn the berry basics",
                                    art: "StrawberrySchool", caption: "5 Lessons") {
                                    showSchool = true
                                }
                                BerryGridNavigationTile(
                                    title: "Berry Village", detail: "Watch our little world grow",
                                    art: BerryArtResolver.displayName(for: "BerryVillageMap"), caption: "Explore Village") {
                                    showVillage = true
                                }
                                BerryGridNavigationTile(
                                    title: "Berry Quests", detail: "Three real goals every day",
                                    art: BerryArtResolver.displayName(for: "BerryQuestBoardArt"), caption: "Daily Quests") {
                                    showQuests = true
                                }
                                BerryGridNavigationTile(
                                    title: "Berry Journal", detail: "Your personal berry scrapbook",
                                    art: BerryArtResolver.displayName(for: "BerryJournalArt"), caption: "My Progress") {
                                    showJournal = true
                                }
                                BerryGridNavigationTile(
                                    title: "Daily Streak", detail: "Calendar, win streak and daily outcome",
                                    art: "DailyHarvest", caption: "View Calendar") {
                                    showDailyCalendar = true
                                }

                            }
                            Text("MUSIC, STYLE & EXTRAS")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(BerryStyle.strawberry)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                                GridItem(.flexible(), spacing: 11)], spacing: 11) {
                                BerryGridNavigationTile(
                                    title: "Strawberry Jukebox", detail: "51 original songs stored offline",
                                    art: "StrawberryJukebox",
                                    caption: music ? "Play Music" : "Music Paused") {
                                    audio.play(.menuSelect)
                                    showJukebox = true
                                }
                                BerryGridNavigationTile(
                                    title: "Berry Boutique", detail: "Boards, frames and garden upgrades",
                                    art: "ShopBasket", caption: "Visit Market") {
                                    audio.play(.menuSelect)
                                    showHomeShop = true
                                }
                            }
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
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 18)
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
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                            GridItem(.flexible(), spacing: 11)], spacing: 11) {
                            ForEach(Array(BerryMode.allCases.dropFirst(3).filter { $0 != .classic })) { mode in
                                BerryGridNavigationTile(
                                    title: mode.rawValue,
                                    detail: mode.description,
                                    art: mode == .cozy ? "CottageDecorations" :
                                         mode == .challenge ? "Milestone" : "MoreAdventures",
                                    caption: mode == .superHard ? "12×12 · 3 Minutes" :
                                             mode == .challenge ? "4 Time Trials" : "Cozy Play") {
                                    showMore = false
                                    audio.play(.menuSelect)
                                    if mode == .challenge {
                                        launchBlitzAfterMoreDismissal = true
                                    } else {
                                        audio.play(.gameStart)
                                        activeMode = mode
                                    }
                                }
                            }
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
        .sheet(isPresented: $showDailyCalendar) {
            BerryDailyHarvestView(goal: 120)
        }
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
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                            GridItem(.flexible(), spacing: 11)], spacing: 11) {
                            ForEach([8, 12, 24], id: \.self) { side in
                                BerryGridNavigationTile(
                                    title: "\(side) × \(side) Garden",
                                    detail: side == 8 ? "Classic-sized, easy to read" :
                                        side == 12 ? "More room for puzzle planning" :
                                        "Four automatic 12×12 patches · no scrolling",
                                    art: "SweetEndless",
                                    caption: savedEndlessSizes.contains(side) ?
                                        "Resume Saved Garden" : "Start New Garden",
                                    selected: endlessSize == side) {
                                    endlessSize = side
                                    showBoardPicker = false
                                    audio.play(.gameStart)
                                    activeMode = .endless
                                }
                            }
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
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 11),
                                            GridItem(.flexible(), spacing: 11)], spacing: 11) {
                            ForEach(BerryBlitzVariant.allCases) { variant in
                                BerryGridNavigationTile(
                                    title: variant.rawValue,
                                    detail: variant.subtitle,
                                    art: variant == .quick60 ? "Milestone" :
                                         variant == .rush120 ? "MoreAdventures" :
                                         variant == .garden300 ? "HarvestReward" : "Champion",
                                    caption: "🏆 \(BerryNumbers.compact(UserDefaults.standard.integer(forKey: variant.bestScoreKey)))",
                                    selected: selectedBlitz == variant.rawValue) {
                                    selectedBlitz = variant.rawValue
                                    showBlitzPicker = false
                                    audio.play(.gameStart)
                                    activeMode = .challenge
                                }
                            }
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
                BerrySettingsHubView()
                    .navigationTitle("🍓 Berry Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                audio.play(.menuBack)
                                showSettings = false
                            }
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
        #if BERRY_INTERNAL_QA
        .onReceive(NotificationCenter.default.publisher(
            for: BerryGameSession.qaWalletChanged)) { _ in
            villageSession.refreshEconomyFromDisk()
        }
        #endif
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
