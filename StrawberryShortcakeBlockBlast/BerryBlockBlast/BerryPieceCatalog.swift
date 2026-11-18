import Foundation

/// Original shape catalog extracted verbatim; gameplay/scoring stays in BerryEngine.
enum BerryPieceCatalog {
    static let standard: [[BerryPoint]] = [
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
    static let classicExtras: [[BerryPoint]] = [
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
    static var classic: [[BerryPoint]] { standard + classicExtras }

        // Nightmare uses genuinely larger shapes instead of just more empty
        // squares. These long and wide pieces demand deliberate space planning.
    static let nightmare: [[BerryPoint]] = [
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
    static let mega: [[BerryPoint]] = [
            (0..<4).flatMap { r in (0..<4).map { c in BerryPoint(row: r, col: c) } },
            (0..<5).flatMap { r in (0..<5).map { c in BerryPoint(row: r, col: c) } },
            (0..<3).flatMap { r in (0..<6).map { c in BerryPoint(row: r, col: c) } },
            (0..<6).flatMap { r in (0..<3).map { c in BerryPoint(row: r, col: c) } },
            (0..<2).flatMap { r in (0..<8).map { c in BerryPoint(row: r, col: c) } },
            (0..<8).flatMap { r in (0..<2).map { c in BerryPoint(row: r, col: c) } },
            (0..<9).map { BerryPoint(row: 0, col: $0) },
            (0..<9).map { BerryPoint(row: $0, col: 0) }
        ]
}

private extension BerryPoint {
    init(_ row: Int, _ col: Int) { self.row = row; self.col = col }
}
