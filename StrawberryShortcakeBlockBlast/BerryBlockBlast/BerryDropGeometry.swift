import Foundation

/// Maps the physical finger location to a board origin; all coordinates are global.
enum BerryDropGeometry {
    /// One unchanging lifted finger anchor for the entire drag.
    /// Tap-to-place uses `target` directly with unlifted coordinates.
    /// Never switch anchors based on which location happens to be legal.
    static func candidates(for finger: CGPoint, board: CGRect, piece: BerryPiece,
                           side: Int) -> [(row: Int, col: Int)] {
        guard board.width > 0 else { return [] }
        let lift = min(CGFloat(84), max(CGFloat(46), board.width * 0.19))
        let liftedFinger = CGPoint(x: finger.x, y: finger.y - lift)
        guard let result = target(for: liftedFinger, board: board, piece: piece,
                                  side: side) else { return [] }
        return [result]
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
