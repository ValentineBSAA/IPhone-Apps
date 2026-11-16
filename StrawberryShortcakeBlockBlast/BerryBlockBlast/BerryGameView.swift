import SwiftUI
import UIKit
import AudioToolbox

private struct BerryBoardRect: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

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
    private let gap: CGFloat = 3

    var body: some View {
        let unit = (size - 7 * gap) / 8
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 0.98, green: 0.71, blue: 0.79))
                .overlay { RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.8), lineWidth: 3) }
                .padding(-7)
                .shadow(color: BerryStyle.strawberry.opacity(0.22), radius: 15, y: 8)
            ForEach(0..<64, id: \.self) { i in
                let r = i / 8
                let c = i % 8
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.76))
                        .overlay(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.58), lineWidth: 1)
                        }
                    if let tint = engine.board[r][c] { BerryTile(tint: tint, mode: mode, strawberryUnlocked: strawberryUnlocked) }
                }
                .frame(width: unit, height: unit)
                .offset(x: CGFloat(c) * (unit + gap), y: CGFloat(r) * (unit + gap))
            }
            if let preview {
                ForEach(preview.piece.points, id: \.self) { p in
                    let r = preview.row + p.row
                    let c = preview.col + p.col
                    if (0..<8).contains(r), (0..<8).contains(c) {
                        BerryTile(tint: preview.piece.tint, preview: true, mode: mode, strawberryUnlocked: strawberryUnlocked)
                            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(preview.allowed ? Color.green : Color.red, lineWidth: 2) }
                            .frame(width: unit, height: unit)
                            .offset(x: CGFloat(c) * (unit + gap), y: CGFloat(r) * (unit + gap))
                    }
                }
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .background {
            GeometryReader { geo in
                Color.clear.preference(key: BerryBoardRect.self, value: geo.frame(in: .named("berry-screen")))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Berry garden, eight by eight puzzle board")
    }
}

struct BerryGameView: View {
    let mode: BerryMode
    let onExit: () -> Void
    @AppStorage("berryblockblast.story.level") private var storyLevel = 1
    @AppStorage("berryblockblast.daily.completed") private var dailyCompleted = ""
    @State private var showVictory = false
    private var goal: Int { mode == .story ? 100 + storyLevel * 80 : mode == .challenge ? 600 : 300 }
    private var objective: String {
        switch mode {
        case .endless: "Fill a row or column. Grow your berry garden!"
        case .story: "CHAPTER \(storyLevel) • Reach \(goal) points to bloom!"
        case .daily: "DAILY HARVEST • Gather \(goal) points!"
        case .cozy: "COZY COTTAGE • Enjoy the garden at your pace!"
        case .challenge: "BERRY BLITZ • Reach \(goal) points!"
        }
    }

    @StateObject private var session = BerryGameSession()
    @State private var boardRect: CGRect = .zero
    @State private var drag: BerryDragState?
    @State private var selectedSlot: Int?
    @State private var showHelp = false
    @State private var showSettings = false
    @State private var showShop = false
    @State private var showStats = false
    @State private var confirmRestart = false
    @State private var showGameOver = false
    @State private var showWelcome = false
    @AppStorage("berryblockblast.haptics") private var haptics = true
    @AppStorage("berryblockblast.sound") private var sound = true
    @AppStorage("berryblockblast.music") private var music = true
    @State private var sparkle = false
    @AppStorage("berryblockblast.strawberry-unlocked") private var strawberryUnlocked = false
    @AppStorage("berryblockblast.lifetime-lines") private var lifetimeLines = 0
    @State private var showUnlock = false
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
            let boardSize = max(185, min(width - 42, height - top - bottom - (compact ? 248 : 282), 475))
            let cell = (boardSize - 21) / 8
            ZStack {
                background
                VStack(spacing: compact ? 5 : 8) {
                    topBar(compact: compact)
                    scoreBar
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text(session.lastMessage ?? objective)
                            .lineLimit(1).minimumScaleFactor(0.65)
                        Image(systemName: "sparkles")
                    }
                    .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .frame(height: 19)
                    BerryBoard(engine: session.engine, preview: drag, size: boardSize, selected: selectedSlot, mode: mode, strawberryUnlocked: strawberryUnlocked)
                        .overlay { if sparkle { Text(harvestCheer).font(.headline).foregroundStyle(BerryStyle.strawberry).padding(12).background(.regularMaterial, in: Capsule()).transition(.scale.combined(with: .opacity)).allowsHitTesting(false) } }
                        .padding(7)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let slot = selectedSlot, let piece = session.engine.tray[slot] else { return }
                            let step = cell + 3
                            let col = Int(floor((location.x - 7) / step))
                            let row = Int(floor((location.y - 7) / step))
                            if session.drop(slot: slot, row: row, col: col) {
                                selectedSlot = nil
                                successFeedback()
                            } else if !session.engine.canPlace(piece, row: row, col: col) { warningFeedback() }
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
                                    BerryPieceGlyph(piece: piece, unit: min(17, (width - 86) / CGFloat(3 * max(piece.width, 3))), mode: mode, strawberryUnlocked: strawberryUnlocked)
                                        .opacity(drag?.slot == slot ? 0.3 : session.engine.hasPlacement(for: piece) ? 1 : 0.3)
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(BerryStyle.leaf.opacity(0.6))
                                        .font(.title2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: compact ? 65 : 76)
                            .contentShape(Rectangle())
                            .onTapGesture { if piece != nil { selectedSlot = selectedSlot == slot ? nil : slot } }
                            .gesture(
                                DragGesture(minimumDistance: 5, coordinateSpace: .named("berry-screen"))
                                    .onChanged { value in updateDrag(slot: slot, finger: value.location, cell: cell) }
                                    .onEnded { _ in finishDrag() }
                            )
                            .accessibilityLabel("Berry piece \(slot + 1)")
                        }
                    }
                    toolBar
                    HStack {
                        Text("🍓 \(session.berries) berries")
                        Spacer()
                        Text("\(session.engine.totalLines) lines • \(session.engine.moves) moves")
                    }
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.65))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 15)
                .padding(.top, max(8, top + 3))
                .padding(.bottom, max(5, bottom))
                .frame(maxWidth: 510)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: width, height: height)
            .coordinateSpace(name: "berry-screen")
            .onPreferenceChange(BerryBoardRect.self) { boardRect = $0 }
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
        .sheet(isPresented: $showWelcome) { welcomeSheet }
        .onChange(of: session.gameOver) { _, ended in showGameOver = ended && !showVictory }
        .onAppear {
            BerryAudio.shared.setMusic(music)
            session.selectMode(mode)
            showGameOver = session.gameOver
            if !welcomed { showWelcome = true }
        }
        .onChange(of: session.engine.score) { _, newScore in
            guard mode == .story || mode == .daily || mode == .challenge else { return }
            guard newScore >= goal, !showVictory else { return }
            if mode == .story { session.rewardStory(storyLevel); storyLevel += 1 }
            if mode == .daily { session.rewardDaily(); dailyCompleted = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash)) }
            showVictory = true
        }
        .overlay {
            if showVictory || showGameOver || confirmRestart {
                ZStack {
                    BerryStyle.chocolate.opacity(0.42).ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text(showVictory ? "🍰 ✨ 🍓" : confirmRestart ? "🌱 🍓 🌱" : "🍓 🌸 🧺")
                            .font(.system(size: 38))
                        Text(showVictory ? "Strawberry Spectacular!" : confirmRestart ? "Plant a Fresh Garden?" : "Our Berry Patch Is Full!")
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry).multilineTextAlignment(.center)
                        Text(showVictory ? "Your strawberry star has blossomed!" : confirmRestart ? "Your best score and earned berries stay safe." : "You harvested \(session.engine.score) sweet points and cleared \(session.engine.totalLines) lines. Every garden deserves another season!")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate).multilineTextAlignment(.center)
                        Button(showVictory ? "🍓 Another Sweet Adventure" : "🍓 Plant a Fresh Garden") {
                            showVictory = false; showGameOver = false; confirmRestart = false
                            session.newGame(); selectedSlot = nil; drag = nil
                        }.buttonStyle(.borderedProminent).tint(BerryStyle.strawberry).controlSize(.large)
                        Button("🏡 Return to Strawberry Village") { onExit() }
                            .foregroundStyle(BerryStyle.leaf).fontWeight(.bold)
                        if showGameOver && session.shuffles > 0 {
                            Button("✨ Use Shuffle (\(session.shuffles) left)") { session.shuffle(); showGameOver = session.gameOver }
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
            LinearGradient(colors: [Color(red: 1, green: 0.85, blue: 0.9), Color(red: 1, green: 0.96, blue: 0.87), Color(red: 1, green: 0.8, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
            Button { onExit() } label: { Image(systemName: "house.fill").font(.system(size: 20)).foregroundStyle(BerryStyle.leaf) }.accessibilityLabel("Main menu")
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
            toolButton("Undo", icon: "arrow.uturn.backward", count: session.undos, enabled: session.canUndo) {
                session.undo(); selectedSlot = nil; successFeedback()
            }
            toolButton("Shuffle", icon: "shuffle", count: session.shuffles, enabled: session.shuffles > 0) {
                session.shuffle(); selectedSlot = nil; successFeedback()
            }
            toolButton("Shop", icon: "basket.fill", count: nil, enabled: true) { showShop = true }
            toolButton("Stats", icon: "chart.bar.fill", count: nil, enabled: true) { showStats = true }
            toolButton("Home", icon: "house.fill", count: nil, enabled: true) { onExit() }
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
        }.disabled(!enabled)
    }

    private func updateDrag(slot: Int, finger: CGPoint, cell: CGFloat) {
        guard session.engine.tray.indices.contains(slot), let piece = session.engine.tray[slot] else { drag = nil; return }
        let step = cell + 3
        let x = finger.x - boardRect.minX - CGFloat(piece.width) * step / 2
        let y = finger.y - boardRect.minY - 42 - CGFloat(piece.height) * step / 2
        let col = Int((x / step).rounded())
        let row = Int((y / step).rounded())
        let hovering = boardRect.insetBy(dx: -28, dy: -55).contains(finger)
        drag = BerryDragState(slot: slot, piece: piece, row: row, col: col,
                              allowed: hovering && session.engine.canPlace(piece, row: row, col: col))
    }

    private func finishDrag() {
        defer { drag = nil }
        guard let drag, drag.allowed else { return }
        if session.drop(slot: drag.slot, row: drag.row, col: drag.col) {
            selectedSlot = nil
            successFeedback()
        }
    }

    private func successFeedback() {
        lifetimeLines += session.lastClearedLines
        if lifetimeLines >= 10 && !strawberryUnlocked {
            strawberryUnlocked = true
            showUnlock = true
            session.awardOnce("strawberry-unlock", amount: 15, reason: "Strawberry blocks unlocked")
        }
        if haptics { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        if sound { BerryAudio.shared.play(session.lastEarned > 10 ? .clear : .place) }
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
            Text("No timer, no pressure. Every three placed pieces bring a new batch. Your progress saves automatically.")
            primaryButton("Let's Grow!") { welcomed = true; showWelcome = false }
        }
    }
    private var helpSheet: some View {
        sheetBase("How to Play", icon: "🍰") {
            Text("Drag a block onto the 8 × 8 board. Or tap a block, then tap an empty square. Complete full rows or columns to clear them.")
            Text("Clear multiple lines together for bonus points. Keep clearing to grow your combo. Clear the entire board for +300!")
            Text("Earn strawberries for line clears. Spend them in the basket on extra Undos and Shuffles. Keep playing until nothing fits.")
            primaryButton("Got It!") { showHelp = false }
        }
    }
    private var settingsSheet: some View {
        sheetBase("Berry Settings", icon: "⚙️") {
            Toggle("Haptic feedback", isOn: $haptics).tint(BerryStyle.strawberry)
            Toggle("Sweet sound effects", isOn: $sound).tint(BerryStyle.strawberry)
            Toggle("Strawberry music box", isOn: $music).tint(BerryStyle.strawberry)
                .onChange(of: music) { _, enabled in BerryAudio.shared.setMusic(enabled) }
            Text("Your game is saved automatically. The display uses the full iPhone screen.").font(.footnote)
            Button("Start a New Garden", role: .destructive) { showSettings = false; confirmRestart = true }
            Text("🍓 v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev") • build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")").font(.footnote).foregroundStyle(.secondary)
            primaryButton("Done") { showSettings = false }
        }
    }
    private var shopSheet: some View {
        sheetBase("The Berry Basket", icon: "🧺") {
            Text("Your strawberries: 🍓 \(session.berries)").font(.system(size: 22, weight: .black, design: .rounded))
            HStack {
                VStack(alignment: .leading) { Text("Extra Undo").bold(); Text("🍓 25").font(.caption) }
                Spacer()
                Button("Buy") { session.buyUndo() }.disabled(session.berries < 25).buttonStyle(.borderedProminent).tint(BerryStyle.strawberry)
            }
            HStack {
                VStack(alignment: .leading) { Text("Extra Shuffle").bold(); Text("🍓 25").font(.caption) }
                Spacer()
                Button("Buy") { session.buyShuffle() }.disabled(session.berries < 25).buttonStyle(.borderedProminent).tint(BerryStyle.strawberry)
            }
            Text("🍓 Clear lines to earn berries: +3 per line, plus combo and perfect-garden bonuses. Strawberry School earns +25, Daily Harvest +30, and Story chapters earn rewards.").font(.subheadline)
            Text("🎀 Recent Berry Harvests").font(.headline).foregroundStyle(BerryStyle.strawberry)
            ForEach(session.rewardsLog.prefix(6), id: \.self) { reward in Text(reward).font(.caption) }
            Text(strawberryUnlocked ? "🍓 Strawberry blocks unlocked!" : "🔒 Clear \(max(0, 10 - lifetimeLines)) more lines across your gardens to unlock strawberry blocks and 15 berries.").font(.subheadline).foregroundStyle(BerryStyle.leaf)
            Text("All strawberries are earned by playing. No purchases or ads.").font(.footnote)
            primaryButton("Back to Garden") { showShop = false }
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
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(BerryStyle.cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
