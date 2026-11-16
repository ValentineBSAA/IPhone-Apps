import SwiftUI
import UIKit

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
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .fill(Color(red: 0.68, green: 0.31, blue: 0.39).opacity(0.16))
                .padding(-8)
            ForEach(0..<64, id: \.self) { index in
                let row = index / 8
                let col = index % 8
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.white.opacity(0.68))
                    if let tint = engine.board[row][col] {
                        BerryTile(tint: tint)
                    }
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
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(preview.allowed ? Color.green : Color.red,
                                            lineWidth: 2)
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
        .accessibilityLabel("Eight by eight block puzzle board. Score: \(engine.score)")
    }
}

struct BerryGameView: View {
    @StateObject private var session = BerryGameSession()
    @State private var boardFrame: CGRect = .zero
    @State private var drag: BerryDrag?
    @State private var showHelp = false
    @State private var confirmRestart = false
    @AppStorage("berryblockblast.haptics") private var haptics = true

    var body: some View {
        GeometryReader { area in
            let compact = area.size.height < 740
            let boardSize = min(area.size.width - 54, area.size.height * (compact ? 0.43 : 0.46), 430)
            let cell = (boardSize - 21) / 8
            let space: CGFloat = compact ? 7 : 13
            ZStack {
                LinearGradient(colors: [Color(red: 1, green: 0.91, blue: 0.93),
                                        BerryStyle.cream, Color(red: 1, green: 0.89, blue: 0.88)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                // Soft floating confectionery decorations.
                Circle().fill(.white.opacity(0.36))
                    .frame(width: 190, height: 190).offset(x: -165, y: -310)
                Circle().fill(BerryStyle.softPink.opacity(0.40))
                    .frame(width: 165, height: 165).offset(x: 165, y: 250)

                VStack(spacing: space) {
                    HStack(spacing: 8) {
                        BerryGirlView()
                            .frame(width: compact ? 110 : 134, height: compact ? 116 : 143)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("STRAWBERRY SWEET")
                                .font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded))
                                .tracking(2.0)
                                .foregroundStyle(BerryStyle.leaf)
                            Text("Berry Block\nBlast!")
                                .font(.system(size: compact ? 29 : 35, weight: .black, design: .rounded))
                                .tracking(-1)
                                .lineSpacing(-5)
                                .foregroundStyle(BerryStyle.strawberry)
                                .minimumScaleFactor(0.8)
                            Text("A puzzle as sweet as pie  🍓")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        scoreCard(title: "SCORE", number: session.engine.score, icon: "heart.fill")
                        scoreCard(title: "BEST", number: session.bestScore, icon: "crown.fill")
                        Button { showHelp = true } label: {
                            Image(systemName: "questionmark")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(BerryStyle.strawberry)
                                .frame(width: 49, height: 66)
                                .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 19))
                        }
                        .accessibilityLabel("How to play")
                    }

                    if let message = session.lastMessage {
                        Text(message)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(BerryStyle.strawberry)
                            .frame(height: 16)
                            .transition(.scale.combined(with: .opacity))
                            .id(session.celebration)
                    } else {
                        Text("Fill a row or column for a berry bonus!")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(BerryStyle.chocolate.opacity(0.62))
                            .frame(height: 16)
                    }

                    BerryBoardView(engine: session.engine, preview: drag, size: boardSize)
                        .padding(8)
                        .background(.white.opacity(0.80), in: RoundedRectangle(cornerRadius: 26))
                        .overlay {
                            RoundedRectangle(cornerRadius: 26)
                                .strokeBorder(.white.opacity(0.90), lineWidth: 2)
                        }
                        .shadow(color: BerryStyle.strawberry.opacity(0.12), radius: 16, y: 10)

                    HStack {
                        Image(systemName: "hand.draw.fill")
                        Text("DRAG YOUR BERRY BLOCKS")
                    }
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.70))
                    .padding(.top, compact ? 0 : 2)

                    HStack(spacing: 9) {
                        ForEach(0..<3, id: \.self) { slot in
                            ZStack {
                                RoundedRectangle(cornerRadius: 19)
                                    .fill(Color.white.opacity(0.76))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 19)
                                            .strokeBorder(BerryStyle.strawberry.opacity(0.12), lineWidth: 1.5)
                                    }
                                if let piece = session.engine.tray[slot] {
                                    BerryPieceGlyph(piece: piece,
                                                    unit: min(compact ? 20 : 24,
                                                              (area.size.width - 85) / CGFloat(3 * max(piece.width, 3))))
                                        .opacity(drag?.slot == slot ? 0.28 : 1)
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(BerryStyle.leaf.opacity(0.35))
                                        .font(.system(size: 28))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: compact ? 75 : 92)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 2, coordinateSpace: .named("berry-playfield"))
                                    .onChanged { value in
                                        updateDrag(slot: slot, finger: value.location, cell: cell)
                                    }
                                    .onEnded { _ in finishDrag() }
                            )
                            .accessibilityLabel("Piece \(slot + 1). Drag onto the board.")
                        }
                    }

                    HStack {
                        Button {
                            confirmRestart = true
                        } label: {
                            Label("New Game", systemImage: "arrow.clockwise")
                        }
                        Spacer()
                        Text("V0.1.0  •  FAN PUZZLE")
                            .tracking(0.7)
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.69))
                    .padding(.horizontal, 5)
                    .padding(.top, compact ? 0 : 3)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.top, compact ? 5 : 10)
                .frame(maxWidth: 530)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .coordinateSpace(name: "berry-playfield")
            .onPreferenceChange(BoardFrameKey.self) { boardFrame = $0 }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showHelp) { helpSheet }
        .confirmationDialog("Start a fresh berry puzzle?", isPresented: $confirmRestart) {
            Button("New Game", role: .destructive) { session.newGame(); drag = nil }
            Button("Keep Playing", role: .cancel) { }
        } message: { Text("Your current board will be replaced. Your best score stays saved.") }
        .alert("Berry good run! 🍰", isPresented: Binding(
            get: { session.gameOver },
            set: { if !$0 && session.gameOver { /* keep the restart decision visible */ } }
        )) {
            Button("Play Again") { session.newGame() }
        } message: {
            Text("You scored \(session.engine.score) points. Ready for another round?")
        }
    }

    private func scoreCard(title: String, number: Int, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(title == "BEST" ? Color(red: 1, green: 0.66, blue: 0.26) : BerryStyle.strawberry)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1.1)
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.53))
                Text(number.formatted())
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 19))
    }

    private func updateDrag(slot: Int, finger: CGPoint, cell: CGFloat) {
        guard session.engine.tray.indices.contains(slot), let piece = session.engine.tray[slot] else {
            drag = nil
            return
        }
        let step = cell + 3
        // Lift the preview above the finger so it remains visible while dragging.
        let x = finger.x - boardFrame.minX - CGFloat(piece.width) * step * 0.5
        let y = finger.y - boardFrame.minY - 57 - CGFloat(piece.height) * step * 0.5
        let col = Int((x / step).rounded())
        let row = Int((y / step).rounded())
        let hovering = boardFrame.insetBy(dx: -32, dy: -75).contains(finger)
        drag = BerryDrag(slot: slot, piece: piece, row: row, col: col,
                         hovering: hovering,
                         allowed: hovering && session.engine.canPlace(piece, row: row, col: col))
    }

    private func finishDrag() {
        defer { drag = nil }
        guard let drag, drag.allowed else { return }
        if session.drop(slot: drag.slot, row: drag.row, col: drag.col), haptics {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private var helpSheet: some View {
        VStack(spacing: 20) {
            Text("🍓") .font(.system(size: 58))
            Text("How to Play")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.strawberry)
            Text("Drag one of the three berry blocks onto the 8 × 8 board. Fill a whole row or column to clear it. Clear several lines and make combos for extra points. When you use all three pieces, a fresh tray appears!")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 25)
            Toggle("Gentle haptic feedback", isOn: $haptics)
                .tint(BerryStyle.strawberry)
                .padding(.horizontal, 24)
            Text("Your score and unfinished game are saved on this iPhone.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Let's Play!") { showHelp = false }
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(BerryStyle.strawberry, in: Capsule())
                .padding(.horizontal, 28)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BerryStyle.cream.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
