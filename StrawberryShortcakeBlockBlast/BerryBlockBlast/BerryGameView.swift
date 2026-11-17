import SwiftUI
import UIKit
import AudioToolbox

private struct BerryDragState {
    var slot: Int
    var piece: BerryPiece
    var row: Int
    var col: Int
    var allowed: Bool
}

private struct BerryBoard: View {
    let engine: BerryEngine
    let preview: BerryDragState?
    let size: CGFloat
    let selected: Int?
    let mode: BerryMode
    let strawberryUnlocked: Bool
    let previewStyle: String
    let onBoardRect: (CGRect) -> Void
    @AppStorage("berryblockblast.shop.equippedBorder.v056b2") private var borderSkin = "default"
    private let gap: CGFloat = 3
    private var gardenBorder: Color {
        switch borderSkin {
        case "rose-border": return Color(red: 0.91, green: 0.25, blue: 0.55)
        case "mint-border": return Color(red: 0.32, green: 0.73, blue: 0.58)
        default: return Color(red: 0.98, green: 0.71, blue: 0.79)
        }
    }

    var body: some View {
        let side = engine.side
        let unit = (size - CGFloat(side - 1) * gap) / CGFloat(side)
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(gardenBorder)
                .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.8), lineWidth: 3) }
                .padding(-7)
                .shadow(color: BerryStyle.strawberry.opacity(0.22), radius: 15, y: 8)
            ForEach(0..<(side * side), id: \.self) { i in
                let r = i / side
                let c = i % side
                ZStack {
                    RoundedRectangle(cornerRadius: side > 8 ? 4 : 8)
                        .fill(Color.white.opacity(0.76))
                        .overlay(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: side > 8 ? 4 : 8).strokeBorder(.white.opacity(0.58), lineWidth: 1)
                        }
                    if let tint = engine.board[r][c] { BerryTile(tint: tint, mode: mode, strawberryUnlocked: strawberryUnlocked) }
                }
                .frame(width: unit, height: unit)
                .offset(x: CGFloat(c) * (unit + gap), y: CGFloat(r) * (unit + gap))
            }
            if let preview, previewStyle != "mystery" {
                ForEach(preview.piece.points, id: \.self) { p in
                    let r = preview.row + p.row
                    let c = preview.col + p.col
                    if (0..<side).contains(r), (0..<side).contains(c) {
                        BerryTile(tint: preview.piece.tint, preview: true, mode: mode, strawberryUnlocked: strawberryUnlocked)
                            .opacity(previewStyle == "outline" ? 0.18 : 0.56)
                            .overlay { RoundedRectangle(cornerRadius: side > 8 ? 4 : 8).strokeBorder(preview.allowed ? Color.green : Color.red, lineWidth: 2) }
                            .frame(width: unit, height: unit)
                            .offset(x: CGFloat(c) * (unit + gap), y: CGFloat(r) * (unit + gap))
                    }
                }
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
        // Both the touch receiver and this anchor measure UIWindow coordinates.
        .background(BerryBoardWindowAnchor(onRect: onBoardRect, tracksScrolling: side == 24))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Berry garden, \(engine.side) by \(engine.side) puzzle board")
    }
}

struct BerryGameView: View {
    let mode: BerryMode
    let onExit: () -> Void
    @AppStorage("berryblockblast.story.level") private var storyLevel = 1
    @AppStorage("berryblockblast.daily.completed") private var dailyCompleted = ""
    @State private var showVictory = false
    @State private var completedStoryChapter: Int?
    @State private var blitzRemaining = 120
    @State private var blitzWarnedTenSeconds = false
    @State private var blitzPlayedFinalTick = false
    @State private var blitzFinished = false
    @State private var blitzRunning = false
    @State private var blitzDeadline: Date?
    private var blitzVariant: BerryBlitzVariant { BerryBlitzVariant.selected }
    @State private var isPaused = false
    @Environment(\.scenePhase) private var scenePhase
    private var canManuallyPause: Bool { mode != .challenge }
    private var canMakeMove: Bool {
        guard !isPaused, !showGameOver, !showVictory, !session.gameOver else { return false }
        if mode == .challenge { return blitzRunning && (blitzDeadline.map { $0 > Date() } ?? false) }
        return true
    }
    private var goal: Int { mode == .story ? 100 + storyLevel * 55 : 120 }
    private var storyTargetLines: Int { 2 + (storyLevel / 2) }
    private var storyIsLineQuest: Bool { storyLevel % 2 == 0 }
    private var objective: String {
        switch mode {
        case .endless: "🍓 SWEET ENDLESS • SEASON \(session.engine.seasons + 1) • PLAY FOREVER!"
        case .classic: "🍓 BERRY CLASSIC • Three pieces • Chase your best!"
        case .story: storyIsLineQuest ? "CHAPTER \(storyLevel) • Clear \(storyTargetLines) lines to bloom!" : "CHAPTER \(storyLevel) • Reach \(goal) points to bloom!"
        case .daily: "DAILY HARVEST • Gather \(goal) points!"
        case .cozy: "COZY COTTAGE • \(session.cottageDecorations) decorations • Grow at your pace!"
        case .challenge: "⚡ \(blitzVariant.rawValue.uppercased()) • \(blitzRemaining)s • \(session.engine.score) points"
        case .superHard: "🍓 STRAWBERRY NIGHTMARE • 12 × 12 • Bigger pieces!"
        }
    }

    @StateObject private var session = BerryGameSession()
    @State private var boardRect: CGRect = .zero
    @State private var drag: BerryDragState?
    @State private var activeDragSlot: Int?
    @State private var activeDragFinger: CGPoint?
    @AppStorage("berryblockblast.touchDiagnostics") private var touchDiagnostics = false
    @State private var touchStatus = "Ready"
    @State private var selectedSlot: Int?
    @State private var showHelp = false
    @State private var showSettings = false
    @State private var showShop = false
    @State private var showStats = false
    @State private var showCottage = false
    @State private var confirmRestart = false
    @State private var showGameOver = false
    @State private var showWelcome = false
    @AppStorage("berryblockblast.haptics") private var haptics = true
    @AppStorage("berryblockblast.sound") private var sound = true
    @AppStorage("berryblockblast.music") private var music = true
    @State private var sparkle = false
    @State private var showNewBestBanner = false
    @State private var scoreRecordAtEntry = 0
    @State private var celebratedRecordThisRun = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("berryblockblast.strawberry-unlocked") private var strawberryUnlocked = false
    @AppStorage("berryblockblast.lifetime-lines") private var lifetimeLines = 0
    @State private var showUnlock = false
    @State private var lastBlitzTimeBonus = 0
    @AppStorage("berryblockblast.previewStyle") private var previewStyle = "ghost"
    private let harvestCheers = [
        "🍓 A berry sweet harvest!", "🍰 Piece of strawberry cake!",
        "🌸 The garden is blooming!", "✨ Sweet as sunshine!",
        "🧺 Basketful of brilliance!", "🍓 That's jam-tastic!",
        "🌿 Fresh from the berry patch!", "🎀 What a lovely little harvest!",
        "🍒 A delicious combo!", "🌷 The village is cheering!",
        "🍓 Strawberries and sparkles!", "🍰 A slice of sweet success!"
    ]
    private var harvestCheer: String {
        harvestCheers[max(0, session.celebration - 1) % harvestCheers.count]
    }
    @AppStorage("berryblockblast.welcomed.v3") private var welcomed = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let top = geo.safeAreaInsets.top
            let bottom = geo.safeAreaInsets.bottom
            let compact = height < 740
            let boardSize = max(185, min(width - 42, height - top - bottom -
                (mode == .challenge ? (compact ? 276 : 310) : (compact ? 248 : 282)), 475))
            let cell = (boardSize - CGFloat(session.engine.side - 1) * 3) / CGFloat(session.engine.side)
            ZStack {
                background
                VStack(spacing: compact ? 5 : 8) {
                    topBar(compact: compact)
                    if mode == .classic {
                        BerryClassicScoreView(score: session.engine.score, best: session.bestScore, combo: session.engine.streak)
                    } else if mode == .challenge {
                        BerryBlitzHUD(timeLeft: blitzRemaining, score: session.engine.score,
                                     best: session.bestScore, variant: blitzVariant)
                    } else {
                        scoreBar
                    }
                    HStack(spacing: 6) {
                        Image(systemName: mode == .challenge ? "bolt.fill" : mode == .cozy ? "leaf.fill" : "sparkles")
                        Text((mode == .endless || mode == .cozy) ? (session.lastMessage ?? objective) : objective)
                            .lineLimit(1).minimumScaleFactor(0.65)
                        Image(systemName: "sparkles")
                    }
                    .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .frame(height: 19)
                    if session.engine.side == 24 {
                        ScrollView([.horizontal, .vertical]) {
                            boardInteraction(actualSize: max(580, boardSize * 1.75))
                        }
                        .frame(width: boardSize + 14, height: boardSize + 14)
                        .scrollIndicators(.visible)
                        .defaultScrollAnchor(.center)
                        .background(BerryStyle.softPink, in: RoundedRectangle(cornerRadius: 24))
                        .accessibilityLabel("24 by 24 Mega Garden. Scroll to reach more cells.")
                    } else {
                        boardInteraction(actualSize: boardSize)
                    }
                    HStack(spacing: 5) {
                        Image(systemName: "hand.draw.fill")
                        Text(selectedSlot == nil ? "DRAG UP TO PLACE  •  OR TAP A PIECE" : "TAP AN EMPTY SPACE TO PLACE")
                    }
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                    .frame(height: 17)
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { slot in
                            let piece = session.engine.tray[slot]
                            ZStack {
                                RoundedRectangle(cornerRadius: 17)
                                    .fill(Color.white.opacity(0.86))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 17)
                                            .strokeBorder(selectedSlot == slot ? BerryStyle.strawberry : .white, lineWidth: selectedSlot == slot ? 3 : 1.5)
                                    }
                                    .shadow(color: BerryStyle.strawberry.opacity(0.12), radius: 5, y: 3)
                                if let piece {
                                    BerryPieceGlyph(piece: piece, unit: min(17, (width - 86) / CGFloat(3 * max(piece.width, 3)), CGFloat(compact ? 57 : 68) / CGFloat(max(piece.height, 1))), mode: mode, strawberryUnlocked: strawberryUnlocked)
                                        .opacity(activeDragSlot == slot ? 0.3 : session.engine.hasPlacement(for: piece) ? 1 : 0.3)
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(BerryStyle.leaf.opacity(0.6))
                                        .font(.title2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: compact ? 65 : 76)
                            .contentShape(Rectangle())
                            // Dedicated UIKit touch delivery persists after the finger
                            // leaves the tray and cannot conflict with board tap gestures.
                            .overlay {
                                BerryTrayTouchCapture(slot: slot) { capturedSlot, event in
                                    handleTrayTouch(slot: capturedSlot, event: event)
                                }
                            }
                            .accessibilityLabel("Berry piece \(slot + 1)")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction {
                                if canMakeMove && piece != nil {
                                    selectedSlot = selectedSlot == slot ? nil : slot
                                }
                            }
                        }
                    }
                    toolBar
                    if touchDiagnostics {
                        Text(touchStatus)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .lineLimit(2)
                            .foregroundStyle(BerryStyle.chocolate)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Text("🍓 \(session.berries) berries")
                        Spacer()
                        Text("\(session.engine.totalLines) lines • \(session.engine.moves) moves")
                    }
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.65))
                    Spacer(minLength: 0)
                }
                .disabled(isPaused)
                .padding(.horizontal, 15)
                .padding(.top, max(8, top + 3))
                .padding(.bottom, max(5, bottom))
                .frame(maxWidth: 510)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: width, height: height)
        }
        .preferredColorScheme(.light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showUnlock) {
            sheetBase("Strawberry Blocks Unlocked!", icon: "🍓") {
                Text("You cleared 10 lines! Your red blocks now grow strawberry decorations across every game mode. Plus, you earned 15 berries!")
                primaryButton("Sweet! 🍓") { showUnlock = false }
            }
        }
        .sheet(isPresented: $showHelp) { helpSheet }
        .sheet(isPresented: $showSettings) { settingsSheet }
        .sheet(isPresented: $showShop) { shopSheet }
        .sheet(isPresented: $showStats) { statsSheet }
        .sheet(isPresented: $showCottage) { cottageSheet }
        .sheet(isPresented: $showWelcome) { welcomeSheet }
        .onChange(of: scenePhase) { _, phase in
            // iOS screenshots and banners can temporarily mark the app inactive.
            // Pause overlays appear only when Pause was pressed, not on screenshots.
            if phase == .background { drag = nil; selectedSlot = nil }
            if phase == .active && mode == .challenge { refreshBlitzClock() }
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            if mode == .challenge { refreshBlitzClock() }
        }
        .onChange(of: session.gameOver) { _, ended in
            showGameOver = !showVictory && (ended || (mode == .challenge && !blitzRunning && blitzRemaining == 0))
            if ended && sound && mode != .challenge { BerryAudio.shared.play(.gameOver) }
        }
        .onAppear {
            BerryAudio.shared.setScreen(mode == .challenge ? .blitz : .gameplay)
            BerryAudio.shared.setMusic(music)
            session.selectMode(mode)
            scoreRecordAtEntry = max(session.bestScore, session.engine.score)
            celebratedRecordThisRun = false
            showNewBestBanner = false
            blitzRunning = mode == .challenge
            blitzFinished = false
            blitzWarnedTenSeconds = false
            blitzPlayedFinalTick = false
            if mode == .challenge {
                blitzRemaining = blitzVariant.seconds
                blitzDeadline = Date().addingTimeInterval(TimeInterval(blitzVariant.seconds))
                if sound { BerryAudio.shared.play(.blitzStart) }
            }
            showGameOver = session.gameOver || (mode == .challenge && blitzRemaining == 0)
            if mode == .daily && dailyCompleted == BerryGameSession.dailyDateKey() { showVictory = session.engine.score >= goal }
            if !welcomed { showWelcome = true }
        }
        .onChange(of: session.engine.score) { _, score in
            checkObjective()
            celebrateNewRecordIfNeeded(score)
        }
        .onChange(of: session.engine.totalLines) { _, _ in checkObjective() }
        .onChange(of: showSettings) { _, _ in if mode == .challenge { refreshBlitzClock() } }
        .onChange(of: showVictory) { _, victory in
            BerryAudio.shared.setScreen(victory ? .results : (mode == .challenge ? .blitz : .gameplay))
            if victory && sound { BerryAudio.shared.play(.victory) }
        }
        .overlay {
            if isPaused && !showVictory && !showGameOver {
                ZStack {
                    BerryStyle.chocolate.opacity(0.54).ignoresSafeArea()
                    VStack(spacing: 18) {
                        Text("🍓 🌸 🫖").font(.system(size: 44))
                        Text("A Little Berry Break").font(.system(size: 27, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                        Text("Your garden is safely waiting. Take all the time you need!")
                            .multilineTextAlignment(.center).foregroundStyle(BerryStyle.chocolate)
                        Text("🍓 \(session.berries) berries • \(session.engine.score) points")
                            .font(.subheadline.bold()).foregroundStyle(BerryStyle.leaf)
                        Button("Continue Gardening") { isPaused = false }
                            .buttonStyle(.borderedProminent).tint(BerryStyle.strawberry).controlSize(.large)
                        Button(mode == .endless ? "Save Forever Garden & Return" : "Return to Village") { isPaused = false; onExit() }
                            .foregroundStyle(BerryStyle.leaf).fontWeight(.bold)
                    }
                    .padding(26).frame(maxWidth: 350)
                    .background(LinearGradient(colors: [BerryStyle.cream, Color(red: 1, green: 0.84, blue: 0.89)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 28))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white, lineWidth: 3))
                    .padding(22)
                }
            }
        }
        .overlay {
            if showVictory || showGameOver || confirmRestart {
                ZStack {
                    BerryStyle.chocolate.opacity(0.42).ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text(showVictory ? "🍰 ✨ 🍓" : confirmRestart ? "🌱 🍓 🌱" : "🍓 🌸 🧺")
                            .font(.system(size: 38))
                        Text(showVictory ? "Strawberry Spectacular!" : confirmRestart ? "Plant a Fresh Garden?" :
                             mode == .challenge ? "Time's Up, Berry Racer!" : "Our Berry Patch Is Full!")
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry).multilineTextAlignment(.center)
                        Text(showVictory ? (mode == .story ? "Chapter \(completedStoryChapter ?? max(1, storyLevel - 1)) complete! Your next chapter is ready." : "Your strawberry star has blossomed!") : confirmRestart ? "Your best score and earned berries stay safe." : "You harvested \(session.engine.score) sweet points and cleared \(session.engine.totalLines) lines. Every garden deserves another season!")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate).multilineTextAlignment(.center)
                        Button(showVictory ? "🍓 Another Sweet Adventure" : mode == .challenge ? "⚡ Race Again" : "🍓 Plant a Fresh Garden") {
                            showVictory = false; showGameOver = false; confirmRestart = false
                            completedStoryChapter = nil; session.newGame(); selectedSlot = nil; drag = nil
                            blitzRemaining = blitzVariant.seconds; blitzRunning = mode == .challenge
                            blitzDeadline = mode == .challenge ?
                                Date().addingTimeInterval(TimeInterval(blitzVariant.seconds)) : nil
                            blitzFinished = false; blitzWarnedTenSeconds = false; blitzPlayedFinalTick = false
                            if mode == .challenge && sound { BerryAudio.shared.play(.blitzStart) }
                            celebratedRecordThisRun = false; scoreRecordAtEntry = session.bestScore
                            showNewBestBanner = false
                        }.buttonStyle(.borderedProminent).tint(BerryStyle.strawberry).controlSize(.large)
                        Button("🏡 Return to Strawberry Village") { returnToVillage() }
                            .foregroundStyle(BerryStyle.leaf).fontWeight(.bold)
                        if showGameOver && session.shuffles > 0 && mode != .classic && mode != .challenge {
                            Button("✨ Use Shuffle (\(session.shuffles) left)") { session.shuffle(); showGameOver = session.gameOver; selectedSlot = nil; drag = nil }
                                .foregroundStyle(BerryStyle.strawberry)
                        }
                        if confirmRestart {
                            Button("Keep Playing") { confirmRestart = false }.foregroundStyle(BerryStyle.chocolate)
                        }
                    }
                    .padding(25).frame(maxWidth: 350)
                    .background(
                        LinearGradient(colors: [BerryStyle.cream, Color(red: 1, green: 0.85, blue: 0.9)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 30))
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white, lineWidth: 3))
                    .shadow(color: BerryStyle.strawberry.opacity(0.28), radius: 22, y: 12)
                    .padding(22)
                }.transition(.opacity)
            }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: mode == .cozy ? [Color(red: 0.88, green: 0.96, blue: 0.84), BerryStyle.cream, Color(red: 1, green: 0.86, blue: 0.87)] : mode == .challenge ? [Color(red: 1, green: 0.79, blue: 0.84), Color(red: 1, green: 0.95, blue: 0.77), Color(red: 0.98, green: 0.73, blue: 0.8)] : mode == .story ? [Color(red: 0.94, green: 0.83, blue: 1), BerryStyle.cream, Color(red: 1, green: 0.83, blue: 0.91)] : [Color(red: 1, green: 0.85, blue: 0.9), Color(red: 1, green: 0.96, blue: 0.87), Color(red: 1, green: 0.8, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
            GeometryReader { geo in
                Circle().fill(.white.opacity(0.34)).frame(width: geo.size.width * 0.85).offset(x: -geo.size.width * 0.35, y: -geo.size.height * 0.13)
                Circle().fill(BerryStyle.strawberry.opacity(0.06)).frame(width: 270).offset(x: geo.size.width - 170, y: geo.size.height * 0.62)
                VStack {
                    HStack { Text("✿"); Spacer(); Text("🍓") }
                    Spacer()
                    HStack { Text("🍃"); Spacer(); Text("✿") }
                }
                .font(.system(size: 31))
                .opacity(0.28)
                .padding(15)
            }
        }.ignoresSafeArea()
    }

    private func topBar(compact: Bool) -> some View {
        HStack(spacing: 8) {
            BerryGirlView().frame(width: compact ? 45 : 54, height: compact ? 45 : 54).clipped()
            VStack(alignment: .leading, spacing: 0) {
                Text("STRAWBERRY SWEET").font(.system(size: 8, weight: .black, design: .rounded)).tracking(1.7).foregroundStyle(BerryStyle.leaf)
                Text("Berry Block Blast!").font(.system(size: compact ? 20 : 23, weight: .black, design: .rounded)).lineLimit(1).minimumScaleFactor(0.6).foregroundStyle(BerryStyle.strawberry)
                Text(mode == .endless ? "THE ENDLESS BERRY GARDEN" : mode.rawValue.uppercased()).font(.system(size: 8, weight: .bold, design: .rounded)).tracking(0.7).foregroundStyle(BerryStyle.chocolate.opacity(0.7))
            }
            Spacer(minLength: 0)
            if canManuallyPause {
                Button { isPaused = true; drag = nil; selectedSlot = nil } label: {
                    Image(systemName: "pause.circle.fill").font(.system(size: 23)).foregroundStyle(BerryStyle.strawberry)
                }.accessibilityLabel("Pause game")
            }
            Button { returnToVillage() } label: { Image(systemName: "house.fill").font(.system(size: 20)).foregroundStyle(BerryStyle.leaf) }.accessibilityLabel("Main menu")
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.system(size: 20)).foregroundStyle(BerryStyle.strawberry)
            }.accessibilityLabel("Berry settings")
            Button { showHelp = true } label: {
                Image(systemName: "questionmark.circle.fill").font(.system(size: 23)).foregroundStyle(BerryStyle.strawberry)
            }.accessibilityLabel("How to play")
        }
        .frame(height: compact ? 48 : 56)
    }

    private var scoreBar: some View {
        HStack(spacing: 8) {
            scorePill("SCORE", value: session.engine.score, icon: "heart.fill")
            scorePill("BEST", value: session.bestScore, icon: "crown.fill")
            HStack(spacing: 3) {
                Text("🍓").font(.system(size: 18))
                VStack(alignment: .leading, spacing: 0) {
                    Text("COMBO").font(.system(size: 8, weight: .heavy))
                    Text("×\(max(1, session.engine.streak))").font(.system(size: 19, weight: .black, design: .rounded))
                }
            }
            .foregroundStyle(BerryStyle.chocolate)
            .frame(width: 80, height: 51)
            .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 15))
        }
    }

    private func scorePill(_ title: String, value: Int, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(title == "BEST" ? .orange : BerryStyle.strawberry)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.system(size: 8, weight: .heavy, design: .rounded)).foregroundStyle(BerryStyle.chocolate.opacity(0.65))
                Text(value.formatted()).font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(BerryStyle.chocolate).lineLimit(1).minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity)
        .frame(height: 51)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 15))
    }

    private var toolBar: some View {
        HStack(spacing: 7) {
            if mode != .classic && mode != .challenge {
            toolButton("Undo", icon: "arrow.uturn.backward", count: session.undos, enabled: session.canUndo) {
                if session.canUndo {
                    let revertedLines = session.undo()
                    lifetimeLines = max(0, lifetimeLines - revertedLines)
                    if mode == .challenge && lastBlitzTimeBonus > 0 {
                        blitzDeadline = blitzDeadline?.addingTimeInterval(TimeInterval(-lastBlitzTimeBonus))
                        // No saved Blitz timer. This challenge restarts on re-entry.
                        lastBlitzTimeBonus = 0
                        refreshBlitzClock()
                    }
                    selectedSlot = nil; drag = nil
                } else { showShop = true }
            }
            toolButton("Shuffle", icon: "shuffle", count: session.shuffles, enabled: session.shuffles > 0) {
                if session.shuffles > 0 { session.shuffle(); selectedSlot = nil; drag = nil } else { showShop = true }
            }
            toolButton("Shop", icon: "basket.fill", count: nil, enabled: true) { showShop = true }
            }
            toolButton(mode == .cozy ? "Cottage" : "Stats", icon: mode == .cozy ? "house.lodge.fill" : "chart.bar.fill", count: nil, enabled: true) { if mode == .cozy { showCottage = true } else { showStats = true } }
            toolButton("Home", icon: "house.fill", count: nil, enabled: true) { returnToVillage() }
        }.frame(height: 43)
    }

    private func toolButton(_ title: String, icon: String, count: Int?, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                HStack(spacing: 2) {
                    Image(systemName: icon).font(.system(size: 13, weight: .bold))
                    if let count { Text("\(count)").font(.system(size: 10, weight: .heavy)) }
                }
                Text(title).font(.system(size: 9, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(enabled ? BerryStyle.strawberry : Color.gray)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 12))
        }.disabled(!enabled && count == nil)
    }

    // Both board measurement and touch events use UIWindow coordinates.
    // A lifted preview matches the original thumb interaction; direct-finger
    // targeting is accepted as a fallback when it is the legal position.
    private func placementForDrag(slot: Int, finger: CGPoint) -> BerryDragState? {
        guard canMakeMove, session.engine.tray.indices.contains(slot),
              let piece = session.engine.tray[slot] else { return nil }
        let candidates = BerryDropGeometry.candidates(
            for: finger, board: boardRect, piece: piece, side: session.engine.side
        )
        let target = candidates.first {
            session.engine.canPlace(piece, row: $0.row, col: $0.col)
        } ?? candidates.first
        guard let target else { return nil }
        return BerryDragState(
            slot: slot, piece: piece, row: target.row, col: target.col,
            allowed: session.engine.canPlace(piece, row: target.row, col: target.col)
        )
    }

    private func handleTrayTouch(slot: Int, event: BerryTouchEvent) {
        guard canMakeMove, session.engine.tray.indices.contains(slot),
              session.engine.tray[slot] != nil else {
            activeDragSlot = nil
            activeDragFinger = nil
            drag = nil
            return
        }
        switch event.phase {
        case .began:
            touchStatus = "Picked up piece \(slot + 1)"
        case .moved:
            guard event.distanceSquared >= 64 else { return }
            if activeDragSlot != slot && sound { BerryAudio.shared.play(.pickup) }
            activeDragSlot = slot
            activeDragFinger = event.location
            drag = placementForDrag(slot: slot, finger: event.location)
            if let drag {
                touchStatus = "Preview (\(drag.row), \(drag.col)) \(drag.allowed ? "legal" : "blocked")"
            } else {
                touchStatus = "Moving piece \(slot + 1) toward board"
            }
        case .ended:
            if event.distanceSquared < 64 {
                selectedSlot = selectedSlot == slot ? nil : slot
                touchStatus = "Selected piece \(slot + 1) for tap placement"
            } else {
                let finalDrop = placementForDrag(slot: slot, finger: event.location)
                touchStatus = finalDrop.map {
                    "Released (\($0.row), \($0.col)) \($0.allowed ? "legal" : "blocked")"
                } ?? "Released outside board"
                finishDrag(finalDrop)
            }
            activeDragSlot = nil
            activeDragFinger = nil
            drag = nil
        case .cancelled:
            touchStatus = "Touch cancelled"
            activeDragSlot = nil
            activeDragFinger = nil
            drag = nil
        }
    }

    private func finishDrag(_ finalDrop: BerryDragState?) {
        defer { drag = nil }
        guard canMakeMove, let finalDrop else {
            #if DEBUG
            print("[BerryDrag] Release had no board target (boardRect=\(boardRect)).")
            #endif
            refreshBlitzClock()
            return
        }
        guard finalDrop.allowed else {
            #if DEBUG
            print("[BerryDrag] Invalid placement: row=\(finalDrop.row), col=\(finalDrop.col).")
            #endif
            warningFeedback()
            return
        }
        if session.drop(slot: finalDrop.slot, row: finalDrop.row, col: finalDrop.col) {
            selectedSlot = nil
            successFeedback()
        } else {
            warningFeedback()
        }
    }

    /// Identical drag and tap board to the physically verified 0.5.6 engine.
    /// Only the 24x24 view enlarges and scrolls.
    private func boardInteraction(actualSize: CGFloat) -> some View {
            BerryBoard(engine: session.engine, preview: drag, size: actualSize, selected: selectedSlot, mode: mode, strawberryUnlocked: strawberryUnlocked, previewStyle: previewStyle, onBoardRect: { rect in boardRect = rect })
                .overlay {
                    if sparkle {
                        Text(harvestCheer)
                            .font(.headline)
                            .foregroundStyle(BerryStyle.strawberry)
                            .padding(12)
                            .background(.regularMaterial, in: Capsule())
                            .transition(.scale.combined(with: .opacity))
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    if showNewBestBanner {
                        BerryNewBestBanner(score: session.engine.score)
                            .transition(.scale(scale: 0.78).combined(with: .opacity))
                            .allowsHitTesting(false)
                            .zIndex(3)
                    }
                }
                .padding(7)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard canMakeMove, let slot = selectedSlot,
                          session.engine.tray.indices.contains(slot),
                          let piece = session.engine.tray[slot] else { return }
                    // Tap coordinates are local to the 7-point padded board wrapper.
                    // Resolve using the same cell-origin logic as drag placement.
                    let local = CGPoint(x: location.x - 7, y: location.y - 7)
                    let area = CGRect(origin: .zero, size: CGSize(width: actualSize, height: actualSize))
                    guard let target = BerryDropGeometry.target(
                        for: local, board: area, piece: piece, side: session.engine.side
                    ) else {
                        warningFeedback()
                        return
                    }
                    if session.drop(slot: slot, row: target.row, col: target.col) {
                        selectedSlot = nil
                        successFeedback()
                    } else {
                        warningFeedback()
                    }
                }
    }

    private func refreshBlitzClock() {
        guard mode == .challenge, blitzRunning, let deadline = blitzDeadline,
              !showVictory else { return }
        blitzRemaining = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
        if blitzRemaining <= 10 && blitzRemaining > 0 && !blitzWarnedTenSeconds {
            blitzWarnedTenSeconds = true
            if sound { BerryAudio.shared.play(.tenSeconds) }
        }
        // Uploaded final countdown WAV lasts two full seconds; fire ONCE.
        if blitzRemaining <= 3 && blitzRemaining > 0 && !blitzPlayedFinalTick {
            blitzPlayedFinalTick = true
            if sound { BerryAudio.shared.play(.countdown) }
        }
        if blitzRemaining == 0 && !blitzFinished {
            blitzFinished = true
            blitzRunning = false
            showGameOver = true
            drag = nil
            selectedSlot = nil
            if sound { BerryAudio.shared.play(.timeUp) }
        }
    }
    private func checkObjective() {
        guard !showVictory, !showGameOver else { return }
        if mode == .challenge {
            guard let deadline = blitzDeadline, deadline > Date() else {
                refreshBlitzClock()
                return
            }
        }
        let completed: Bool
        switch mode {
        case .story: completed = storyIsLineQuest ? session.engine.totalLines >= storyTargetLines : session.engine.score >= goal
        case .daily: completed = session.engine.score >= goal
        case .challenge: completed = false // Timed score chase, no early win.
        case .superHard: completed = false
        default: completed = false
        }
        guard completed else { return }
        if mode == .story { completedStoryChapter = storyLevel; session.rewardStory(storyLevel); storyLevel += 1 }
        if mode == .daily { session.rewardDaily(); dailyCompleted = BerryGameSession.dailyDateKey() }
        blitzRunning = false
        showVictory = true
    }
    private func celebrateNewRecordIfNeeded(_ score: Int) {
        // A tiny score on a fresh run should not fill the screen with banners.
        // Once a genuine record is passed, it is celebrated once per run.
        guard !celebratedRecordThisRun, score > scoreRecordAtEntry,
              score >= 20 else { return }
        celebratedRecordThisRun = true
        if sound { BerryAudio.shared.play(.highScore) }
        BerryAudio.shared.duckForCelebration(duration: 1.6)
        withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.7)) {
            showNewBestBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) {
                showNewBestBanner = false
            }
        }
    }

    private func returnToVillage() {
        if sound { BerryAudio.shared.play(.menuBack) }
        onExit()
    }

    private func successFeedback() {
        lifetimeLines += session.lastClearedLines
        // Genuine play milestones build longer-term progression without
        // introducing yet another top-level mode.
        for (lines, reward) in [(25, 15), (50, 30), (100, 60)] {
            if lifetimeLines >= lines {
                session.awardOnce("lifetime-lines-\(lines)", amount: reward,
                                  reason: "Garden milestone: \(lines) lines")
            }
        }
        if lifetimeLines >= 10 && !strawberryUnlocked {
            strawberryUnlocked = true
            showUnlock = true
            session.awardOnce("strawberry-unlock", amount: 15, reason: "Strawberry blocks unlocked")
        }
        // Fixed time: no extensions for clears.
        lastBlitzTimeBonus = 0
        if haptics { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        if sound {
            let cue: BerryAudio.Cue = session.lastClearedLines > 0 ?
                (session.engine.streak > 1 ? .combo : .clear) : .place
            BerryAudio.shared.play(cue)
        }
        if session.lastEarned > 10 {
            withAnimation(.spring()) { sparkle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { withAnimation { sparkle = false } }
        }
    }
    private func warningFeedback() {
        if haptics { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        if sound { BerryAudio.shared.play(.invalid) }
    }

    private var welcomeSheet: some View {
        sheetBase("Welcome to Strawberry Village!", icon: "🍓") {
            Text("Make the sweetest garden one block at a time. Place berry pieces, complete rows and columns, and earn strawberries to stock your basket.")
            Text("Complete full lines and make combos. Berry Classic is your single resumable garden.")
            primaryButton("Let's Grow!") { welcomed = true; showWelcome = false }
        }
    }
    private var helpSheet: some View {
        sheetBase("How to Play", icon: "🍰") {
            Text("Touch a piece and slide it onto the \(session.engine.side) × \(session.engine.side) board, then release. Or tap a piece and tap the board to place it. Complete full rows or columns to clear them.")
            Text("Clear multiple lines together for bonus points. Keep clearing to grow your combo. Clear the entire board for +300!")
            if mode == .classic {
                Text("Berry Classic uses three shapes at a time, with no timer, Undo or Shuffle. Build combos, clear rows or columns, and chase your personal record!")
            } else {
                Text("Earn strawberries for line clears. Spend them in the basket on extra Undos and Shuffles. Keep playing until nothing fits.")
            }
            primaryButton("Got It!") { showHelp = false }
        }
    }
    private var settingsSheet: some View {
        sheetBase("Berry Settings", icon: "⚙️") {
            Picker("🍓 Placement Preview", selection: $previewStyle) {
                Text("Sweet Assist").tag("ghost")
                Text("Outline Only").tag("outline")
                Text("Mystery Garden").tag("mystery")
            }
            Toggle("Haptic feedback", isOn: $haptics).tint(BerryStyle.strawberry)
            Toggle("Touch diagnostics (testing)", isOn: $touchDiagnostics).tint(BerryStyle.strawberry)
            if touchDiagnostics {
                Text("A small status line appears below your tools for testing drag releases.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            BerryMusicSettingsView()
            Text(mode == .endless ?
                "Sweet Endless saves this garden and your score automatically. When there are no moves, a new season begins without resetting your score." :
                "Scores, strawberries and rewards are saved. Only Sweet Endless resumes a live board.")
                .font(.footnote)
            Button("Start a New Garden", role: .destructive) { showSettings = false; confirmRestart = true }
            Text("🍓 v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev") • build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")").font(.footnote).foregroundStyle(.secondary)
            primaryButton("Done") { showSettings = false }
        }
    }
    private var shopSheet: some View {
        sheetBase("The Berry Boutique", icon: "🧺") {
            BerryBoutiqueView(session: session)
            primaryButton("Back to Your Berry Garden") { showShop = false }
        }
    }

    private var cottageSheet: some View {
        let completed = session.cottageDecorations
        let upgrades = ["Berry Flowerbed 🌸", "Strawberry Garden Gate 🍓",
                        "Jam Market Stall 🧺", "Village Fountain ⛲",
                        "Rose Trellis 🌹", "Cottage Bakery 🍰"]
        return sheetBase("My Strawberry Cottage", icon: "🏡") {
            Text("Your little cottage becomes a sweeter home with every decoration.")
                .multilineTextAlignment(.center)
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: [Color(red: 0.87, green: 0.97, blue: 0.83),
                        Color(red: 1, green: 0.88, blue: 0.91)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack(spacing: 7) {
                    Text(completed >= 4 ? "☀️    🌺   ⛲   🌺    ☁️" : "☀️    🌸    ☁️")
                        .font(.system(size: 23))
                    Text("🏡")
                        .font(.system(size: 94))
                        .shadow(color: BerryStyle.strawberry.opacity(0.25), radius: 9, y: 5)
                    HStack(spacing: 8) {
                        if completed >= 1 { Text("🌷") }
                        if completed >= 2 { Text("🍓") }
                        if completed >= 3 { Text("🧺") }
                        if completed >= 5 { Text("🌹") }
                        if completed >= 6 { Text("🍰") }
                    }
                    .font(.system(size: 27))
                    Text(completed >= 6 ? "✨ THE SWEETEST COTTAGE ✨" :
                        "🌿 A garden still growing 🌿")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.leaf)
                }
            }.frame(height: 256)
            Text("🍓 \(completed) decorations collected")
                .font(.headline)
                .foregroundStyle(BerryStyle.leaf)
            ForEach(0..<upgrades.count, id: \.self) { index in
                HStack {
                    Image(systemName: completed > index ? "checkmark.seal.fill" : "lock.fill")
                        .foregroundStyle(completed > index ? BerryStyle.leaf : .gray)
                    Text(upgrades[index])
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate)
                    Spacer()
                    if completed > index { Text("Owned").font(.caption).foregroundStyle(BerryStyle.leaf) }
                }
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
            }
            Button(completed < upgrades.count ?
                   "Decorate: \(upgrades[completed]) • 🍓 50" :
                   "Add another garden bouquet • 🍓 50") {
                session.buyCottageDecoration()
                if sound { BerryAudio.shared.play(.reward) }
            }
            .disabled(session.berries < 50 || session.cottageDecorations >= 6)
            .buttonStyle(.borderedProminent)
            .tint(BerryStyle.strawberry)
            Text("Your strawberry basket: 🍓 \(session.berries)")
                .font(.caption)
            primaryButton("Back to the Garden") { showCottage = false }
        }
    }

    private var statsSheet: some View {
        sheetBase("Berry Scrapbook", icon: "📖") {
            statRow("Best score", "\(session.bestScore)")
            statRow("Current score", "\(session.engine.score)")
            statRow("Lines cleared", "\(session.engine.totalLines)")
            statRow("Moves", "\(session.engine.moves)")
            statRow("Best combo", "×\(session.engine.bestCombo)")
            statRow("Perfect gardens", "\(session.engine.boardClears)")
            statRow("Berries earned", "\(session.totalEarnedBerries)")
            statRow("Cottage decorations", "\(session.cottageDecorations)")
            primaryButton("Keep Playing") { showStats = false }
        }
    }
    private func statRow(_ name: String, _ value: String) -> some View {
        HStack { Text(name); Spacer(); Text(value).bold().foregroundStyle(BerryStyle.strawberry) }
    }
    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action).buttonStyle(.borderedProminent).tint(BerryStyle.strawberry).controlSize(.large)
    }
    private func sheetBase<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 17) {
                Text(icon).font(.system(size: 49))
                Text(title).font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(BerryStyle.strawberry)
                content()
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(BerryStyle.chocolate)
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 52)
            .frame(maxWidth: .infinity)
        }
        .background(LinearGradient(colors: [BerryStyle.cream, Color(red: 1, green: 0.85, blue: 0.90), Color(red: 0.91, green: 0.97, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
