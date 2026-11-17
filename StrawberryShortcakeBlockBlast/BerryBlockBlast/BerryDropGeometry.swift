import Foundation

/// Maps the physical finger location to a board origin; all coordinates are global.
enum BerryDropGeometry {
    /// The original touch game lifts the piece above the thumb.
    /// Keep the unlifted alternative for direct-to-board dragging.
    static func candidates(for finger: CGPoint, board: CGRect, piece: BerryPiece,
                           side: Int) -> [(row: Int, col: Int)] {
        guard board.width > 0 else { return [] }
        let lift = min(CGFloat(84), max(CGFloat(46), board.width * 0.19))
        let positions = [CGPoint(x: finger.x, y: finger.y - lift), finger]
        var matches: [(row: Int, col: Int)] = []
        for point in positions {
            if let target = target(for: point, board: board, piece: piece, side: side),
               !matches.contains(where: { $0.row == target.row && $0.col == target.col }) {
                matches.append(target)
            }
        }
        return matches
    }

    static func target(for finger: CGPoint, board: CGRect, piece: BerryPiece,
                       side: Int, gap: CGFloat = 3) -> (row: Int, col: Int)? {
        guard side > 0, board.width > 0, board.height > 0,
              finger.x.isFinite, finger.y.isFinite, !piece.points.isEmpty else { return nil }
        let cell = (board.width - CGFloat(side - 1) * gap) / CGFloat(side)
        guard cell > 0 else { return nil }
        let step = cell + gap
        let margin = max(CGFloat(12), step * 0.6)
        guard board.insetBy(dx: -margin, dy: -margin).contains(finger) else { return nil }
        let minRow = piece.points.map(\.row).min() ?? 0
        let maxRow = piece.points.map(\.row).max() ?? 0
        let minCol = piece.points.map(\.col).min() ?? 0
        let maxCol = piece.points.map(\.col).max() ?? 0
        let col = Int(floor((finger.x - board.minX) / step - CGFloat(minCol + maxCol) / 2))
        let row = Int(floor((finger.y - board.minY) / step - CGFloat(minRow + maxRow) / 2))
        return (row, col)
    }
}
