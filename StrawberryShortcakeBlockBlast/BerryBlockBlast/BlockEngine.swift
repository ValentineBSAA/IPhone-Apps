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
    static let classicSide = 8
    private(set) var side: Int = 8
    private(set) var board: [[Int?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    private(set) var tray: [BerryPiece?] = []
    private(set) var score = 0
    private(set) var streak = 0
    private(set) var moves = 0
    private(set) var totalLines = 0
    private(set) var bestCombo = 0
    private(set) var dryMoves = 0
    private(set) var boardClears = 0
    private var randomState: UInt64? = nil
    private var cozyPieces: Bool? = nil
    private var hardPieces: Bool? = nil

    init() { refill() }
    init(side: Int, hard: Bool = false) {
        precondition(side == 8 || side == 12 || side == 24)
        self.side = side
        self.hardPieces = hard
        board = Array(repeating: Array(repeating: nil, count: side), count: side)
        refill()
    }
    init(cozy: Bool) {
        cozyPieces = cozy
        refill()
    }
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

    // Codable does not apply stored-property defaults when keys are absent.
    // Decode the optional mode metadata explicitly so older saves survive upgrades.
    private enum CodingKeys: String, CodingKey {
        case board, tray, score, streak, moves, totalLines, bestCombo
        case dryMoves, boardClears, randomState, cozyPieces, side, hardPieces
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        board = try values.decode([[Int?]].self, forKey: .board)
        side = try values.decodeIfPresent(Int.self, forKey: .side) ?? 8
        hardPieces = try values.decodeIfPresent(Bool.self, forKey: .hardPieces)
        tray = try values.decode([BerryPiece?].self, forKey: .tray)
        score = try values.decodeIfPresent(Int.self, forKey: .score) ?? 0
        streak = try values.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        moves = try values.decodeIfPresent(Int.self, forKey: .moves) ?? 0
        totalLines = try values.decodeIfPresent(Int.self, forKey: .totalLines) ?? 0
        bestCombo = try values.decodeIfPresent(Int.self, forKey: .bestCombo) ?? 0
        dryMoves = try values.decodeIfPresent(Int.self, forKey: .dryMoves) ?? 0
        boardClears = try values.decodeIfPresent(Int.self, forKey: .boardClears) ?? 0
        randomState = try values.decodeIfPresent(UInt64.self, forKey: .randomState)
        cozyPieces = try values.decodeIfPresent(Bool.self, forKey: .cozyPieces)
        guard (side == 8 || side == 12 || side == 24), board.count == side,
              board.allSatisfy({ $0.count == side }),
              tray.count == 3 else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                debugDescription: "Invalid Berry Block Blast board or tray dimensions"))
        }
    }

    // Explicit initial state is useful for deterministic puzzle-rule tests.
    init(board: [[Int?]], tray: [BerryPiece?], score: Int = 0, hard: Bool = false) {
        let dimension = board.count
        precondition((dimension == 8 || dimension == 12 || dimension == 24) && board.allSatisfy { $0.count == dimension })
        precondition(tray.count == 3)
        self.board = board
        self.side = dimension
        self.hardPieces = hard
        self.tray = tray
        self.score = score
    }

    func canPlace(_ piece: BerryPiece, row: Int, col: Int) -> Bool {
        guard !piece.points.isEmpty, Set(piece.points).count == piece.points.count else { return false }
        for p in piece.points {
            let r = row + p.row
            let c = col + p.col
            guard (0..<side).contains(r), (0..<side).contains(c), board[r][c] == nil else {
                return false
            }
        }
        return true
    }

    func hasPlacement(for piece: BerryPiece) -> Bool {
        (0..<side).contains { row in
            (0..<side).contains { col in canPlace(piece, row: row, col: col) }
        }
    }

    func hasMove() -> Bool {
        for piece in tray.compactMap({ $0 }) {
            for row in 0..<side {
                for col in 0..<side where canPlace(piece, row: row, col: col) { return true }
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

        let rows = (0..<side).filter { r in board[r].allSatisfy { $0 != nil } }
        let cols = (0..<side).filter { c in (0..<side).allSatisfy { board[$0][c] != nil } }
        let lines = rows.count + cols.count
        if lines > 0 {
            streak += 1
            dryMoves = 0
            totalLines += lines
            bestCombo = max(bestCombo, streak)
            for r in rows { for c in 0..<side { board[r][c] = nil } }
            for c in cols { for r in 0..<side { board[r][c] = nil } }
        } else {
            dryMoves += 1
            if dryMoves >= 3 { streak = 0 }
        }
        let boardClear = lines > 0 && board.flatMap { $0 }.allSatisfy { $0 == nil }
        if boardClear { boardClears += 1 }
        // Classic baseline: one line 10, two lines 20, three lines 60,
        // four lines 120, multiplied by the current clearing streak.
        // Other published app versions may use conditional score modifiers.
        let lineBase = lines <= 1 ? 10 * lines : 10 * lines * (lines - 1)
        let earned = piece.points.count + lineBase * min(streak, 8) + (boardClear ? 300 : 0)
        score += earned
        if tray.allSatisfy({ $0 == nil }) { refill() }
        return BerryPlacement(clearedRows: rows, clearedColumns: cols, earned: earned, streak: streak, boardClear: boardClear)
    }

    mutating func reshuffleTray() {
        refill()
    }

    private mutating func refill() {
        let catalog: [[BerryPoint]] = [
            [BerryPoint(row: 0, col: 0)], [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1)], [BerryPoint(row: 0, col: 0),BerryPoint(row: 1, col: 0)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 0, col: 2)], [BerryPoint(row: 0, col: 0),BerryPoint(row: 1, col: 0),BerryPoint(row: 2, col: 0)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 1, col: 0),BerryPoint(row: 1, col: 1)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 1, col: 0),BerryPoint(row: 1, col: 1)], [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 1, col: 1)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 1, col: 0),BerryPoint(row: 2, col: 0),BerryPoint(row: 3, col: 0)], [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 0, col: 2),BerryPoint(row: 0, col: 3)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 0, col: 2),BerryPoint(row: 1, col: 1)], [BerryPoint(row: 0, col: 1),BerryPoint(row: 1, col: 0),BerryPoint(row: 1, col: 1),BerryPoint(row: 1, col: 2)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 1, col: 0),BerryPoint(row: 2, col: 0),BerryPoint(row: 2, col: 1)], [BerryPoint(row: 0, col: 1),BerryPoint(row: 1, col: 1),BerryPoint(row: 2, col: 0),BerryPoint(row: 2, col: 1)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 1, col: 1),BerryPoint(row: 1, col: 2)], [BerryPoint(row: 0, col: 1),BerryPoint(row: 0, col: 2),BerryPoint(row: 1, col: 0),BerryPoint(row: 1, col: 1)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 0, col: 2),BerryPoint(row: 1, col: 0),BerryPoint(row: 1, col: 1),BerryPoint(row: 1, col: 2)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 1, col: 0),BerryPoint(row: 2, col: 0),BerryPoint(row: 2, col: 1),BerryPoint(row: 2, col: 2)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 1, col: 0),BerryPoint(row: 1, col: 1),BerryPoint(row: 2, col: 0),BerryPoint(row: 2, col: 1)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 0, col: 1),BerryPoint(row: 0, col: 2),BerryPoint(row: 0, col: 3),BerryPoint(row: 0, col: 4)],
            [BerryPoint(row: 0, col: 0),BerryPoint(row: 1, col: 0),BerryPoint(row: 2, col: 0),BerryPoint(row: 3, col: 0),BerryPoint(row: 4, col: 0)]
        ]
        // Classic now includes the 3x3 square, 2x3/3x2 rectangles, corners
        // and zigzags. Old saved trays remain untouched; these appear on refill.
        let classicExtras: [[BerryPoint]] = [
            (0..<3).flatMap { r in (0..<3).map { c in BerryPoint(row: r, col: c) } },
            (0..<2).flatMap { r in (0..<3).map { c in BerryPoint(row: r, col: c) } },
            (0..<3).flatMap { r in (0..<2).map { c in BerryPoint(row: r, col: c) } },
            [BerryPoint(0, 0), BerryPoint(1, 0), BerryPoint(2, 0),
             BerryPoint(2, 1), BerryPoint(2, 2)],
            [BerryPoint(0, 2), BerryPoint(1, 2), BerryPoint(2, 0),
             BerryPoint(2, 1), BerryPoint(2, 2)],
            [BerryPoint(0, 0), BerryPoint(0, 1), BerryPoint(1, 1), BerryPoint(1, 2)],
            [BerryPoint(0, 1), BerryPoint(0, 2), BerryPoint(1, 0), BerryPoint(1, 1)],
            [BerryPoint(0, 0), BerryPoint(0, 1), BerryPoint(0, 2),
             BerryPoint(1, 0), BerryPoint(1, 2)],
            [BerryPoint(0, 0), BerryPoint(1, 0), BerryPoint(2, 0),
             BerryPoint(2, 1)],
            [BerryPoint(0, 1), BerryPoint(1, 1), BerryPoint(2, 1),
             BerryPoint(2, 0)]
        ]
        let classicCatalog = catalog + classicExtras

        // Nightmare uses genuinely larger shapes instead of just more empty
        // squares. These long and wide pieces demand deliberate space planning.
        let nightmareShapes: [[BerryPoint]] = [
            (0..<7).map { BerryPoint(row: 0, col: $0) },
            (0..<7).map { BerryPoint(row: $0, col: 0) },
            (0..<3).flatMap { row in (0..<3).map { col in BerryPoint(row: row, col: col) } },
            (0..<4).flatMap { row in (0..<2).map { col in BerryPoint(row: row, col: col) } },
            (0..<2).flatMap { row in (0..<4).map { col in BerryPoint(row: row, col: col) } },
            [BerryPoint(row: 0, col: 0), BerryPoint(row: 1, col: 0), BerryPoint(row: 2, col: 0), BerryPoint(row: 3, col: 0),
             BerryPoint(row: 3, col: 1), BerryPoint(row: 3, col: 2), BerryPoint(row: 3, col: 3)]
        ]
        // The 24x24 Mega Garden needs substantial pieces so full-line clears
        // remain achievable rather than requiring dozens of single cells.
        let megaShapes: [[BerryPoint]] = [
            (0..<4).flatMap { r in (0..<4).map { c in BerryPoint(row: r, col: c) } },
            (0..<5).flatMap { r in (0..<5).map { c in BerryPoint(row: r, col: c) } },
            (0..<3).flatMap { r in (0..<6).map { c in BerryPoint(row: r, col: c) } },
            (0..<6).flatMap { r in (0..<3).map { c in BerryPoint(row: r, col: c) } },
            (0..<2).flatMap { r in (0..<8).map { c in BerryPoint(row: r, col: c) } },
            (0..<8).flatMap { r in (0..<2).map { c in BerryPoint(row: r, col: c) } },
            (0..<9).map { BerryPoint(row: 0, col: $0) },
            (0..<9).map { BerryPoint(row: $0, col: 0) }
        ]
        // A newly dealt tray always contains at least one legal move. Prefer
        // several playable choices instead of handing out impossible pieces.
        let selection = side == 24 ? (nightmareShapes + megaShapes) :
            cozyPieces == true ? Array(catalog.prefix(8)) :
            hardPieces == true ? Array(catalog.filter { $0.count >= 5 }) + nightmareShapes : classicCatalog
        let viable = selection.filter { shape in
            let piece = BerryPiece(points: shape, tint: 0)
            return (0..<side).contains { r in
                (0..<side).contains { c in canPlace(piece, row: r, col: c) }
            }
        }
        var nextTray: [BerryPiece?] = []
        for index in 0..<3 {
            let pool = side == 24 ? (!viable.isEmpty ? viable : selection) :
                cozyPieces == true ? (!viable.isEmpty ? viable : selection) :
                hardPieces == true ? (!viable.isEmpty ? viable : selection) :
                (!viable.isEmpty && (index < 2 || nextRandom(2) == 0) ? viable : classicCatalog)
            let shape = pool[nextRandom(pool.count)]
            nextTray.append(BerryPiece(points: shape, tint: nextRandom(6)))
        }
        tray = nextTray
    }
}

private extension BerryPoint {
    init(_ row: Int, _ col: Int) { self.row = row; self.col = col }
}
