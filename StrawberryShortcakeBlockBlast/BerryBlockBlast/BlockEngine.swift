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
    /// Completed Sweet Endless gardens. Older saved games decode this as zero.
    private(set) var seasons = 0
    /// Four 12x12 sections in the 24x24 endless garden. Persisted with
    /// the existing engine save so older players keep their whole garden.
    private(set) var activeGardenSection = 0
    /// A patch blooms after 18 placements or three completed 12-cell lines,
    /// whichever happens first. Never require a permanently full board:
    /// completed rows automatically clear and would prevent that condition.
    private(set) var gardenPatchMoves = 0
    private(set) var gardenPatchLines = 0
    var visibleSide: Int { side == 24 ? 12 : side }
    var sectionOrigin: (row: Int, col: Int) {
        guard side == 24 else { return (0, 0) }
        let section = max(0, min(3, activeGardenSection))
        return ((section / 2) * 12, (section % 2) * 12)
    }
    /// A completed patch advances in reading order with no user interaction.
    /// Fourth patch completion starts a fresh garden season, keeping score.
    private mutating func advanceCompletedGardenPatch() {
        guard side == 24 else { return }
        gardenPatchMoves = 0
        gardenPatchLines = 0
        if activeGardenSection == 3 {
            activeGardenSection = 0
            board = Array(repeating: Array<Int?>(repeating: nil, count: 24), count: 24)
            seasons += 1
            streak = 0
            dryMoves = 0
            refill()
        } else {
            activeGardenSection += 1
            // Keep unplaced tray pieces, unless none fits the fresh section.
            if !hasMove() { refill() }
        }
    }

    private func origin(for section: Int) -> (row: Int, col: Int) {
        ((section / 2) * 12, (section % 2) * 12)
    }
    private func sectionHasFreeCell(_ section: Int) -> Bool {
        let start = origin(for: section)
        return (start.row..<(start.row + 12)).contains { row in
            (start.col..<(start.col + 12)).contains { col in board[row][col] == nil }
        }
    }
    func visibleCell(row: Int, col: Int) -> Int? {
        let origin = sectionOrigin
        guard (0..<visibleSide).contains(row), (0..<visibleSide).contains(col) else { return nil }
        return board[origin.row + row][origin.col + col]
    }

    private var randomState: UInt64? = nil
    private var cozyPieces: Bool? = nil
    private var hardPieces: Bool? = nil
    /// These optional fields decode to nil in all 0.5.x saves.
    private(set) var pantryPiece: BerryPiece? = nil
    private(set) var spyglassNext: BerryPiece? = nil

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
        case dryMoves, boardClears, seasons, activeGardenSection, gardenPatchMoves, gardenPatchLines, randomState, cozyPieces, side, hardPieces, pantryPiece, spyglassNext
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
        seasons = try values.decodeIfPresent(Int.self, forKey: .seasons) ?? 0
        activeGardenSection = min(3, max(0, try values.decodeIfPresent(Int.self, forKey: .activeGardenSection) ?? 0))
        gardenPatchMoves = max(0, try values.decodeIfPresent(Int.self, forKey: .gardenPatchMoves) ?? 0)
        gardenPatchLines = max(0, try values.decodeIfPresent(Int.self, forKey: .gardenPatchLines) ?? 0)
        randomState = try values.decodeIfPresent(UInt64.self, forKey: .randomState)
        cozyPieces = try values.decodeIfPresent(Bool.self, forKey: .cozyPieces)
        pantryPiece = try values.decodeIfPresent(BerryPiece.self, forKey: .pantryPiece)
        spyglassNext = try values.decodeIfPresent(BerryPiece.self, forKey: .spyglassNext)
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

    private func canPlace(_ piece: BerryPiece, row: Int, col: Int, section: Int) -> Bool {
        guard !piece.points.isEmpty, Set(piece.points).count == piece.points.count else { return false }
        let start = side == 24 ? origin(for: section) : (row: 0, col: 0)
        let limit = side == 24 ? 12 : side
        for p in piece.points {
            let r = row + p.row, c = col + p.col
            guard (start.row..<(start.row + limit)).contains(r),
                  (start.col..<(start.col + limit)).contains(c),
                  board[r][c] == nil else { return false }
        }
        return true
    }

    func canPlace(_ piece: BerryPiece, row: Int, col: Int) -> Bool {
        canPlace(piece, row: row, col: col, section: activeGardenSection)
    }

    private func hasMove(in section: Int) -> Bool {
        let origin = side == 24 ? origin(for: section) : (row: 0, col: 0)
        let limit = side == 24 ? 12 : side
        for piece in tray.compactMap({ $0 }) {
            for row in origin.row..<(origin.row + limit) {
                for col in origin.col..<(origin.col + limit)
                where canPlace(piece, row: row, col: col, section: section) {
                    return true
                }
            }
        }
        return false
    }

    func hasPlacement(for piece: BerryPiece) -> Bool {
        (0..<side).contains { row in
            (0..<side).contains { col in canPlace(piece, row: row, col: col) }
        }
    }

    struct BerryHint: Equatable {
        let slot: Int
        let row: Int
        let col: Int
    }
    /// An accessibility guide for the scrolling 24x24 Endless board. Prefer
    /// a placement in the initial visible corner (roughly 12x12 cells) and
    /// only search the rest of the board if those positions are occupied.
    /// This never spends a purchased hint or modifies puzzle state.
    func suggestedEndlessMove() -> BerryHint? {
        guard side == 24 else { return suggestedMove() }
        let origin = sectionOrigin
        for row in origin.row..<(origin.row + 12) {
            for col in origin.col..<(origin.col + 12) {
                for (slot, candidate) in tray.enumerated() {
                    if let piece = candidate, canPlace(piece, row: row, col: col) {
                        return BerryHint(slot: slot, row: row, col: col)
                    }
                }
            }
        }
        return suggestedMove()
    }

    /// Offer a legal slot and exact position. Prefer completing lines; never
    /// rotate or resize pieces. Hint is advisory and does not place a piece.
    func suggestedMove() -> BerryHint? {
        var best: (value: Int, hint: BerryHint)?
        for (slot, optionalPiece) in tray.enumerated() {
            guard let piece = optionalPiece else { continue }
            for row in 0..<side {
                for col in 0..<side where canPlace(piece, row: row, col: col) {
                    let points = piece.points.map { BerryPoint(row: row + $0.row, col: col + $0.col) }
                    let rows = Set(points.map(\.row))
                    let cols = Set(points.map(\.col))
                    let completedRows = rows.filter { r in
                        (0..<side).allSatisfy { c in board[r][c] != nil || points.contains(BerryPoint(row: r, col: c)) }
                    }.count
                    let completedCols = cols.filter { c in
                        (0..<side).allSatisfy { r in board[r][c] != nil || points.contains(BerryPoint(row: r, col: c)) }
                    }.count
                    let value = (completedRows + completedCols) * 1000 + piece.points.count
                    if best == nil || value > best!.value {
                        best = (value, BerryHint(slot: slot, row: row, col: col))
                    }
                }
            }
        }
        return best?.hint
    }

    /// Permanent pantry reserve and paid tools use these safe operations.
    /// Failures NEVER change board state or consume inventory.
    @discardableResult
    mutating func removeOneOccupiedCell(row: Int, col: Int) -> Bool {
        guard (0..<side).contains(row), (0..<side).contains(col),
              board[row][col] != nil else { return false }
        board[row][col] = nil
        return true
    }

    @discardableResult
    mutating func plantOneSeed(row: Int, col: Int) -> BerryPlacement? {
        guard (0..<side).contains(row), (0..<side).contains(col),
              board[row][col] == nil else { return nil }
        board[row][col] = 0
        let origin = sectionOrigin
        let rowRange = origin.row..<(origin.row + visibleSide)
        let colRange = origin.col..<(origin.col + visibleSide)
        let rows = rowRange.filter { row in colRange.allSatisfy { board[row][$0] != nil } }
        let columns = colRange.filter { col in rowRange.allSatisfy { board[$0][col] != nil } }
        let cleared = rows.count + columns.count
        if cleared > 0 {
            totalLines += cleared
            streak += 1
            dryMoves = 0
            bestCombo = max(streak, bestCombo)
            for r in rows { for c in colRange { board[r][c] = nil } }
            for c in columns { for r in rowRange { board[r][c] = nil } }
        }
        moves += 1
        let bonus = cleared * 10
        score += 1 + bonus
        let clear = cleared > 0 && rowRange.allSatisfy { row in
            colRange.allSatisfy { board[row][$0] == nil }
        }
        if clear { boardClears += 1 }
        return BerryPlacement(clearedRows: rows, clearedColumns: columns,
                              earned: 1 + bonus, streak: streak, boardClear: clear)
    }

    @discardableResult
    mutating func rotateTrayPiece(slot: Int) -> Bool {
        guard tray.indices.contains(slot), let piece = tray[slot] else { return false }
        let rotated = piece.points.map { BerryPoint(row: $0.col,
                                                      col: piece.height - 1 - $0.row) }
        let minRow = rotated.map(\.row).min() ?? 0
        let minCol = rotated.map(\.col).min() ?? 0
        let normalized = rotated.map {
            BerryPoint(row: $0.row - minRow, col: $0.col - minCol)
        }
        guard Set(normalized) != Set(piece.points) else { return false }
        let newPiece = BerryPiece(points: normalized, tint: piece.tint)
        guard hasPlacement(for: newPiece) else { return false }
        tray[slot] = newPiece
        return true
    }

    @discardableResult
    mutating func swapPantry(slot: Int) -> Bool {
        guard tray.indices.contains(slot), tray[slot] != nil || pantryPiece != nil else { return false }
        let old = tray[slot]
        tray[slot] = pantryPiece
        pantryPiece = old
        // If the last piece was stashed, deal a fresh tray instead of
        // declaring a loss while the pantry contains a valid reserve.
        if tray.allSatisfy({ $0 == nil }) { refill() }
        return true
    }

    func hasMove() -> Bool { hasMove(in: activeGardenSection) }

    @discardableResult
    mutating func place(slot: Int, row: Int, col: Int) -> BerryPlacement? {
        guard tray.indices.contains(slot), let piece = tray[slot], canPlace(piece, row: row, col: col) else { return nil }
        for point in piece.points { board[row + point.row][col + point.col] = piece.tint }
        tray[slot] = nil
        moves += 1

        let origin = sectionOrigin
        let rowRange = origin.row..<(origin.row + visibleSide)
        let colRange = origin.col..<(origin.col + visibleSide)
        let rows = rowRange.filter { row in colRange.allSatisfy { board[row][$0] != nil } }
        let cols = colRange.filter { col in rowRange.allSatisfy { board[$0][col] != nil } }
        let lines = rows.count + cols.count
        if lines > 0 {
            streak += 1
            dryMoves = 0
            totalLines += lines
            bestCombo = max(bestCombo, streak)
            for r in rows { for c in colRange { board[r][c] = nil } }
            for c in cols { for r in rowRange { board[r][c] = nil } }
        } else {
            dryMoves += 1
            if dryMoves >= 3 { streak = 0 }
        }
        let boardClear = lines > 0 && rowRange.allSatisfy { row in
            colRange.allSatisfy { board[row][$0] == nil }
        }
        if boardClear { boardClears += 1 }
        // Classic baseline: one line 10, two lines 20, three lines 60,
        // four lines 120, multiplied by the current clearing streak.
        // Other published app versions may use conditional score modifiers.
        let lineBase = lines <= 1 ? 10 * lines : 10 * lines * (lines - 1)
        let earned = piece.points.count + lineBase * min(streak, 8) + (boardClear ? 300 : 0)
        score += earned
        if side == 24 {
            gardenPatchMoves += 1
            gardenPatchLines += lines
            if gardenPatchMoves >= 18 || gardenPatchLines >= 3 {
                advanceCompletedGardenPatch()
            }
        }
        if tray.allSatisfy({ $0 == nil }) { refill() }
        return BerryPlacement(clearedRows: rows, clearedColumns: cols, earned: earned, streak: streak, boardClear: boardClear)
    }

    /// A paid shuffle must never spend a helper without creating a legal move.
    /// It can rescue isolated free cells by offering a one-square piece.
    @discardableResult
    mutating func reshuffleTray() -> Bool {
        guard side == 24 ? sectionHasFreeCell(activeGardenSection) :
              board.contains(where: { $0.contains(nil) }) else { return false }
        refill()
        if !hasMove() {
            tray[0] = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: nextRandom(6))
        }
        return hasMove()
    }

    /// Timed Blitz must only end when its timer reaches zero.
    /// A stuck tray gets a complimentary legal reroll; a completely filled
    /// board starts fresh without losing the run score or remaining time.
    @discardableResult
    mutating func beginNextTimedBoardIfStuck() -> Bool {
        guard !hasMove() else { return false }
        if !reshuffleTray() {
            board = Array(repeating: Array<Int?>(repeating: nil, count: side), count: side)
            tray = []
            streak = 0
            dryMoves = 0
            refill()
        }
        return hasMove()
    }

    var canRescueWithShuffle: Bool {
        board.contains { $0.contains(nil) }
    }

    /// Endless has no terminal loss. A stuck tray is NOT a reason to charge
    /// for Shuffle or erase a saved garden: replace all three pieces with
    /// legal shapes, preserving the board, score, lines, moves and inventory.
    /// If a corrupted legacy save has a completely full board, begin a new
    /// garden season while retaining the accumulated run and its records.
    @discardableResult
    mutating func beginNextEndlessSeasonIfStuck() -> Bool {
        guard !hasMove() else { return false }
        if side == 24 {
            // First try another section using the existing hand. This is
            // a fully automatic, between-turn switch, never a scroll view.
            for offset in 1..<4 {
                let next = (activeGardenSection + offset) % 4
                if hasMove(in: next) {
                    activeGardenSection = next
                    return true
                }
            }
            // If nothing fits anywhere, advance to the next section with
            // space and deal a free playable hand. No purchase required.
            for offset in 1..<4 {
                let next = (activeGardenSection + offset) % 4
                guard sectionHasFreeCell(next) else { continue }
                activeGardenSection = next
                refill()
                if !hasMove() { forcePlayableEndlessHand() }
                return hasMove()
            }
            // Only the current section still has free cells.
            if sectionHasFreeCell(activeGardenSection) {
                refill()
                if !hasMove() { forcePlayableEndlessHand() }
                return hasMove()
            }
            // All four 12x12 sections are fully occupied. Start a new
            // season without resetting score, line count, moves or berries.
            board = Array(repeating: Array<Int?>(repeating: nil, count: 24), count: 24)
            activeGardenSection = 0
            gardenPatchMoves = 0
            gardenPatchLines = 0
            seasons += 1
            streak = 0
            dryMoves = 0
            refill()
            return hasMove()
        }
        // The older 8x8 and 12x12 Endless rules stay unchanged.
        if board.contains(where: { $0.contains(nil) }) {
            refill()
            if !hasMove() { forcePlayableEndlessHand() }
        } else {
            board = Array(repeating: Array<Int?>(repeating: nil, count: side), count: side)
            streak = 0
            dryMoves = 0
            refill()
            seasons += 1
        }
        return hasMove()
    }

    /// Emergency hand for unusual older saves. Never consume berries, paid
    /// helpers, points, completed lines, achievements, or a saved position.
    private mutating func forcePlayableEndlessHand() {
        guard board.contains(where: { $0.contains(nil) }) else { return }
        let one = [BerryPoint(row: 0, col: 0)]
        let pair = [BerryPoint(row: 0, col: 0), BerryPoint(row: 0, col: 1)]
        tray = [
            BerryPiece(points: one, tint: nextRandom(6)),
            BerryPiece(points: one, tint: nextRandom(6)),
            BerryPiece(points: hasPlacement(for: BerryPiece(points: pair, tint: 0))
                       ? pair : one, tint: nextRandom(6))
        ]
    }

    /// Prefer a short, connected piece that fills an entire almost-complete
    /// row or column. No cells are automatically removed or placed for free:
    /// players still choose where to drop the offered puzzle shape.
    /// A one-square bridge also reaches disconnected near-finished rows.
    private func bestLineFinishingPiece() -> [BerryPoint]? {
        let start = sectionOrigin
        let rows = start.row..<(start.row + visibleSide)
        let cols = start.col..<(start.col + visibleSide)
        var best: [BerryPoint]?
        for row in rows {
            let gaps = cols.filter { board[row][$0] == nil }
            if !gaps.isEmpty && gaps.count <= 9 &&
                gaps.last! - gaps.first! + 1 == gaps.count {
                let points = gaps.map { BerryPoint(row: 0, col: $0 - gaps[0]) }
                if best == nil || points.count < best!.count { best = points }
            }
        }
        for col in cols {
            let gaps = rows.filter { board[$0][col] == nil }
            if !gaps.isEmpty && gaps.count <= 9 &&
                gaps.last! - gaps.first! + 1 == gaps.count {
                let points = gaps.map { BerryPoint(row: $0 - gaps[0], col: 0) }
                if best == nil || points.count < best!.count { best = points }
            }
        }
        return best
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
        // Newly dealt Endless hands contain legal choices, not just one
        // legal shape among two traps. Full-size giant pieces remain available
        // early, but thin rescue pieces become more frequent as space fills.
        // Mega Garden should offer small and medium pieces, not exclusively
        // impossible giant pieces. Existing larger shapes remain available.
        let selection = side == 24 ? (classicCatalog + nightmareShapes + megaShapes) :
            cozyPieces == true ? Array(catalog.prefix(8)) :
            hardPieces == true ? Array(catalog.filter { $0.count >= 5 }) + nightmareShapes : classicCatalog
        let viable = selection.filter { shape in
            hasPlacement(for: BerryPiece(points: shape, tint: 0))
        }
        let rowFinisher = side == 24 ? bestLineFinishingPiece() : nil
        var nextTray: [BerryPiece?] = []
        var used: [[BerryPoint]] = []
        var usedTints: Set<Int> = []
        for index in 0..<3 {
            let pool = side == 24 ? (!viable.isEmpty ? viable : [[BerryPoint(row: 0, col: 0)]]) :
                cozyPieces == true ? (!viable.isEmpty ? viable : selection) :
                hardPieces == true ? (!viable.isEmpty ? viable : selection) :
                (!viable.isEmpty && (index < 2 || nextRandom(2) == 0) ? viable : classicCatalog)
            // A full hand should not repeat the identical L/line three times.
            let unique = pool.filter { candidate in !used.contains(candidate) }
            let choices = unique.isEmpty ? pool : unique
            // As a large Endless board fills, always offer a practical small
            // piece in the tray. A near-finished line gets a bridge piece.
            // No other modes have their difficulty rules changed.
            let shape: [BerryPoint]
            if side == 24 && index == 0, let finishing = rowFinisher,
                hasPlacement(for: BerryPiece(points: finishing, tint: 0)) {
                shape = finishing
            } else if side == 24 && index == 0 &&
                        (sectionOrigin.row..<(sectionOrigin.row + visibleSide)).reduce(0) { total, row in
                            total + (sectionOrigin.col..<(sectionOrigin.col + visibleSide)).reduce(0) {
                                $0 + (board[row][$1] == nil ? 0 : 1)
                            }
                        } > (visibleSide * visibleSide) / 3) {
                let small = viable.filter { $0.count <= 3 }
                shape = small.isEmpty ? [BerryPoint(row: 0, col: 0)] :
                    small[nextRandom(small.count)]
            } else {
                shape = choices[nextRandom(choices.count)]
            }
            used.append(shape)
            let freshTints = (0..<6).filter { !usedTints.contains($0) }
            let tint = freshTints.isEmpty ? nextRandom(6) : freshTints[nextRandom(freshTints.count)]
            usedTints.insert(tint)
            nextTray.append(BerryPiece(points: shape, tint: tint))
        }
        if side == 24 && board.contains(where: { $0.contains(nil) }) {
            let start = sectionOrigin
            let occupied = (start.row..<(start.row + 12)).reduce(0) { total, row in
                total + (start.col..<(start.col + 12)).reduce(0) { count, col in
                    count + (board[row][col] == nil ? 0 : 1)
                }
            }
            // At 30% occupancy, protect a practical rescue slot. The other
            // two shapes stay varied and are still checked for legal fit.
            if occupied >= (visibleSide * visibleSide * 3) / 10 {
                let helpful = bestLineFinishingPiece() ?? [BerryPoint(row: 0, col: 0)]
                let legal = hasPlacement(for: BerryPiece(points: helpful, tint: 0))
                    ? helpful : [BerryPoint(row: 0, col: 0)]
                nextTray[0] = BerryPiece(points: legal, tint: nextRandom(6))
            }
            // Replace any remaining unusable pieces; a legal move hidden on
            // the far edge of the scrolling board must never be the sole hope.
            for slot in 1..<nextTray.count {
                if let piece = nextTray[slot], !hasPlacement(for: piece) {
                    nextTray[slot] = BerryPiece(
                        points: [BerryPoint(row: 0, col: 0)], tint: nextRandom(6))
                }
            }
        }
        tray = nextTray
        // Store a real forecast based on the same current piece catalog.
        // The preview is informational, with no change to puzzle balance.
        if let upcoming = selection.randomElement() {
            spyglassNext = BerryPiece(points: upcoming, tint: 1)
        }
    }
}

private extension BerryPoint {
    init(_ row: Int, _ col: Int) { self.row = row; self.col = col }
}
