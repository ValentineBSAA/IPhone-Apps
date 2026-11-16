import Foundation

struct BerryPoint: Hashable, Codable {
    let row: Int
    let col: Int
}

struct BerryPiece: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let points: [BerryPoint]
    let tint: Int

    var width: Int { (points.map(\.col).max() ?? 0) + 1 }
    var height: Int { (points.map(\.row).max() ?? 0) + 1 }
}

struct BerryPlacement: Equatable {
    let clearedRows: [Int]
    let clearedColumns: [Int]
    let earned: Int
    let streak: Int
    let boardClear: Bool
    var clearedLines: Int { clearedRows.count + clearedColumns.count }
}

struct BerryEngine: Codable {
    static let side = 8
    private(set) var board: [[Int?]] = Array(repeating: Array(repeating: nil, count: side), count: side)
    private(set) var tray: [BerryPiece?] = []
    private(set) var score = 0
    private(set) var streak = 0
    private(set) var moves = 0
    private(set) var totalLines = 0
    private(set) var bestCombo = 0
    private(set) var dryMoves = 0
    private(set) var boardClears = 0
    private var randomState: UInt64? = nil

    init() { refill() }
    init(seed: UInt64) {
        randomState = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        refill()
    }
    private mutating func nextRandom(_ upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        guard var state = randomState else { return Int.random(in: 0..<upperBound) }
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        randomState = state
        return Int((state &* 2685821657736338717) % UInt64(upperBound))
    }

    // Explicit initial state is useful for deterministic puzzle-rule tests.
    init(board: [[Int?]], tray: [BerryPiece?], score: Int = 0) {
        precondition(board.count == Self.side && board.allSatisfy { $0.count == Self.side })
        precondition(tray.count == 3)
        self.board = board
        self.tray = tray
        self.score = score
    }

    func canPlace(_ piece: BerryPiece, row: Int, col: Int) -> Bool {
        for p in piece.points {
            let r = row + p.row
            let c = col + p.col
            guard (0..<Self.side).contains(r), (0..<Self.side).contains(c), board[r][c] == nil else {
                return false
            }
        }
        return true
    }

    func hasPlacement(for piece: BerryPiece) -> Bool {
        (0..<Self.side).contains { row in
            (0..<Self.side).contains { col in canPlace(piece, row: row, col: col) }
        }
    }

    func hasMove() -> Bool {
        for piece in tray.compactMap({ $0 }) {
            for row in 0..<Self.side {
                for col in 0..<Self.side where canPlace(piece, row: row, col: col) { return true }
            }
        }
        return false
    }

    @discardableResult
    mutating func place(slot: Int, row: Int, col: Int) -> BerryPlacement? {
        guard tray.indices.contains(slot), let piece = tray[slot], canPlace(piece, row: row, col: col) else { return nil }
        for point in piece.points { board[row + point.row][col + point.col] = piece.tint }
        tray[slot] = nil
        moves += 1

        let rows = (0..<Self.side).filter { r in board[r].allSatisfy { $0 != nil } }
        let cols = (0..<Self.side).filter { c in (0..<Self.side).allSatisfy { board[$0][c] != nil } }
        let lines = rows.count + cols.count
        if lines > 0 {
            streak += 1
            dryMoves = 0
            totalLines += lines
            bestCombo = max(bestCombo, streak)
            for r in rows { for c in 0..<Self.side { board[r][c] = nil } }
            for c in cols { for r in 0..<Self.side { board[r][c] = nil } }
        } else {
            dryMoves += 1
            if dryMoves >= 3 { streak = 0 }
        }
        let boardClear = lines > 0 && board.flatMap { $0 }.allSatisfy { $0 == nil }
        if boardClear { boardClears += 1 }
        let earned = piece.points.count + (lines > 0 ? 10 * lines * lines * min(streak, 8) : 0) + (boardClear ? 300 : 0)
        score += earned
        if tray.allSatisfy({ $0 == nil }) { refill() }
        return BerryPlacement(clearedRows: rows, clearedColumns: cols, earned: earned, streak: streak, boardClear: boardClear)
    }

    mutating func reshuffleTray() {
        refill()
    }

    private mutating func refill() {
        let catalog: [[BerryPoint]] = [
            [BerryPoint(0,0)], [BerryPoint(0,0),BerryPoint(0,1)], [BerryPoint(0,0),BerryPoint(1,0)],
            [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(0,2)], [BerryPoint(0,0),BerryPoint(1,0),BerryPoint(2,0)],
            [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(1,0),BerryPoint(1,1)],
            [BerryPoint(0,0),BerryPoint(1,0),BerryPoint(1,1)], [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(1,1)],
            [BerryPoint(0,0),BerryPoint(1,0),BerryPoint(2,0),BerryPoint(3,0)], [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(0,2),BerryPoint(0,3)],
            [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(0,2),BerryPoint(1,1)], [BerryPoint(0,1),BerryPoint(1,0),BerryPoint(1,1),BerryPoint(1,2)],
            [BerryPoint(0,0),BerryPoint(1,0),BerryPoint(2,0),BerryPoint(2,1)], [BerryPoint(0,1),BerryPoint(1,1),BerryPoint(2,0),BerryPoint(2,1)],
            [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(1,1),BerryPoint(1,2)], [BerryPoint(0,1),BerryPoint(0,2),BerryPoint(1,0),BerryPoint(1,1)],
            [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(0,2),BerryPoint(1,0),BerryPoint(1,1),BerryPoint(1,2)],
            [BerryPoint(0,0),BerryPoint(1,0),BerryPoint(2,0),BerryPoint(2,1),BerryPoint(2,2)],
            [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(1,0),BerryPoint(1,1),BerryPoint(2,0),BerryPoint(2,1)],
            [BerryPoint(0,0),BerryPoint(0,1),BerryPoint(0,2),BerryPoint(0,3),BerryPoint(0,4)],
            [BerryPoint(0,0),BerryPoint(1,0),BerryPoint(2,0),BerryPoint(3,0),BerryPoint(4,0)]
        ]
        // A newly dealt tray always contains at least one legal move. Prefer
        // several playable choices instead of handing out impossible pieces.
        let viable = catalog.filter { shape in
            let piece = BerryPiece(points: shape, tint: 0)
            return (0..<Self.side).contains { r in
                (0..<Self.side).contains { c in canPlace(piece, row: r, col: c) }
            }
        }
        tray = (0..<3).map { index in
            let pool = !viable.isEmpty && (index < 2 || nextRandom(2) == 0) ? viable : catalog
            let shape = pool[nextRandom(pool.count)]
            return BerryPiece(points: shape, tint: nextRandom(6))
        }
    }
}

private extension BerryPoint {
    init(_ row: Int, _ col: Int) { self.row = row; self.col = col }
}
