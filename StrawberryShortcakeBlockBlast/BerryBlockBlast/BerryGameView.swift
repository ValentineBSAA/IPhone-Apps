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
    @AppStorage("berryberryblast.board.surface.v059") private var boardSurface = "cream"
    private var boardCellArt: String {
        switch boardSurface {
        case "glass": return "BerryBoardCandyGlassCell"
        case "picnic": return "BerryBoardPicnicCell"
        case "garden": return "BerryBoardGardenCell"
        case "seed": return "BerryBoardSeedMosaicCell"
        default: return "BerryBoardCreamCell"
        }
    }
    private let gap: CGFloat = 3
    private var gardenBorder: Color {
        switch borderSkin {
        case "rose-border": return Color(red: 0.91, green: 0.25, blue: 0.55)
        case "mint-border": return Color(red: 0.32, green: 0.73, blue: 0.58)
        default: return Color(red: 0.98, green: 0.71, blue: 0.79)
        }
    }

    var body: some View {
        let side = engine.visibleSide
        let origin = engine.sectionOrigin
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
                        .fill(LinearGradient(colors: [
                            .white.opacity(0.98),
                            Color(red: 1, green: 0.90, blue: 0.94),
                            Color(red: 0.99, green: 0.81, blue: 0.87)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay {
                            RoundedRectangle(cornerRadius: side > 8 ? 4 : 8)
                                .strokeBorder(Color(red: 0.91, green: 0.54, blue: 0.68).opacity(0.5),
                                              lineWidth: max(0.75, unit * 0.035))
                        }
                        .overlay(alignment: .topLeading) {
                            Circle().fill(.white.opacity(0.72))
                                .frame(width: max(2, unit * 0.14), height: max(2, unit * 0.14))
                                .padding(.top, unit * 0.12)
                                .padding(.leading, unit * 0.13)
                        }
                        .overlay {
                            if UIImage(named: boardCellArt) != nil {
                                Image(boardCellArt)
                                    .resizable()
                                    .interpolation(.high)
                                    .scaledToFit()
                                    .frame(width: unit, height: unit)
                                    .opacity(0.73)
                            }
                        }
                    if let tint = engine.visibleCell(row: r, col: c) {
                        let blocked = preview?.piece.points.contains(where: {
                            preview!.row + $0.row == r + origin.row &&
                            preview!.col + $0.col == c + origin.col
                        }) ?? false
                        BerryTile(tint: tint, mode: mode, strawberryUnlocked: strawberryUnlocked)
                            .opacity(blocked && !((preview?.allowed) ?? true) ? 0.24 : 1)
                    }
                }
                .frame(width: unit, height: unit)
                .offset(x: CGFloat(c) * (unit + gap), y: CGFloat(r) * (unit + gap))
            }
            if let preview, previewStyle != "mystery" {
                ForEach(preview.piece.points, id: \.self) { p in
                    let r = preview.row + p.row - origin.row
                    let c = preview.col + p.col - origin.col
                    if (0..<side).contains(r), (0..<side).contains(c) {
                        let occupied = engine.visibleCell(row: r, col: c) != nil
                        ZStack {
                            if preview.allowed {
                                BerryTile(tint: preview.piece.tint, preview: true,
                                          mode: mode, strawberryUnlocked: strawberryUnlocked)
                                    .opacity(previewStyle == "outline" ? 0.33 : 0.80)
                            } else {
                                RoundedRectangle(cornerRadius: side > 8 ? 4 : 8)
                                    .fill(Color.red.opacity(occupied ? 0.28 : 0.12))
                                if occupied {
                                    Image(systemName: "xmark")
                                        .font(.system(size: max(8, unit * 0.30), weight: .black))
                                        .foregroundStyle(Color(red: 0.72, green: 0.07, blue: 0.22))
                                }
                            }
                        }
                            .overlay {
                                RoundedRectangle(cornerRadius: side > 8 ? 4 : 8)
                                    .strokeBorder(preview.allowed ? Color.green : Color.red,
                                                  lineWidth: preview.allowed ? 2 : 2.8)
                            }
                            .frame(width: unit, height: unit)
                            .offset(x: CGFloat(c) * (unit + gap), y: CGFloat(r) * (unit + gap))
                    }
                }
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .overlay {
            if let preview, !preview.allowed,
               preview.piece.points.contains(where: {
                   !(0..<engine.side).contains(preview.row + $0.row) ||
                   !(0..<engine.side).contains(preview.col + $0.col)
               }) {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(Color.red.opacity(0.82), lineWidth: 3)
                    .overlay(alignment: .top) {
                        Text("Outside the garden")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(6).background(.white, in: Capsule())
                            .foregroundStyle(Color.red)
                    }
                    .allowsHitTesting(false)
            }
        }
        // Both the touch receiver and this anchor measure UIWindow coordinates.
        .background(BerryBoardWindowAnchor(onRect: onBoardRect, tracksScrolling: false))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Berry garden, \(engine.side) by \(engine.side) puzzle board")
    }
}

/// UIKit geometry changes while the 24×24 garden scrolls are stored in a
/// reference object, not @State, preventing 576 SwiftUI cells from rebuilding
/// for every subpixel of movement or transient notification safe-area change.
private final class BerryBoardPositionCache {
    var rect: CGRect = .zero
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
    @State private var pausedTimerAt: Date?
    @State private var storyMessage: String?
    @State private var storyMessageGeneration = 0
    private var blitzVariant: BerryBlitzVariant { BerryBlitzVariant.selected }
    private var isTimedMode: Bool { mode == .challenge || mode == .superHard }
    private var timedDuration: Int { mode == .superHard ? 180 : blitzVariant.seconds }
    @State private var isPaused = false
    @Environment(\.scenePhase) private var scenePhase
    private var canManuallyPause: Bool { true }
    private var canMakeMove: Bool {
        guard !isPaused, !showGameOver, !showVictory, !session.gameOver else { return false }
        if isTimedMode { return blitzRunning && (blitzDeadline.map { $0 > Date() } ?? false) }
        return true
    }
    private var goal: Int { mode == .story ? 100 + storyLevel * 55 : 120 }
    private var storyTargetLines: Int { 2 + (storyLevel / 2) }
    private var storyIsLineQuest: Bool { storyLevel % 2 == 0 }
    private var objective: String {
        switch mode {
        case .endless:
            let seasonNames = ["Spring Bloom", "Summer Berries", "Autumn Honey", "Winter Frost"]
            return "🍓 \(session.engine.side)×\(session.engine.side) • SEASON \(session.engine.seasons + 1): \(seasonNames[session.engine.seasons % 4])"
        case .classic: return "🍓 BERRY CLASSIC • Three pieces • Chase your best!"
        case .story: return storyIsLineQuest ? "CHAPTER \(storyLevel) • Clear \(storyTargetLines) lines to bloom!" : "CHAPTER \(storyLevel) • Reach \(goal) points to bloom!"
        case .daily: return "DAILY HARVEST • \(BerryGameSession.dailyDateKey()) • Gather \(goal) points!"
        case .cozy: return "COZY COTTAGE • \(session.cottageDecorations) decorations • Grow at your pace!"
        case .challenge: return "⚡ \(blitzVariant.rawValue.uppercased()) • \(blitzRemaining)s • \(session.engine.score) points"
        case .superHard: return "🌙 NIGHTMARE • 12 × 12 • \(blitzRemaining)s remaining"
        }
    }

    @StateObject private var session = BerryGameSession()
    @State private var boardPosition = BerryBoardPositionCache()
    @State private var stableBoardSize: CGFloat?
    @State private var drag: BerryDragState?
    @State private var hintPreview: BerryDragState?
    @State private var hintSerial = 0
    @State private var strawberryRain = false
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
    @State private var showDailyCalendar = false
    @State private var showPremiumActions = false
    @State private var confirmGoldenStrawberry = false
    @State private var specialTargetTool: String? = nil
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
    @AppStorage("berryberryblast.board.surface.v059") private var boardSurface = "cream"
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
            let fittedBoardSize = max(185, min(width - 42, height - top - bottom -
                (isTimedMode ? (compact ? 276 : 310) : (compact ? 248 : 282)) -
                (mode == .story ? 42 : 0), 475))
            let boardSize = stableBoardSize ?? fittedBoardSize
            ZStack {
                background
                VStack(spacing: compact ? 5 : 8) {
                    topBar(compact: compact)
                    if mode == .classic {
                        BerryClassicScoreView(score: session.engine.score, best: session.bestScore, combo: session.engine.streak)
                    } else if mode == .challenge {
                        BerryBlitzHUD(timeLeft: blitzRemaining, score: session.engine.score,
                                     best: session.bestScore, variant: blitzVariant)
                    } else if mode == .superHard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🌙 STRAWBERRY NIGHTMARE")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                Text(String(format: "%01d:%02d", blitzRemaining / 60, blitzRemaining % 60))
                                    .font(.system(size: 35, weight: .black, design: .rounded))
                                    .monospacedDigit()
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("SCORE").font(.caption.bold())
                                Text(session.engine.score.formatted()).font(.title.bold())
                                Text("BEST \(session.bestScore)").font(.caption.bold())
                            }
                        }
                        .foregroundStyle(Color(red: 0.49, green: 0.09, blue: 0.35))
                        .padding(13)
                        .frame(height: 87)
                        .background(Color(red: 0.98, green: 0.86, blue: 0.94), in: RoundedRectangle(cornerRadius: 21))
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
                    if mode == .endless && session.engine.side == 24 {
                        endlessSectionHUD
                    }
                    if mode == .story {
                        storyProgressCard
                    }
                    if mode == .daily {
                        Button {
                            showDailyCalendar = true
                        } label: {
                            HStack(spacing: 6) {
                                BerryIcon(name: "DailyHarvest", size: 26)
                                Text("Today's Harvest • Calendar & Streak")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(BerryStyle.chocolate)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(.white.opacity(0.87), in: Capsule())
                        }.buttonStyle(.plain)
                    }
                    if mode == .endless && session.engine.side == 24 {
                        boardInteraction(actualSize: boardSize)
                            .id(session.engine.activeGardenSection)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.26),
                                       value: session.engine.activeGardenSection)
                            .accessibilityLabel("Mega Garden, section \(session.engine.activeGardenSection + 1) of 4. This section changes automatically.")
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
                                    Text("\(piece.points.count)")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundStyle(BerryStyle.strawberry)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(.white.opacity(0.95), in: Capsule())
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                        .padding(5)
                                        .allowsHitTesting(false)
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
                        BerryWalletPill(berries: session.berries)
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
                if let slot = activeDragSlot,
                   drag == nil,
                   let finger = activeDragFinger,
                   session.engine.tray.indices.contains(slot),
                   let piece = session.engine.tray[slot] {
                    BerryPieceGlyph(piece: piece, unit: min(28, 90 / CGFloat(max(piece.width, piece.height))),
                                    mode: mode, strawberryUnlocked: strawberryUnlocked)
                        .opacity(0.79)
                        .shadow(color: BerryStyle.strawberry.opacity(0.3), radius: 9, y: 3)
                        .position(x: finger.x - geo.frame(in: .global).minX,
                                  y: finger.y - geo.frame(in: .global).minY - 58)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            // Screen-space celebrations never follow garden section changes.
            // Incoming notifications cannot move these banners.
            if sparkle {
                Text(harvestCheer)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                    .padding(13)
                    .background(.regularMaterial, in: Capsule())
                    .position(x: width / 2, y: height * 0.43)
                    .allowsHitTesting(false)
            }
            if showNewBestBanner {
                BerryNewBestBanner(score: session.engine.score)
                    .frame(maxWidth: min(310, width - 30))
                    .position(x: width / 2, y: height * 0.36)
                    .allowsHitTesting(false)
                    .zIndex(9)
            }
            }
            .frame(width: width, height: height)
            .onAppear {
                if stableBoardSize == nil { stableBoardSize = fittedBoardSize }
            }
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
        .sheet(isPresented: $showDailyCalendar) { BerryDailyHarvestView(goal: goal) }
        .confirmationDialog("Special Tools", isPresented: $showPremiumActions,
                            titleVisibility: .visible) {
            Button("Golden Trowel · \(session.premiumCharges["trowel", default: 0]) left") {
                specialTargetTool = "trowel"
            }
            .disabled(session.premiumCharges["trowel", default: 0] < 1)
            Button("Starberry Seed · \(session.premiumCharges["seed", default: 0]) left") {
                specialTargetTool = "seed"
            }
            .disabled(session.premiumCharges["seed", default: 0] < 1)
            Button("✨ Golden Strawberry · \(session.premiumCharges["golden-strawberry", default: 0]) left") {
                confirmGoldenStrawberry = true
            }
            .disabled(session.premiumCharges["golden-strawberry", default: 0] < 1)
            Button("Ribbon Twister · \(session.premiumCharges["twister", default: 0]) left") {
                guard let slot = selectedSlot else { return }
                if session.useRibbonTwister(slot: slot) { successFeedback() }
                else { warningFeedback() }
            }
            .disabled(session.premiumCharges["twister", default: 0] < 1 || selectedSlot == nil)
            Button("Picnic Pantry · \(session.premiumOwned.contains("pantry") ? "Owned" : "Locked")") {
                guard let slot = selectedSlot else { return }
                if session.usePicnicPantry(slot: slot) { successFeedback() }
                else { warningFeedback() }
            }
            .disabled(!session.premiumOwned.contains("pantry") || selectedSlot == nil)
            Button("Cancel", role: .cancel) { specialTargetTool = nil }
        } message: {
            Text(session.spyglassPiece.map { "Spyglass forecast: \($0.points.count) squares. Select a piece first for rotation or storage. For Trowel and Seed, tap an occupied or empty board square." } ??
                 "Select a tray piece for rotation/storage. For Trowel and Seed, choose a board cell. Invalid actions never spend charges.")
        }
        .alert("Continue with Golden Strawberry?", isPresented: $confirmGoldenStrawberry) {
            Button(session.premiumCharges["golden-strawberry", default: 0] > 0
                   ? "Use Golden Strawberry"
                   : "Buy & Continue · 🍓 \(BerryGameSession.goldenStrawberryCost)") {
                let ownsOne = session.premiumCharges["golden-strawberry", default: 0] > 0
                let resumed = ownsOne ? session.useGoldenStrawberry()
                    : session.buyAndUseGoldenStrawberry()
                if resumed {
                    showGameOver = false
                    specialTargetTool = nil
                    hintPreview = nil
                    selectedSlot = nil
                    drag = nil
                    successFeedback()
                } else {
                    warningFeedback()
                }
            }
            Button("Keep My Strawberries", role: .cancel) {}
        } message: {
            Text("Clear the occupied board and continue your current run. Keep your score, chapter and earned berries. Only one Golden Strawberry can be used per run. No points or lines are awarded for clearing.")
        }
        .sheet(isPresented: $showHelp) { helpSheet }
        .sheet(isPresented: $showSettings) { settingsSheet }
        .sheet(isPresented: $showShop) { shopSheet }
        .sheet(isPresented: $showStats) { statsSheet }
        .sheet(isPresented: $showCottage) { BerryCottageGardenView(session: session) }
        .sheet(isPresented: $showWelcome) { welcomeSheet }
        .onChange(of: scenePhase) { phase in
            // iOS screenshots and banners can temporarily mark the app inactive.
            // Pause overlays appear only when Pause was pressed, not on screenshots.
            if phase == .background { drag = nil; selectedSlot = nil }
            if isTimedMode {
                if phase != .active { pauseTimedClock() }
                else { resumeTimedClockIfPossible() }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isTimedMode && scenePhase == .active && !isPaused && pausedTimerAt == nil {
                refreshBlitzClock()
            }
        }
        .onChange(of: session.engine.activeGardenSection) { _ in
            // Never carry a selected shape or preview across patch changes.
            selectedSlot = nil
            hintPreview = nil
            activeDragSlot = nil
            activeDragFinger = nil
            drag = nil
        }
        .onChange(of: session.gameOver) { ended in
            if ended && mode == .superHard {
                // Nightmare is survival: a blocked board ends the race NOW.
                blitzRunning = false
                blitzFinished = true
                blitzDeadline = nil
                pausedTimerAt = nil
            }
            showGameOver = !showVictory && (ended || (isTimedMode && !blitzRunning && blitzRemaining == 0))
            if ended && sound && (mode == .superHard || !isTimedMode) {
                BerryAudio.shared.play(.gameOver)
            }
        }
        .onAppear {
            BerryAudio.shared.setScreen(isTimedMode ? .blitz : .gameplay)
            BerryAudio.shared.setMusic(music)
            session.selectMode(mode)
            scoreRecordAtEntry = max(session.bestScore, session.engine.score)
            celebratedRecordThisRun = false
            showNewBestBanner = false
            blitzRunning = isTimedMode
            blitzFinished = false
            blitzWarnedTenSeconds = false
            blitzPlayedFinalTick = false
            if isTimedMode {
                blitzRemaining = timedDuration
                blitzDeadline = Date().addingTimeInterval(TimeInterval(timedDuration))
                if sound { BerryAudio.shared.play(.blitzStart) }
            }
            showGameOver = session.gameOver || (isTimedMode && blitzRemaining == 0)
            if mode == .story {
                tellStory(BerryStoryNarrative.opening(for: storyLevel))
            }
            if mode == .superHard && session.gameOver {
                blitzRunning = false
                blitzFinished = true
                blitzDeadline = nil
            }
            if mode == .daily && dailyCompleted == BerryGameSession.dailyDateKey() { showVictory = session.engine.score >= goal }
            if !welcomed { showWelcome = true }
        }
        .onChange(of: session.engine.score) { score in
            checkObjective()
            celebrateNewRecordIfNeeded(score)
        }
        .onChange(of: session.engine.totalLines) { lines in
            if mode == .story, lines > 0 {
                tellStory(BerryStoryNarrative.encouragement(for: storyLevel))
            }
            checkObjective()
        }
        .onChange(of: showSettings) { opened in
            if opened { pauseTimedClock() }
            else { resumeTimedClockIfPossible() }
        }
        .onChange(of: showHelp) { opened in
            if opened { pauseTimedClock() }
            else { resumeTimedClockIfPossible() }
        }
        .onChange(of: showVictory) { victory in
            BerryAudio.shared.setScreen(victory ? .results : (isTimedMode ? .blitz : .gameplay))
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
                        Button("Continue Gardening") {
                            isPaused = false
                            resumeTimedClockIfPossible()
                        }
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
                    VStack(spacing: 12) {
                        if showVictory {
                            BerryGirlView(pose: .celebrate)
                                .frame(width: 83, height: 95)
                                .accessibilityLabel("Berry heroine celebrating your chapter")
                        }
                        Text(showVictory ? "🍰 ✨ 🍓" : confirmRestart ? "🌱 🍓 🌱" : "🍓 🌸 🧺")
                            .font(.system(size: 38))
                        Text(showVictory ? "Strawberry Spectacular!" : confirmRestart ? "Plant a Fresh Garden?" :
                             isTimedMode && blitzRemaining == 0 ? "Time's Up, Berry Racer!" : "No More Moves!")
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry).multilineTextAlignment(.center)
                        Text(showVictory ? (mode == .story ? "Chapter \(completedStoryChapter ?? max(1, storyLevel - 1)) complete! Your next chapter is ready." : "Your strawberry star has blossomed!") : confirmRestart ? "A fresh board starts this chapter again. Your records and earned berries stay safe." : isTimedMode && blitzRemaining == 0 ? "Your timer reached zero. See your results below!" : "No pieces fit. A Golden Strawberry can rescue this run, or you can restart for free.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate).multilineTextAlignment(.center)
                        if !confirmRestart {
                            HStack(spacing: 18) {
                                VStack { Text("\(session.engine.score)").font(.title2.bold()); Text("SCORE").font(.caption2) }
                                VStack { Text("\(session.engine.totalLines)").font(.title2.bold()); Text("LINES").font(.caption2) }
                                VStack { Text("\(session.engine.moves)").font(.title2.bold()); Text("MOVES").font(.caption2) }
                            }
                            .foregroundStyle(BerryStyle.chocolate)
                            if mode == .story && !showVictory {
                                Text("Chapter \(storyLevel): \(storyIsLineQuest ? "\(session.engine.totalLines)/\(storyTargetLines) lines" : "\(session.engine.score)/\(goal) points")")
                                    .font(.subheadline.bold()).foregroundStyle(BerryStyle.leaf)
                            }
                        }
                        if showGameOver && session.canUsePremium {
                            if session.engine.goldenRescueUsed {
                                Text("✨ Golden Strawberry already used this run")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(BerryStyle.chocolate.opacity(0.7))
                            } else {
                                let ownsGolden = session.premiumCharges["golden-strawberry", default: 0] > 0
                                let affordable = ownsGolden ||
                                    session.berries >= BerryGameSession.goldenStrawberryCost
                                Button {
                                    confirmGoldenStrawberry = true
                                } label: {
                                    HStack(spacing: 10) {
                                        BerryIcon(name: "GoldenStrawberry", size: 38)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(ownsGolden ? "CONTINUE · USE GOLDEN STRAWBERRY" :
                                                 "CONTINUE · 🍓 \(BerryGameSession.goldenStrawberryCost)")
                                                .font(.system(size: 13, weight: .black, design: .rounded))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.74)
                                            Text("Keep this run, clear your board")
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: 320, minHeight: 54)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(red: 0.79, green: 0.49, blue: 0.08))
                                .disabled(!affordable)
                                if !affordable {
                                    Text("Earn \(BerryGameSession.goldenStrawberryCost - session.berries) more strawberries to continue")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(BerryStyle.chocolate)
                                }
                            }
                        }
                        if showGameOver && session.shuffles > 0 && session.engine.canRescueWithShuffle && mode != .classic && !isTimedMode {
                            Button("✨ Continue with Shuffle (\(session.shuffles) left)") {
                                session.shuffle(); showGameOver = session.gameOver; selectedSlot = nil; drag = nil
                            }
                            .buttonStyle(.borderedProminent).tint(BerryStyle.leaf).controlSize(.large)
                        }
                        Button(showVictory ? "🍓 Another Sweet Adventure" : isTimedMode ? "⚡ Race Again" : "🍓 Plant a Fresh Garden") {
                            showVictory = false; showGameOver = false; confirmRestart = false
                            completedStoryChapter = nil; session.newGame(); selectedSlot = nil; drag = nil; hintPreview = nil
                            blitzRemaining = timedDuration; blitzRunning = isTimedMode
                            blitzDeadline = isTimedMode ?
                                Date().addingTimeInterval(TimeInterval(timedDuration)) : nil
                            blitzFinished = false; blitzWarnedTenSeconds = false; blitzPlayedFinalTick = false
                            pausedTimerAt = nil
                            if isTimedMode && sound { BerryAudio.shared.play(.blitzStart) }
                            celebratedRecordThisRun = false; scoreRecordAtEntry = session.bestScore
                            showNewBestBanner = false
                        }.buttonStyle(.borderedProminent).tint(BerryStyle.strawberry).controlSize(.large)
                        Button("🏡 Return to Strawberry Village") { returnToVillage() }
                            .foregroundStyle(BerryStyle.leaf).fontWeight(.bold)
                        if confirmRestart {
                            Button("Keep Playing") { confirmRestart = false }.foregroundStyle(BerryStyle.chocolate)
                        }
                    }
                    .padding(21).frame(maxWidth: 360)
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
            LinearGradient(colors: mode == .endless && session.engine.seasons % 4 == 1 ?
                [Color(red: 0.87, green: 0.97, blue: 0.85), BerryStyle.cream, BerryStyle.softPink] :
                mode == .endless && session.engine.seasons % 4 == 2 ?
                [Color(red: 1, green: 0.88, blue: 0.71), BerryStyle.cream, Color(red: 1, green: 0.80, blue: 0.70)] :
                mode == .endless && session.engine.seasons % 4 == 3 ?
                [Color(red: 0.86, green: 0.88, blue: 1), BerryStyle.cream, Color(red: 0.91, green: 0.91, blue: 1)] :
                mode == .cozy ? [Color(red: 0.88, green: 0.96, blue: 0.84), BerryStyle.cream, Color(red: 1, green: 0.86, blue: 0.87)] : mode == .challenge ? [Color(red: 1, green: 0.79, blue: 0.84), Color(red: 1, green: 0.95, blue: 0.77), Color(red: 0.98, green: 0.73, blue: 0.8)] : mode == .story ? [Color(red: 0.94, green: 0.83, blue: 1), BerryStyle.cream, Color(red: 1, green: 0.83, blue: 0.91)] : [Color(red: 1, green: 0.85, blue: 0.9), Color(red: 1, green: 0.96, blue: 0.87), Color(red: 1, green: 0.8, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                Text("STRAWBERRY SWEET").font(.system(size: 7, weight: .black, design: .rounded)).tracking(1.7).foregroundStyle(BerryStyle.leaf)
                Text("Berry Berry Blast!")
                    .font(.system(size: compact ? 15 : 17, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)
                    .foregroundStyle(BerryStyle.strawberry)
                Text(mode == .endless ? "\(session.engine.side)×\(session.engine.side) • SEASON \(session.engine.seasons + 1)" : mode.rawValue.uppercased()).font(.system(size: 8, weight: .bold, design: .rounded)).tracking(0.7).foregroundStyle(BerryStyle.chocolate.opacity(0.7))
            }
            Spacer(minLength: 0)
            if canManuallyPause {
                Button {
                    isPaused = true
                    pauseTimedClock()
                    drag = nil; selectedSlot = nil
                } label: {
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
        .overlay(alignment: .bottomLeading) {
            if mode == .story, let storyMessage {
                Text(storyMessage)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(.white, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(BerryStyle.strawberry.opacity(0.40), lineWidth: 1))
                    .shadow(color: BerryStyle.strawberry.opacity(0.2), radius: 6, y: 2)
                    .frame(maxWidth: 270, alignment: .leading)
                    .offset(x: 34, y: 38)
                    .allowsHitTesting(false)
                    .zIndex(10)
                    .transition(.opacity)
            }
        }
    }

    private var storyProgressCard: some View {
        let current = storyIsLineQuest ? session.engine.totalLines : session.engine.score
        let target = storyIsLineQuest ? storyTargetLines : goal
        let progress = min(1.0, CGFloat(current) / CGFloat(max(target, 1)))
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(BerryStyle.strawberry)
                Text("CHAPTER \(storyLevel): \(BerryStoryNarrative.title(for: storyLevel))")
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 2)
                Text(storyIsLineQuest ?
                     "\(current) / \(target) LINES" : "\(current) / \(target) POINTS")
                    .monospacedDigit()
                    .foregroundStyle(BerryStyle.strawberry)
                    .lineLimit(1)
            }
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(BerryStyle.chocolate)
            GeometryReader { bar in
                ZStack(alignment: .leading) {
                    Capsule().fill(BerryStyle.strawberry.opacity(0.15))
                    Capsule().fill(BerryStyle.strawberry)
                        .frame(width: bar.size.width * progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 11).padding(.vertical, 7)
        .background(.white.opacity(0.93), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func tellStory(_ message: String) {
        storyMessageGeneration += 1
        let generation = storyMessageGeneration
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            storyMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            guard storyMessageGeneration == generation else { return }
            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.20)) {
                storyMessage = nil
            }
        }
    }

    private var endlessSectionHUD: some View {
        let section = session.engine.activeGardenSection
        let names = ["Rose Garden", "Berry Patch", "Flower Meadow", "Cottage Orchard"]
        return HStack(spacing: 7) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(BerryStyle.leaf)
            VStack(alignment: .leading, spacing: 2) {
                Text("PATCH \(section + 1) OF 4 · \(names[section])")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(min(session.engine.gardenPatchMoves, 18))/18 plants · \(session.engine.gardenPatchLines)/3 lines")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
                    .lineLimit(1)
            }
            Spacer(minLength: 3)
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index == section ? BerryStyle.strawberry :
                          Color(red: 0.96, green: 0.73, blue: 0.80))
                    .frame(width: index == section ? 10 : 7, height: index == section ? 10 : 7)
                    .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1))
            }
            Button(action: showEndlessMove) {
                Image(systemName: "scope")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(BerryStyle.strawberry)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Find a legal move without spending a Hint")
        }
        .padding(.horizontal, 9)
        .frame(height: 38)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Garden patch \(section + 1) of 4. The game automatically changes patches.")
    }

    private var scoreBar: some View {
        HStack(spacing: 8) {
            scorePill("SCORE", value: session.engine.score, icon: "ScoreHeart")
            scorePill("BEST", value: session.bestScore, icon: "BestCrown")
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
            BerryIcon(name: icon, size: 27)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.system(size: 8, weight: .heavy, design: .rounded)).foregroundStyle(BerryStyle.chocolate.opacity(0.65))
                Text(BerryNumbers.compact(value)).font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(BerryStyle.chocolate).lineLimit(1).minimumScaleFactor(0.5)
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
            if mode != .classic && !isTimedMode {
            toolButton("Undo", icon: "UndoIcon", count: session.undos, enabled: session.canUndo) {
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
            toolButton("Shuffle", icon: "ShuffleIcon", count: session.shuffles, enabled: session.shuffles > 0) {
                if session.shuffles > 0 { session.shuffle(); selectedSlot = nil; drag = nil } else { showShop = true }
            }
            toolButton("Hint", icon: "BerryHint", count: session.hints, enabled: session.hints > 0) {
                if session.hints > 0 { showHint() } else { showShop = true }
            }
            }
            toolButton(mode == .cozy ? "Cottage" : "Stats", icon: mode == .cozy ? "CottageDecorations" : "StatsChart", count: nil, enabled: true) { if mode == .cozy { showCottage = true } else { showStats = true } }
            if session.canUsePremium {
                toolButton("Tools", icon: "GoldenStrawberry", count: nil, enabled: true) {
                    showPremiumActions = true
                }
            }
            if !isTimedMode {
                toolButton("Boutique", icon: "ShopBasket", count: nil, enabled: true) {
                    showShop = true
                }
            }
        }.frame(height: 50)
    }

    private func toolButton(_ title: String, icon: String, count: Int?, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                HStack(spacing: 2) {
                    BerryIcon(name: icon, size: 23)
                    if let count { Text("\(count)").font(.system(size: 10, weight: .heavy)) }
                }
                Text(title).font(.system(size: 9, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(enabled ? BerryStyle.strawberry : Color.gray)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
        // Do not disable the Undo button; when no undo is available the player
        // can still see the reason in the store/inventory.

    }

    // Both board measurement and touch events use UIWindow coordinates.
    // A lifted preview matches the original thumb interaction; direct-finger
    // targeting is accepted as a fallback when it is the legal position.
    private func placementForDrag(slot: Int, finger: CGPoint) -> BerryDragState? {
        guard canMakeMove, session.engine.tray.indices.contains(slot),
              let piece = session.engine.tray[slot] else { return nil }
        let candidates = BerryDropGeometry.candidates(
            for: finger, board: boardPosition.rect, piece: piece,
            side: session.engine.visibleSide
        )
        // Preview and release MUST use the same lifted anchor. Choosing a
        // different candidate just because it is legal silently moves an L
        // piece away from the location the player is pointing at.
        let target = candidates.first
        guard let target else { return nil }
        let origin = session.engine.sectionOrigin
        let row = target.row + origin.row, col = target.col + origin.col
        return BerryDragState(
            slot: slot, piece: piece, row: row, col: col,
            allowed: session.engine.canPlace(piece, row: row, col: col)
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
            activeDragSlot = slot
            activeDragFinger = event.location
            hintPreview = nil
            touchStatus = "Picked up piece \(slot + 1)"
        case .moved:
            activeDragFinger = event.location
            guard event.distanceSquared >= 64 else { return }
            if drag == nil && sound { BerryAudio.shared.play(.pickup) }
            activeDragSlot = slot
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

    private func showEndlessMove() {
        guard mode == .endless, session.engine.side == 24,
              let suggested = session.engine.suggestedEndlessMove(),
              let piece = session.engine.tray[suggested.slot] else { return }
        selectedSlot = suggested.slot
        hintPreview = BerryDragState(slot: suggested.slot, piece: piece,
                                    row: suggested.row, col: suggested.col,
                                    allowed: true)
        hintSerial += 1
        let serial = hintSerial
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if hintSerial == serial { hintPreview = nil }
        }
    }

    private func showHint() {
        guard mode != .classic, mode != .challenge,
              let suggestion = session.useHintIfPossible(),
              let piece = session.engine.tray[suggestion.slot] else { return }
        let preview = BerryDragState(slot: suggestion.slot, piece: piece,
                                     row: suggestion.row, col: suggestion.col, allowed: true)
        selectedSlot = suggestion.slot
        hintPreview = preview
        hintSerial += 1
        let current = hintSerial
        if sound { BerryAudio.shared.play(.menuSelect) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if hintSerial == current { hintPreview = nil }
        }
    }

    private func finishDrag(_ finalDrop: BerryDragState?) {
        defer { drag = nil }
        guard canMakeMove, let finalDrop else {
            #if DEBUG
            print("[BerryDrag] Release had no board target (boardPosition.rect=\(boardPosition.rect)).")
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
            hintPreview = nil
            selectedSlot = nil
            successFeedback()
        } else {
            warningFeedback()
        }
    }

    /// Identical drag and tap physics to verified 0.5.6.
    /// The 24x24 Endless engine presents one full-size 12x12 sector at a time.
    private func boardInteraction(actualSize: CGFloat) -> some View {
            BerryBoard(engine: session.engine, preview: drag ?? hintPreview, size: actualSize, selected: selectedSlot, mode: mode, strawberryUnlocked: strawberryUnlocked, previewStyle: previewStyle, onBoardRect: { rect in boardPosition.rect = rect })
                .overlay {
                    if strawberryRain && !reduceMotion {
                        BerryStrawberryRain().allowsHitTesting(false)
                    }
                }

                .padding(7)
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { tap in
                    let location = tap.location
                    if let special = specialTargetTool {
                        let side = session.engine.visibleSide
                        let cell = (actualSize - CGFloat(side - 1) * 3) / CGFloat(side) + 3
                        let origin = session.engine.sectionOrigin
                        let row = Int(floor((location.y - 7) / cell)) + origin.row
                        let col = Int(floor((location.x - 7) / cell)) + origin.col
                        let worked = special == "trowel" ?
                            session.useGoldenTrowel(row: row, col: col) :
                            session.useStarberrySeed(row: row, col: col)
                        if worked {
                            specialTargetTool = nil
                            hintPreview = nil
                            checkObjective()
                            successFeedback()
                        } else { warningFeedback() }
                        return
                    }
                    guard canMakeMove, let slot = selectedSlot,
                          session.engine.tray.indices.contains(slot),
                          let piece = session.engine.tray[slot] else { return }
                    // Tap coordinates are local to the 7-point padded board wrapper.
                    // Resolve using the same cell-origin logic as drag placement.
                    let local = CGPoint(x: location.x - 7, y: location.y - 7)
                    let area = CGRect(origin: .zero, size: CGSize(width: actualSize, height: actualSize))
                    guard let target = BerryDropGeometry.target(
                        for: local, board: area, piece: piece,
                        side: session.engine.visibleSide
                    ) else {
                        warningFeedback()
                        return
                    }
                    let origin = session.engine.sectionOrigin
                    if session.drop(slot: slot, row: target.row + origin.row,
                                    col: target.col + origin.col) {
                        hintPreview = nil
                        selectedSlot = nil
                        successFeedback()
                    } else {
                        warningFeedback()
                    }
                })
    }

    private func pauseTimedClock() {
        guard isTimedMode, blitzRunning, pausedTimerAt == nil else { return }
        pausedTimerAt = Date()
    }

    private func resumeTimedClockIfPossible() {
        guard isTimedMode, blitzRunning, !isPaused,
              !showHelp, !showSettings, scenePhase == .active,
              let began = pausedTimerAt else { return }
        blitzDeadline = blitzDeadline?.addingTimeInterval(Date().timeIntervalSince(began))
        pausedTimerAt = nil
        refreshBlitzClock()
    }

    private func refreshBlitzClock() {
        guard isTimedMode, blitzRunning, let deadline = blitzDeadline,
              !showVictory, !isPaused, pausedTimerAt == nil else { return }
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
        if isTimedMode {
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
        if mode == .story {
            let completedChapter = storyLevel
            completedStoryChapter = completedChapter
            session.rewardStory(completedChapter)
            tellStory(BerryStoryNarrative.victory(for: completedChapter))
            storyLevel += 1
        }
        if mode == .daily {
            session.rewardDaily()
            dailyCompleted = BerryGameSession.dailyDateKey()
            BerryDailyHistory.markCompleteToday()
        }
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
        if session.lastClearedLines > 0 && strawberryUnlocked && !reduceMotion {
            strawberryRain = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.12) { strawberryRain = false }
        }
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
            Text("Complete full lines and make combos. Sweet Endless saves your garden, and every blocked board blooms into a new season without ending your score!")
            primaryButton("Let's Grow!") { welcomed = true; showWelcome = false }
        }
    }
    private var helpSheet: some View {
        sheetBase("How to Play", icon: "🍰") {
            Text("Touch a piece and slide it onto the \(session.engine.side) × \(session.engine.side) board, then release. Or tap a piece and tap the board to place it. Complete full rows or columns to clear them.")
            Text("Clear multiple lines together for bonus points. Keep clearing to grow your combo. Clear the entire board for +300!")
            if mode == .classic {
                Text("Berry Classic uses three shapes at a time, with no timer, Undo or Shuffle. When nothing fits, the run ends. Chase your best record!")
            } else if mode == .endless {
                Text("Sweet Endless has no final game over. The 24×24 Mega Garden appears as four full-size 12×12 patches. Every 18 placements or three cleared lines, it automatically moves to the next patch, with no scrolling or manual navigation. A blocked patch moves on for free, and after patch four a fresh season begins. Scores, strawberries and your garden save stay intact. Tap the scope icon to find a legal move without spending a Hint.")
            } else {
                Text("Earn strawberries for line clears. Buy Undo, Shuffle and Berry Hint from the Boutique. Use helpers from the bottom toolbar in Story, Daily, Endless and Cozy modes. Berry Classic, Blitz and Nightmare stay power-up free.")
            Text("Blitz offers 1, 2, 5 and 10-minute score races. When the tray gets stuck, fresh playable pieces appear, so the clock determines the finish. Nightmare is a separate three-minute challenge and still ends if no piece can fit.")
            Text("Your purchased Cottage decorations can now be moved and saved inside My Strawberry Cottage on the village home screen.")
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
            Picker("🍓 Board Background", selection: $boardSurface) {
                Text("Strawberry Cream").tag("cream")
                Text("Frosted Candy Glass").tag("glass")
                Text("Picnic Cloth").tag("picnic")
                Text("Garden Patch").tag("garden")
                Text("Seed Mosaic").tag("seed")
            }
            Text("Board backgrounds change the empty cells only. All block hitboxes and saved games stay the same.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        NavigationStack {
            ScrollView {
                BerryBoutiqueView(session: session)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 35)
            }
            .background(BerryStyle.cream.ignoresSafeArea())
            .navigationTitle("Berry Boutique")
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Done") { showShop = false }
            }}
        }
        .presentationDetents([.large])
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
                   "Decorate: \(upgrades[completed]) • 🍓 \(session.nextCottageDecorationPrice ?? 0)" :
                   "Collection Complete") {
                session.buyCottageDecoration()
                if sound { BerryAudio.shared.play(.reward) }
            }
            .disabled(session.nextCottageDecorationPrice.map { session.berries < $0 } ?? true)
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
                Text(title).font(.system(size: 24, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(BerryStyle.strawberry)
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
