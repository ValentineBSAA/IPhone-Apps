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
    var clearedLines: Int { clearedRows.count + clearedColumns.count }
}

struct BerryEngine: Codable {
    static let side = 8
    private(set) var board: [[Int?]] = Array(repeating: Array(repeating: nil, count: side), count: side)
    private(set) var tray: [BerryPiece?] = []
    private(set) var score = 0
    private(set) var streak = 0
    private(set) var moves = 0

    init() { refill() }

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
            for r in rows { for c in 0..<Self.side { board[r][c] = nil } }
            for c in cols { for r in 0..<Self.side { board[r][c] = nil } }
        } else {
            streak = 0
        }
        let earned = piece.points.count + lines * 12 + max(0, lines - 1) * 8 + (lines > 0 ? max(0, streak - 1) * 8 : 0)
        score += earned
        if tray.allSatisfy({ $0 == nil }) { refill() }
        return BerryPlacement(clearedRows: rows, clearedColumns: cols, earned: earned, streak: streak)
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
        tray = (0..<3).map { _ in
            let shape = catalog.randomElement() ?? [BerryPoint(row: 0, col: 0)]
            return BerryPiece(points: shape, tint: Int.random(in: 0..<6))
        }
    }
}

private extension BerryPoint {
    init(_ row: Int, _ col: Int) { self.row = row; self.col = col }
}
