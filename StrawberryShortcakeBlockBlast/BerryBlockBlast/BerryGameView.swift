import SwiftUI
import UIKit
import AudioToolbox

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
    @State private var dailyAttemptDay = ""
    @State private var showVictory = false
    @State private var completedStoryChapter: Int?
    @State private var blitzRemaining = 120
    @State private var blitzWarnedTenSeconds = false
    @State private var blitzPlayedFinalTick = false
    @State private var blitzFinished = false
    @State private var blitzRunning = false
    @State private var blitzDeadline: Date?
    @State private var pausedTimerAt: Date?
    // @State survives SwiftUI view reappearance after a device lock.
    // Otherwise onAppear could accidentally restart a live Nightmare run.
    @State private var didInitializeRun = false
    @State private var storyMessage: String?
    @State private var showFullStory = false
    private var blitzVariant: BerryBlitzVariant { BerryBlitzVariant.selected }
    private var isTimedMode: Bool { mode == .challenge || mode == .superHard }
    private var timedDuration: Int { mode == .superHard ? 180 : blitzVariant.seconds }

    private var playtimeModeID: String {
        switch mode {
        case .classic: return "classic"
        case .endless: return "endless-\(session.engine.side)"
        case .story: return "story"
        case .daily: return "daily"
        case .cozy: return "cozy"
        case .superHard: return "nightmare"
        case .challenge: return "blitz-\(blitzVariant.seconds)"
        }
    }
    private var playtimeModeTitle: String {
        if mode == .endless { return "Sweet Endless \(session.engine.side)×\(session.engine.side)" }
        if mode == .challenge { return "Berry Blitz: \(blitzVariant.rawValue)" }
        return mode.rawValue
    }

    private func updateModePlaytime() {
        let activePuzzle = scenePhase == .active && !isPaused &&
            !showGameOver && !showVictory && !confirmRestart &&
            !showSettings && !showHelp && !showShop &&
            !showStats && !showCottage && !showWelcome && !showDailyCalendar &&
            !showPremiumActions && !confirmGoldenStrawberry &&
            (!isTimedMode || (blitzRunning && pausedTimerAt == nil))
        BerryPlaytimeTracker.shared.setModePlaying(activePuzzle)
    }
    @State private var isPaused = false
    @Environment(\.scenePhase) private var scenePhase
    private var canManuallyPause: Bool { true }
    private var canMakeMove: Bool {
        guard !isPaused, !showGameOver, !showVictory, !session.gameOver else { return false }
        if isTimedMode {
            return BerryTimedLifecycle.canPlay(
                now: Date(), deadline: blitzDeadline, running: blitzRunning,
                foreground: scenePhase == .active ||
                    UIApplication.shared.applicationState == .active,
                pausedAt: pausedTimerAt
            )
        }
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
        case .challenge: return "⚡ \(blitzVariant.rawValue.uppercased()) • \(session.engine.score) points"
        case .superHard: return "🌙 NIGHTMARE • 12 × 12 • SURVIVE THE CLOCK"
        }
    }

    @StateObject private var session = BerryGameSession()
    @State private var boardPosition = BerryBoardPositionCache()
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
    @State private var shopStartsWithHelpers = false
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
    @State private var rewardToast: String?
    @AppStorage(BerryTrophyCatalog.nightmareSurvivalsKey) private var nightmareSurvivals = 0
    @AppStorage(BerryTrophyCatalog.nightmareBestLinesKey) private var nightmareBestLines = 0
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
            // GeometryReader's height is already the safe content region.
            // Do not subtract top/bottom safe-area insets twice. Reserve the
            // true HUD and tray heights with a consistent screen-size budget.
            let boardSize = BerryGameplayLayout.boardSize(
                width: width, height: height,
                topInset: top, bottomInset: bottom,
                mode: mode,
                megaGarden: mode == .endless && session.engine.side == 24
            )
            ZStack {
                background
                VStack(spacing: compact ? 4 : 5) {
                    // Distribute surplus vertical space around the gameplay
                    // as phones grow taller; never leave it all below the
                    // counters while shrinking the board unnecessarily.
                    Spacer(minLength: 0)
                    topBar(compact: compact)
                    if mode == .classic {
                        BerryClassicScoreView(score: session.engine.score, best: session.bestScore, combo: session.engine.streak)
                    } else if mode == .challenge {
                        BerryBlitzHUD(timeLeft: blitzRemaining, score: session.engine.score,
                                     best: session.bestScore, variant: blitzVariant,
                                     deadline: blitzDeadline, pausedAt: pausedTimerAt, running: blitzRunning)
                    } else if mode == .superHard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🌙 STRAWBERRY NIGHTMARE")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                BerryLiveCountdown(
                                    deadline: blitzDeadline,
                                    pausedAt: pausedTimerAt,
                                    fallbackSeconds: blitzRemaining,
                                    running: blitzRunning,
                                    fontSize: 35,
                                    label: "Strawberry Nightmare time remaining"
                                )
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("SCORE").font(.caption.bold())
                                BerryCandyNumber(value: session.engine.score.formatted(), size: 30, label: "Score")
                                BerryCandyNumber(value: "BEST \(session.bestScore.formatted())", size: 13,
                                                 label: "Best")
                            }
                        }
                        .foregroundStyle(Color(red: 0.49, green: 0.09, blue: 0.35))
                        .padding(13)
                        .frame(height: 87)
                        .background(Color(red: 0.98, green: 0.86, blue: 0.94), in: RoundedRectangle(cornerRadius: 21))
                    } else {
                        scoreBar
                    }
                    if mode != .story {
                        HStack(spacing: 6) {
                            Image(systemName: mode == .challenge ? "bolt.fill" :
                                  mode == .cozy ? "leaf.fill" : "sparkles")
                            Text((mode == .endless || mode == .cozy) ?
                                 (session.lastMessage ?? objective) : objective)
                                .lineLimit(1).minimumScaleFactor(0.72)
                            Image(systemName: "sparkles")
                        }
                        .font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate)
                        .frame(height: 17)
                    }
                    if mode == .endless && session.engine.side == 24 {
                        endlessSectionHUD
                    }
                    if mode == .story {
                        storyProgressCard
                        storyDialogueCard(compact: compact)
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
                        Text(selectedSlot == nil ? "DRAG OR TAP TO PLACE" : "TAP A FREE BOARD SQUARE")
                    }
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.35)
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.76))
                    .frame(height: 13)
                    BerryThreePieceTray(
                        pieces: session.engine.tray,
                        availableWidth: max(1, min(width, 510) - 10),
                        height: compact ? 58 : 65,
                        selectedSlot: selectedSlot,
                        draggingSlot: activeDragSlot,
                        mode: mode,
                        strawberryUnlocked: strawberryUnlocked,
                        canMakeMove: canMakeMove,
                        onTouch: { slot, event in
                            handleTrayTouch(slot: slot, event: event)
                        },
                        onAccessibilitySelect: { slot in
                            if canMakeMove && session.engine.tray[slot] != nil {
                                selectedSlot = selectedSlot == slot ? nil : slot
                            }
                        }
                    )
                    .layoutPriority(3)
                    toolBar
                    if touchDiagnostics {
                        Text(touchStatus)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .lineLimit(2)
                            .foregroundStyle(BerryStyle.chocolate)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // One small status strip rather than a second full-size
                    // wallet + counters row competing with the board.
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(BerryStyle.leaf)
                        BerryCandyNumber(value: "🍓 \(session.berries.formatted())",
                                         size: 13, label: "Strawberry wallet")
                        Spacer(minLength: 4)
                        BerryCandyNumber(value: session.engine.totalLines.formatted(),
                                         size: 12, label: "Lines cleared")
                        Text("LINES")
                        Text("·")
                        BerryCandyNumber(value: session.engine.moves.formatted(),
                                         size: 12, label: "Moves")
                        Text("MOVES")
                    }
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.80))
                    .padding(.horizontal, 10)
                    .frame(height: 25)
                    .background(.white.opacity(0.78), in: Capsule())
                    Spacer(minLength: 0)
                }
                .disabled(isPaused)
                .padding(.horizontal, 3)
                .padding(.top, max(6, top * 0.18))
                .padding(.bottom, max(6, bottom * 0.18))
                .frame(maxWidth: 510)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                // Always show the piece being carried, even in Mystery
                // Garden. That setting may suppress the target-square
                // ghost, NEVER the actual piece in the player's hand.
                // Previously "drag == nil" hid the floating piece just
                // as the board ghost was also suppressed, making pieces
                // become entirely invisible during a legitimate drag.
                if BerryGameplayLayout.showsCarriedPiece(
                    previewStyle: previewStyle,
                    dragging: activeDragSlot != nil,
                    fingerKnown: activeDragFinger != nil
                ),
                   // The board's clipped ghost takes over for normal modes
                   // once a target is resolved. Mystery keeps its carried
                   // piece visible, but masks it to the playable rectangle.
                   (drag == nil || previewStyle == "mystery"),
                   let slot = activeDragSlot,
                   let finger = activeDragFinger,
                   session.engine.tray.indices.contains(slot),
                   let piece = session.engine.tray[slot] {
                    BerryPieceGlyph(piece: piece, unit: min(28, 90 / CGFloat(max(piece.width, piece.height))),
                                    mode: mode, strawberryUnlocked: strawberryUnlocked)
                        .opacity(1)
                        .shadow(color: BerryStyle.strawberry.opacity(0.3), radius: 9, y: 3)
                        .position(x: finger.x - geo.frame(in: .global).minX,
                                  y: finger.y - geo.frame(in: .global).minY - 58)
                        .mask {
                            if drag != nil && boardPosition.rect.width >
                               BerryGameplayLayout.boardTouchMargin * 2 {
                                let inner = BerryBoardContainment.playableRect(
                                    from: boardPosition.rect)
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .frame(width: inner.width, height: inner.height)
                                    .position(x: inner.midX - geo.frame(in: .global).minX,
                                              y: inner.midY - geo.frame(in: .global).minY)
                            } else {
                                // The carry animation must stay visible while
                                // travelling from the tray to the board.
                                Rectangle()
                            }
                        }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .zIndex(40)
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
            if let rewardToast {
                Text(rewardToast)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 11)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(BerryStyle.strawberry.opacity(0.7), lineWidth: 2))
                    .frame(maxWidth: min(335, width - 36))
                    .position(x: width / 2, y: height * 0.23)
                    .allowsHitTesting(false)
                    .zIndex(11)
                    .accessibilityLabel(rewardToast)
            }
            }
            .frame(width: width, height: height)
        }
        .preferredColorScheme(.light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
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
            .disabled(session.premiumCharges["golden-strawberry", default: 0] < 1 ||
                      !session.canContinueWithGoldenStrawberry)
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
                    dismissRescueAfterSuccess()
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
            // Locking the phone cancels the in-flight touch immediately,
            // regardless of whether UIKit delivers touchesCancelled. The
            // occupied board and all three remaining tray pieces survive.
            if phase != .active {
                drag = nil
                activeDragSlot = nil
                activeDragFinger = nil
                hintPreview = nil
                if phase == .background { selectedSlot = nil }
            }
            if phase == .active && mode == .daily && !dailyAttemptDay.isEmpty &&
               BerryDailyHistory.dateKey(for: Date()) != dailyAttemptDay {
                BerryDailyHistory.expirePriorAttemptIfNeeded()
                returnToVillage()
                return
            }
            if isTimedMode {
                if phase != .active {
                    pauseTimedClock()
                } else {
                    // Use the new phase argument. Reading scenePhase from
                    // inside its own change callback can still return the
                    // previous inactive value and leave timed moves locked.
                    resumeTimedClockIfPossible(foreground: true)
                }
            }
            updateModePlaytime()
        }
        // UIKit lifecycle notifications cover lock/unlock transitions where
        // SwiftUI's scenePhase can arrive late. Both paths are idempotent.
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willResignActiveNotification)) { _ in
            activeDragSlot = nil
            activeDragFinger = nil
            drag = nil
            hintPreview = nil
            if isTimedMode { pauseTimedClock() }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification)) { _ in
            if isTimedMode { resumeTimedClockIfPossible(foreground: true) }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if mode == .daily && scenePhase == .active && !dailyAttemptDay.isEmpty &&
               BerryDailyHistory.dateKey(for: Date()) != dailyAttemptDay {
                BerryDailyHistory.expirePriorAttemptIfNeeded()
                returnToVillage()
                return
            }
            if isTimedMode && (scenePhase == .active ||
                               UIApplication.shared.applicationState == .active) {
                // Recovery if a scene transition callback was missed or
                // arrived before SwiftUI updated its environment value.
                if pausedTimerAt != nil { resumeTimedClockIfPossible(foreground: true) }
                if !isPaused && pausedTimerAt == nil { refreshBlitzClock() }
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
            if ended && mode == .daily {
                // A final move might both reach the score goal AND exhaust
                // the board. Count that as a victory before locking the day.
                if session.engine.score >= goal {
                    checkObjective()
                } else {
                    BerryDailyHistory.markLostToday()
                }
            }
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
            if didInitializeRun {
                // A lock/unlock must never call selectMode() again and
                // replace the in-progress board, timer or rewards.
                BerryPlaytimeTracker.shared.enterMode(playtimeModeID, title: playtimeModeTitle)
                if isTimedMode && scenePhase == .active {
                    resumeTimedClockIfPossible(foreground: true)
                }
                updateModePlaytime()
                return
            }
            didInitializeRun = true
            session.selectMode(mode)
            if mode == .daily {
                dailyAttemptDay = BerryDailyHistory.dateKey(for: Date())
            }
            BerryPlaytimeTracker.shared.enterMode(playtimeModeID, title: playtimeModeTitle)
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
            if mode == .daily {
                // A finished calendar day can never open another playable run.
                if BerryDailyHistory.outcome() == .won { showVictory = true }
                if BerryDailyHistory.outcome() == .lost { showGameOver = true }
                if session.gameOver { BerryDailyHistory.markLostToday() }
            }
            if !welcomed { showWelcome = true }
            updateModePlaytime()
        }
        .onDisappear {
            BerryPlaytimeTracker.shared.leaveMode()
        }
        .onChange(of: isPaused) { _ in updateModePlaytime() }
        .onChange(of: showGameOver) { _ in updateModePlaytime() }
        .onChange(of: showShop) { _ in updateModePlaytime() }
        .onChange(of: showStats) { _ in updateModePlaytime() }
        .onChange(of: showCottage) { _ in updateModePlaytime() }
        .onChange(of: showWelcome) { _ in updateModePlaytime() }
        .onChange(of: showDailyCalendar) { _ in updateModePlaytime() }
        .onChange(of: showPremiumActions) { _ in updateModePlaytime() }
        .onChange(of: confirmGoldenStrawberry) { _ in updateModePlaytime() }
        .onChange(of: confirmRestart) { _ in updateModePlaytime() }
        .onChange(of: blitzRunning) { _ in updateModePlaytime() }
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
            updateModePlaytime()
        }
        .onChange(of: showHelp) { opened in
            if opened { pauseTimedClock() }
            else { resumeTimedClockIfPossible() }
            updateModePlaytime()
        }
        .onChange(of: showVictory) { victory in
            BerryAudio.shared.setScreen(victory ? .results : (isTimedMode ? .blitz : .gameplay))
            if victory && sound { BerryAudio.shared.play(.victory) }
            updateModePlaytime()
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
                    BerryResultScrollContainer {
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
                        Text(showVictory ? (mode == .story ? "Chapter \(completedStoryChapter ?? max(1, storyLevel - 1)) complete! Your next chapter is ready." : "Your strawberry star has blossomed!") : confirmRestart ? "A fresh board starts this chapter again. Your records and earned berries stay safe." : isTimedMode && blitzRemaining == 0 ? "Your timer reached zero. See your results below!" : BerryGameOverCopy.explanation(for: rescueAvailability, daily: mode == .daily))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if showVictory && mode == .story {
                            Text(BerryStoryNarrative.victory(for:
                                completedStoryChapter ?? max(1, storyLevel - 1)))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(BerryStyle.chocolate)
                                .multilineTextAlignment(.center)
                                .padding(9)
                                .background(BerryStyle.softPink,
                                            in: RoundedRectangle(cornerRadius: 14))
                                .accessibilityLabel("Chapter story conclusion")
                        }
                        if !confirmRestart {
                            HStack(spacing: 12) {
                                BerryCandyResultCounter(title: "SCORE", value: session.engine.score)
                                BerryCandyResultCounter(title: "LINES", value: session.engine.totalLines)
                                BerryCandyResultCounter(title: "MOVES", value: session.engine.moves)
                            }
                            if mode == .story && !showVictory {
                                Text("Chapter \(storyLevel): \(storyIsLineQuest ? "\(session.engine.totalLines)/\(storyTargetLines) lines" : "\(session.engine.score)/\(goal) points")")
                                    .font(.subheadline.bold()).foregroundStyle(BerryStyle.leaf)
                            }
                        }
                        if showGameOver && !showVictory && !confirmRestart &&
                           mode != .daily && !(isTimedMode && blitzRemaining == 0) {
                            continueRescueOptions
                        }
                        if mode == .daily {
                            Text(showVictory ? "✓ Daily Harvest completed. Return tomorrow!" :
                                 "🍓 Daily attempt used. Your next chance opens at midnight.")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(BerryStyle.strawberry)
                        } else {
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
                        }
                        Button("🏡 Return to Strawberry Village") { returnToVillage() }
                            .foregroundStyle(BerryStyle.leaf).fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
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
                    .padding(.horizontal, 22)
                    .padding(.vertical, 22)
                    }
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
                mode == .daily ?
                [Color(red: 1.0, green: 0.82, blue: 0.75), Color(red: 1, green: 0.96, blue: 0.84), Color(red: 0.88, green: 0.95, blue: 0.82)] :
                mode == .superHard ?
                [Color(red: 0.77, green: 0.67, blue: 0.88), Color(red: 0.97, green: 0.86, blue: 0.94), Color(red: 0.89, green: 0.77, blue: 0.91)] :
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
        HStack(spacing: compact ? 4 : 6) {
            BerryGirlView()
                .frame(width: compact ? 36 : 42, height: compact ? 36 : 42)
                .clipped()
            VStack(alignment: .leading, spacing: 1) {
                Text("Berry Berry Blast!")
                    .font(.system(size: compact ? 14 : 16,
                                  weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(BerryStyle.strawberry)
                    .layoutPriority(1)
                Text(mode == .endless ?
                     "\(session.engine.side)×\(session.engine.side) · SEASON \(session.engine.seasons + 1)" :
                     mode.rawValue.uppercased())
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            let diameter: CGFloat = compact ? 33 : 37
            if canManuallyPause {
                BerryCandyToolbarButton(symbol: "pause.fill", title: "Pause game",
                                        size: diameter) {
                    isPaused = true
                    pauseTimedClock()
                    drag = nil
                    selectedSlot = nil
                }
            }
            BerryCandyToolbarButton(symbol: "house.fill", title: "Return to Village",
                                    size: diameter, tint: BerryStyle.leaf) {
                returnToVillage()
            }
            BerryCandyToolbarButton(symbol: "gearshape.fill", title: "Berry Settings",
                                    size: diameter) { showSettings = true }
            BerryCandyToolbarButton(symbol: "questionmark", title: "How to Play",
                                    size: diameter) { showHelp = true }
        }
        .frame(height: compact ? 40 : 45)
    }

    /// An unobstructed, compact Story line stays above the board. Tapping
    /// it opens the complete dialogue without covering placement squares.
    private func storyDialogueCard(compact: Bool) -> some View {
        let message = storyMessage ?? BerryStoryNarrative.opening(for: storyLevel)
        return Button { showFullStory = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(BerryStyle.strawberry)
                Text(message)
                    .font(.system(size: compact ? 10 : 11,
                                  weight: .semibold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(BerryStyle.strawberry)
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 36 : 40)
            .background(.white.opacity(0.94),
                        in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11)
                .strokeBorder(BerryStyle.strawberry.opacity(0.42),
                              lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Berry Story dialogue. Tap to read complete message.")
        .alert("Berry Story", isPresented: $showFullStory) {
            Button("Back to the Garden", role: .cancel) {}
        } message: {
            Text(message)
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
                    .foregroundStyle(BerryStyle.candyNumberGradient)
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
        // Never clear after five seconds: it previously left an empty band
        // above the board and made chapter dialogue vanish.
        storyMessage = message
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
                    .foregroundStyle(BerryStyle.candyNumberGradient)
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

    /// Two equally discoverable rescue routes. Shuffle can refill a tray
    /// when the active garden has space. Golden Strawberry clears a crowded
    /// board. Both preserve the running chapter and score.
    private var rescueAvailability: BerryRescueAvailability {
        let shuffle = session.canContinueWithShuffle &&
            (session.shuffles > 0 || session.berries >= BerryEconomy.shufflePrice)
        let golden = session.canUsePremium && session.canContinueWithGoldenStrawberry &&
            (session.premiumCharges["golden-strawberry", default: 0] > 0 ||
             session.berries >= BerryGameSession.goldenStrawberryCost)
        return BerryRescueAvailability(shuffle: shuffle, golden: golden)
    }

    private var continueRescueOptions: some View {
        let availability = rescueAvailability
        let ownsShuffle = session.shuffles > 0
        let shuffleAvailable = availability.shuffle
        let ownsGold = session.premiumCharges["golden-strawberry", default: 0] > 0
        let goldenAvailable = availability.golden

        return VStack(spacing: 7) {
            Text(BerryGameOverCopy.heading(for: availability))
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            if shuffleAvailable || goldenAvailable {
                HStack(alignment: .top, spacing: 10) {
                    if shuffleAvailable {
                        rescueChoice(
                            title: "CONTINUE WITH SHUFFLE",
                            detail: "Replace stuck pieces",
                            price: ownsShuffle ? "Use 1 owned · \(session.shuffles) left" :
                                "Buy & Use · 🍓 \(BerryEconomy.shufflePrice)",
                            icon: "ShuffleIcon", available: true,
                            accent: BerryStyle.leaf) {
                            let rescued = ownsShuffle ?
                                session.shuffle() : session.buyAndContinueWithShuffle()
                            if rescued { dismissRescueAfterSuccess() }
                            else { warningFeedback() }
                        }
                    }
                    if goldenAvailable {
                        rescueChoice(
                            title: "GOLDEN STRAWBERRY",
                            detail: "Clear board & continue",
                            price: ownsGold ? "Use 1 owned" :
                                "Buy & Use · 🍓 \(BerryGameSession.goldenStrawberryCost)",
                            icon: "GoldenStrawberry", available: true,
                            accent: Color(red: 0.75, green: 0.45, blue: 0.08)) {
                            confirmGoldenStrawberry = true
                        }
                    }
                }
            } else {
                BerryNoRescueNotice(message: BerryGameOverCopy.noRescueNotice)
            }
        }
    }

    private func rescueChoice(title: String, detail: String, price: String,
                              icon: String, available: Bool, accent: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                BerryIcon(name: icon, size: 43)
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)
                Text(detail)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(price)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(BerryStyle.chocolate)
            .frame(maxWidth: .infinity, minHeight: 138)
            .padding(7)
            .background(.white, in: RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .strokeBorder(accent.opacity(0.84), lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(!available)
        .opacity(available ? 1 : 0.48)
        .accessibilityLabel(title + ". " + detail + ". " + price)
    }

    private func dismissRescueAfterSuccess() {
        showGameOver = false
        specialTargetTool = nil
        hintPreview = nil
        selectedSlot = nil
        drag = nil
        activeDragSlot = nil
        activeDragFinger = nil
        successFeedback()
    }

    private var scoreBar: some View {
        HStack(spacing: 8) {
            scorePill("SCORE", value: session.engine.score, icon: "StrawberryCandyBlock")
            scorePill("BEST", value: session.bestScore, icon: "BestCrown")
            HStack(spacing: 3) {
                Text("🍓").font(.system(size: 18))
                VStack(alignment: .leading, spacing: 0) {
                    Text("COMBO").font(.system(size: 8, weight: .heavy))
                    BerryCandyNumber(value: "×\(max(1, session.engine.streak))",
                                     size: 19, label: "Combo")
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
                BerryCandyNumber(value: BerryNumbers.compact(value), size: 20, label: title)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity)
        .frame(height: 51)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 15))
    }

    private var toolBar: some View {
        HStack(spacing: 4) {
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
                } else { openBoutique(helpers: true) }
            }
            toolButton("Shuffle", icon: "ShuffleIcon", count: session.shuffles,
                       enabled: session.shuffles > 0 && session.canContinueWithShuffle) {
                if session.shuffles > 0 && session.canContinueWithShuffle {
                    if session.shuffle() { selectedSlot = nil; drag = nil }
                    else { warningFeedback() }
                } else { openBoutique(helpers: true) }
            }
            toolButton("Hint", icon: "BerryHint", count: session.hints, enabled: session.hints > 0) {
                if session.hints > 0 { showHint() } else { openBoutique(helpers: true) }
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
                    openBoutique()
                }
            }
        }.frame(height: 48)
    }

    private func openBoutique(helpers: Bool = false) {
        shopStartsWithHelpers = helpers
        showShop = true
    }

    private func toolSymbol(_ icon: String) -> String {
        switch icon {
        case "UndoIcon": return "arrow.uturn.backward"
        case "ShuffleIcon": return "shuffle"
        case "BerryHint": return "lightbulb.fill"
        case "StatsChart": return "chart.bar.fill"
        case "GoldenStrawberry": return "wand.and.stars"
        case "CottageDecorations": return "house.fill"
        case "ShopBasket": return "basket.fill"
        default: return "square.grid.2x2.fill"
        }
    }

    private func toolButton(_ title: String, icon: String, count: Int?,
                            enabled: Bool, action: @escaping () -> Void) -> some View {
        let approvedArt: String = {
            switch title {
            case "Boutique": return "BBBIconShop"
            case "Tools": return "BBBIconTools"
            case "Cottage": return "CottageDecorations"
            case "Stats": return "StatsChart"
            case "Undo": return "UndoIcon"
            case "Shuffle": return "ShuffleIcon"
            case "Hint": return "BerryHint"
            default: return icon
            }
        }()
        return Button(action: action) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let art = UIImage(named: approvedArt) {
                            Image(uiImage: art)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                        } else {
                            Image(systemName: toolSymbol(icon))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(BerryStyle.strawberry)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(
                        LinearGradient(colors: [.white,
                                               BerryStyle.softPink.opacity(0.94)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.92), lineWidth: 1.25))
                    .shadow(color: BerryStyle.strawberry.opacity(0.18), radius: 2, y: 1)
                    if let count {
                        Text("\(count)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(BerryStyle.strawberry, in: Capsule())
                            .offset(x: 8, y: -2)
                    }
                }
                Text(title)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 47)
            .background(
                LinearGradient(colors: [.white.opacity(0.98),
                                        BerryStyle.cream.opacity(0.94)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(enabled ? BerryStyle.strawberry.opacity(0.37) :
                              BerryStyle.chocolate.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count.map { "\(title), \($0) available" } ?? title)
        // Never hide an icon because the tool is unavailable. The original
        // action still opens the Boutique or preserves the mode restriction.
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
            BerryBoard(engine: session.engine, preview: drag ?? hintPreview, size: actualSize, selected: selectedSlot, mode: mode, strawberryUnlocked: strawberryUnlocked, previewStyle: previewStyle)
                .overlay {
                    if strawberryRain && !reduceMotion {
                        BerryStrawberryRain().allowsHitTesting(false)
                    }
                }
                // Fruit rain and line-clear decorations are confined to the
                // actual rounded board, never painted over the exterior frame.
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                // Measure the OUTER touch wrapper, not just the inner painted grid.
                // Drop geometry subtracts this same rim exactly once for drags and taps.
                .padding(BerryGameplayLayout.boardTouchMargin)
                .background(BerryBoardWindowAnchor(
                    onRect: { rect in boardPosition.rect = rect },
                    tracksScrolling: false))
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { tap in
                    let location = tap.location
                    if let special = specialTargetTool {
                        let side = session.engine.visibleSide
                        let cell = (actualSize - CGFloat(side - 1) * 3) / CGFloat(side) + 3
                        let origin = session.engine.sectionOrigin
                        let row = Int(floor((location.y - 3) / cell)) + origin.row
                        let col = Int(floor((location.x - 3) / cell)) + origin.col
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
                    // SpatialTapGesture uses wrapper-local coordinates. Do not
                    // pre-subtract the rim: DropGeometry handles it exactly once.
                    let wrapperSize = actualSize + 2 * BerryGameplayLayout.boardTouchMargin
                    let area = CGRect(origin: .zero,
                                      size: CGSize(width: wrapperSize, height: wrapperSize))
                    guard let target = BerryDropGeometry.target(
                        for: location, board: area, piece: piece,
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
                // This decoration is outside the touch tracker and gesture:
                // altering its appearance cannot shift legal placement cells.
                .padding(BerryGameplayLayout.gardenFrameInset)
                .background {
                    BerryGardenBorder(mode: mode)
                }
    }

    private func pauseTimedClock() {
        guard isTimedMode, blitzRunning, pausedTimerAt == nil else { return }
        let pausedAt = Date()
        pausedTimerAt = pausedAt
        blitzRemaining = BerryTimedLifecycle.pausedSeconds(
            deadline: blitzDeadline, pausedAt: pausedAt, fallback: blitzRemaining)
    }

    private func resumeTimedClockIfPossible(foreground: Bool? = nil) {
        let canResume = BerryTimedLifecycle.canResume(
            foreground: foreground ?? (scenePhase == .active),
            running: isTimedMode && blitzRunning,
            manualPause: isPaused,
            anyOverlayOpen: showHelp || showSettings || showGameOver ||
                showVictory || showWelcome || confirmRestart ||
                showShop || showStats || showDailyCalendar ||
                showPremiumActions || confirmGoldenStrawberry,
            pausedAt: pausedTimerAt
        )
        guard canResume, let began = pausedTimerAt else { return }
        let resumedAt = Date()
        blitzDeadline = BerryTimedLifecycle.restoredDeadline(
            blitzDeadline, pausedAt: began, resumedAt: resumedAt)
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
            // Count only a legitimate full Nightmare survival. An early board
            // lock never qualifies. A second timer tick cannot double-award.
            if mode == .superHard && !session.gameOver && session.engine.moves > 0 {
                nightmareSurvivals = min(9999, nightmareSurvivals + 1)
                if nightmareSurvivals >= 5 && nightmareBestLines >= 12,
                   let reward = BerryTrophyCatalog.rewards.first(where: { $0.id == "moonberry-nightmare" }),
                   !BerryTrophyCatalog.permanentlyEarned(reward) {
                    BerryTrophyCatalog.recordPermanentUnlock(reward)
                    showRewardToast("🌙 Moonberry Nightmare unlocked! Visit Trophy Garden to equip.")
                }
            }
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
            if completedChapter == 5 && lifetimeLines >= 2500,
               let reward = BerryTrophyCatalog.rewards.first(where: { $0.id == "royal-berry" }),
               !BerryTrophyCatalog.permanentlyEarned(reward) {
                BerryTrophyCatalog.recordPermanentUnlock(reward)
                showRewardToast("👑 Royal Berry unlocked! Visit Trophy Garden to equip.")
            }
        }
        if mode == .daily {
            // Completed outcomes can never reward or replay twice.
            guard BerryDailyHistory.outcome() == .active else { return }
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

    private func showRewardToast(_ message: String) {
        rewardToast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            if rewardToast == message { rewardToast = nil }
        }
    }

    private func successFeedback() {
        let previousLines = lifetimeLines
        lifetimeLines += session.lastClearedLines
        if mode == .superHard {
            nightmareBestLines = max(nightmareBestLines, session.engine.totalLines)
        }
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
            session.awardOnce("strawberry-unlock", amount: 15, reason: "Strawberry blocks unlocked")
            if let reward = BerryTrophyCatalog.rewards.first {
                BerryTrophyCatalog.recordPermanentUnlock(reward)
            }
            showRewardToast("🍓 Strawberry Red unlocked! +15 berries. View it in Trophy Garden.")
        }
        let newlyEarned = BerryTrophyCatalog.rewards.filter { reward in
            reward.requiredLines > 10 && previousLines < reward.requiredLines &&
            lifetimeLines >= reward.requiredLines &&
            !BerryTrophyCatalog.permanentlyEarned(reward) &&
            BerryTrophyCatalog.unlocked(reward, lifetimeLines: lifetimeLines,
                     chapter: storyLevel, survivals: nightmareSurvivals,
                     nightmareBest: nightmareBestLines, legacy: strawberryUnlocked)
        }
        for reward in newlyEarned {
            BerryTrophyCatalog.recordPermanentUnlock(reward)
        }
        if let earned = newlyEarned.last {
            showRewardToast("🍓 \(earned.title) unlocked! Visit Trophy Garden to equip.")
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
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                BerryGridInfoTile(title: "Drag or Tap",
                                 detail: "Drag a berry piece onto free squares, or tap a piece and then its destination",
                                 art: "BerryClassic", value: "Place")
                BerryGridInfoTile(title: "Complete Lines",
                                 detail: "Fill a row or column to clear it and earn strawberries",
                                 art: "HarvestReward", value: "Clear")
                BerryGridInfoTile(title: "Score Combos",
                                 detail: "Clear multiple lines to increase your sweet score",
                                 art: "Milestone", value: "× Combo")
                BerryGridInfoTile(title: "Your Mode",
                                 detail: mode == .classic ?
                                    "Classic: no timers or power-ups; three pieces at a time" :
                                    mode == .daily ? "Daily: one attempt a day, win or lose" :
                                    mode == .endless ? "Endless: garden sizes persist across plays" :
                                    mode == .challenge ? "Blitz: race the clock" :
                                    mode == .superHard ? "Nightmare: three-minute survival" :
                                    "Story and Cozy: helpers are available",
                                 art: "BerryStory", value: mode.rawValue)
                BerryGridInfoTile(title: "Garden Helpers",
                                 detail: "Undo, Shuffle and Hint work in supported modes",
                                 art: "BerryHint", value: "Optional")
                BerryGridInfoTile(title: "Candy Block Collection",
                                 detail: "Collect and equip your earned block styles in the Trophy Garden",
                                 art: "BBBIconBlocks", value: "Rewards")
            }
            primaryButton("Back to Playing") { showHelp = false }
        }
    }
    private var settingsSheet: some View {
        NavigationStack {
            BerrySettingsHubView(onRestart: {
                showSettings = false
                confirmRestart = true
            })
            .navigationTitle("🍓 Berry Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .presentationDetents([.large])
    }
    private var shopSheet: some View {
        NavigationStack {
            ScrollView {
                BerryBoutiqueView(session: session,
                                  opensWithHelpers: shopStartsWithHelpers)
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
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(0..<upgrades.count, id: \.self) { index in
                    BerryGridInfoTile(
                        title: upgrades[index],
                        detail: completed > index ? "Already decorating your cottage" : "Not collected yet",
                        art: "CottageDecorations",
                        value: completed > index ? "✓ Owned" : "Locked")
                }
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
        sheetBase("Your Berry Scrapbook", icon: "📖") {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                BerryGridInfoTile(title: "Best Score", detail: "Personal record",
                                 art: "Champion", value: session.bestScore.formatted())
                BerryGridInfoTile(title: "Current Score", detail: "This run",
                                 art: "BerryClassic", value: session.engine.score.formatted())
                BerryGridInfoTile(title: "Lines Cleared", detail: "This run",
                                 art: "HarvestReward", value: session.engine.totalLines.formatted())
                BerryGridInfoTile(title: "Moves", detail: "Total pieces placed",
                                 art: "Milestone", value: session.engine.moves.formatted())
                BerryGridInfoTile(title: "Best Combo", detail: "Longest clear streak",
                                 art: "Milestone", value: "×\(session.engine.bestCombo)")
                BerryGridInfoTile(title: "Perfect Gardens", detail: "Board clears",
                                 art: "CottageDecorations", value: "\(session.engine.boardClears)")
                BerryGridInfoTile(title: "Strawberries Earned", detail: "Lifetime income",
                                 art: "HarvestReward", value: "\(session.totalEarnedBerries)")
                BerryGridInfoTile(title: "Cottage Decorations", detail: "Owned furnishings",
                                 art: "CottageDecorations", value: "\(session.cottageDecorations)")
            }
            primaryButton("Keep Playing") { showStats = false }
        }
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
