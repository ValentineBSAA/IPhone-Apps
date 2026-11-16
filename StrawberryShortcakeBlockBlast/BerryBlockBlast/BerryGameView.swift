import SwiftUI
import UIKit
import AudioToolbox

private struct BoardFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

struct BerryDrag {
    let slot: Int
    let piece: BerryPiece
    let row: Int
    let col: Int
    let hovering: Bool
    let allowed: Bool
}

struct BerryBoardView: View {
    let engine: BerryEngine
    let preview: BerryDrag?
    let size: CGFloat
    private let gap: CGFloat = 3

    var body: some View {
        let cell = (size - 7 * gap) / 8
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20).fill(BerryStyle.strawberry.opacity(0.12)).padding(-7)
            ForEach(0..<64, id: \.self) { index in
                let row = index / 8
                let col = index % 8
                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.78))
                    if let tint = engine.board[row][col] { BerryTile(tint: tint) }
                }
                .frame(width: cell, height: cell)
                .offset(x: CGFloat(col) * (cell + gap), y: CGFloat(row) * (cell + gap))
            }
            if let preview, preview.hovering {
                ForEach(preview.piece.points, id: \.self) { point in
                    let r = preview.row + point.row
                    let c = preview.col + point.col
                    if (0..<8).contains(r), (0..<8).contains(c) {
                        BerryTile(tint: preview.piece.tint, preview: true)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(preview.allowed ? BerryStyle.leaf : .red, lineWidth: 2)
                            }
                            .frame(width: cell, height: cell)
                            .offset(x: CGFloat(c) * (cell + gap), y: CGFloat(r) * (cell + gap))
                    }
                }
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: BoardFrameKey.self,
                                       value: proxy.frame(in: .named("berry-playfield")))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Eight by eight puzzle board, score \(engine.score)")
    }
}

struct BerryGameView: View {
    @StateObject private var session = BerryGameSession()
    @State private var boardFrame: CGRect = .zero
    @State private var drag: BerryDrag?
    @State private var selectedSlot: Int? = nil
    @State private var showHelp = false
    @State private var showSettings = false
    @State private var confirmRestart = false
    @State private var showGameOver = false
    @AppStorage("berryblockblast.haptics") private var haptics = true
    @AppStorage("berryblockblast.sound") private var sound = true

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            // Reserve enough height for the complete tray and controls, even on
            // small iPhones. The board never pushes the playable pieces offscreen.
            let boardSize = max(190, min(width - 44, height - 312, 450))
            let cell = (boardSize - 21) / 8
            ZStack {
                LinearGradient(colors: [Color(red: 1, green: 0.91, blue: 0.94),
                                        BerryStyle.cream, Color(red: 1, green: 0.86, blue: 0.88)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                        .frame(height: 72)
                    HStack(spacing: 8) {
                        scoreCard("SCORE", value: session.engine.score, symbol: "heart.fill")
                        scoreCard("BEST", value: session.bestScore, symbol: "crown.fill")
                        Button { showHelp = true } label: {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(BerryStyle.strawberry)
                                .frame(width: 43, height: 58)
                                .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 15))
                        }.accessibilityLabel("How to play")
                    }
                    .padding(.top, 4)
                    HStack(spacing: 8) {
                        Text(session.lastMessage ?? "Clear rows & columns to earn berry bonuses!")
                            .lineLimit(1).minimumScaleFactor(0.7)
                        if session.engine.streak > 1 {
                            Text("×\(session.engine.streak)")
                                .foregroundStyle(BerryStyle.strawberry)
                        }
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .frame(height: 29)
                    .animation(.easeInOut(duration: 0.18), value: session.celebration)

                    BerryBoardView(engine: session.engine, preview: drag, size: boardSize)
                        .padding(7)
                        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 24))
                        .shadow(color: BerryStyle.strawberry.opacity(0.15), radius: 12, y: 5)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let slot = selectedSlot,
                                  let piece = session.engine.tray[slot] else { return }
                            let step = cell + 3
                            let col = Int(((location.x - 7) / step).rounded(.down))
                            let row = Int(((location.y - 7) / step).rounded(.down))
                            if session.drop(slot: slot, row: row, col: col) {
                                selectedSlot = nil
                                feedback()
                            } else if !session.engine.canPlace(piece, row: row, col: col) {
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            }
                        }
                    Text(selectedSlot == nil ? "DRAG A PIECE UP • OR TAP PIECE THEN BOARD" : "TAP A FREE SQUARE TO PLACE YOUR PIECE")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
                        .frame(height: 29)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    HStack(spacing: 9) {
                        ForEach(0..<3, id: \.self) { slot in
                            let piece = session.engine.tray[slot]
                            ZStack {
                                RoundedRectangle(cornerRadius: 17)
                                    .fill(selectedSlot == slot ? BerryStyle.softPink : Color.white.opacity(0.82))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 17)
                                            .strokeBorder(selectedSlot == slot ? BerryStyle.strawberry : BerryStyle.strawberry.opacity(0.15), lineWidth: 2)
                                    }
                                if let piece {
                                    BerryPieceGlyph(piece: piece, unit: min(20, (width - 90) / CGFloat(3 * max(piece.width, 3))))
                                        .opacity(drag?.slot == slot ? 0.3 : session.engine.hasPlacement(for: piece) ? 1 : 0.35)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BerryStyle.leaf.opacity(0.45))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 74)
                            .contentShape(Rectangle())
                            .onTapGesture { if piece != nil { selectedSlot = selectedSlot == slot ? nil : slot } }
                            .gesture(
                                DragGesture(minimumDistance: 5, coordinateSpace: .named("berry-playfield"))
                                    .onChanged { value in updateDrag(slot: slot, finger: value.location, cell: cell) }
                                    .onEnded { _ in finishDrag() }
                            )
                            .accessibilityLabel("Piece \(slot + 1)")
                        }
                    }
                    HStack {
                        Button { confirmRestart = true } label: {
                            Label("New Game", systemImage: "arrow.clockwise")
                        }
                        Spacer()
                        Text("LINES \(session.engine.totalLines)  •  MOVES \(session.engine.moves)")
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                        }.accessibilityLabel("Settings")
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .frame(height: 37)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 15)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .coordinateSpace(name: "berry-playfield")
            .onPreferenceChange(BoardFrameKey.self) { boardFrame = $0 }
        }
        .preferredColorScheme(.light)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showHelp) { helpSheet }
        .sheet(isPresented: $showSettings) { settingsSheet }
        .confirmationDialog("Start a new berry puzzle?", isPresented: $confirmRestart) {
            Button("New Game", role: .destructive) { session.newGame(); selectedSlot = nil; drag = nil }
            Button("Keep Playing", role: .cancel) { }
        } message: { Text("Your current board will be replaced. Your best score stays saved.") }
        .onChange(of: session.gameOver) { _, ended in showGameOver = ended }
        .onAppear { showGameOver = session.gameOver }
        .alert("Berry sweet run! 🍓", isPresented: $showGameOver) {
            Button("Play Again") { session.newGame(); selectedSlot = nil }
        } message: {
            Text("Score: \(session.engine.score) • Lines: \(session.engine.totalLines) • Best combo: ×\(session.engine.bestCombo). Try to beat your best!")
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            BerryGirlView().frame(width: 67, height: 69).clipped().accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("STRAWBERRY SWEET").font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(2).foregroundStyle(BerryStyle.leaf)
                Text("Berry Block Blast!")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.65).lineLimit(1)
                    .foregroundStyle(BerryStyle.strawberry)
                Text("ENDLESS BERRY GARDEN  🍓")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.7))
            }
            Spacer(minLength: 0)
        }
    }

    private func scoreCard(_ title: String, value: Int, symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .foregroundStyle(title == "BEST" ? .orange : BerryStyle.strawberry)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.6))
                Text(value.formatted()).font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(.white.opacity(0.83), in: RoundedRectangle(cornerRadius: 16))
    }

    private func updateDrag(slot: Int, finger: CGPoint, cell: CGFloat) {
        guard session.engine.tray.indices.contains(slot),
              let piece = session.engine.tray[slot] else { drag = nil; return }
        let step = cell + 3
        let x = finger.x - boardFrame.minX - CGFloat(piece.width) * step / 2
        let y = finger.y - boardFrame.minY - 45 - CGFloat(piece.height) * step / 2
        let col = Int((x / step).rounded())
        let row = Int((y / step).rounded())
        let hovering = boardFrame.insetBy(dx: -35, dy: -65).contains(finger)
        drag = BerryDrag(slot: slot, piece: piece, row: row, col: col,
                         hovering: hovering,
                         allowed: hovering && session.engine.canPlace(piece, row: row, col: col))
    }

    private func finishDrag() {
        defer { drag = nil }
        guard let drag, drag.allowed else { return }
        if session.drop(slot: drag.slot, row: drag.row, col: drag.col) {
            selectedSlot = nil
            feedback()
        }
    }

    private func feedback() {
        if haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        if sound { AudioServicesPlaySystemSound(1104) }
    }

    private var helpSheet: some View {
        VStack(spacing: 16) {
            Text("🍓").font(.system(size: 52))
            Text("How to Play").font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            Text("Drag a piece from the tray onto the 8 × 8 garden, or tap a piece and then tap the board. Fill complete rows or columns to clear them. All three pieces used? Three new ones arrive! Keep playing until no piece fits.")
                .multilineTextAlignment(.center)
            Text("Every tile scores 1 point. Line clears earn 10 × lines², multiplied by your combo (up to ×8). Clear again within three moves to keep the combo alive. Empty the board for +300!")
                .multilineTextAlignment(.center)
            Button("Let's Play!") { showHelp = false }
                .buttonStyle(.borderedProminent).tint(BerryStyle.strawberry)
        }
        .font(.system(size: 15, weight: .medium, design: .rounded))
        .foregroundStyle(BerryStyle.chocolate)
        .padding(25)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BerryStyle.cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private var settingsSheet: some View {
        VStack(spacing: 18) {
            Text("Berry Settings 🍓").font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            Toggle("Haptic feedback", isOn: $haptics)
            Toggle("Soft game sounds", isOn: $sound)
            Text("Your current game and personal best are saved automatically on this iPhone.")
                .font(.footnote).foregroundStyle(.secondary)
            Text("Berry Block Blast • v0.2.0 • Unofficial fan puzzle")
                .font(.footnote).foregroundStyle(.secondary)
            Button("Done") { showSettings = false }
                .buttonStyle(.borderedProminent).tint(BerryStyle.strawberry)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BerryStyle.cream.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}
