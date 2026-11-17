import SwiftUI

@MainActor
final class BerryGameSession: ObservableObject {
    @Published private(set) var engine: BerryEngine
    @Published private(set) var bestScore: Int
    @Published private(set) var gameOver = false
    @Published private(set) var lastMessage: String? = nil
    @Published private(set) var celebration = 0
    @Published private(set) var lastEarned = 0
    @Published private(set) var lastClearedLines = 0
    @Published private(set) var berries = 0
    @Published private(set) var undos = 2
    @Published private(set) var shuffles = 2
    @Published private(set) var hints = 0
    @Published private(set) var totalEarnedBerries = 0
    @Published private(set) var rewardsLog: [String] = UserDefaults.standard.stringArray(forKey: "berryblockblast.rewards.v1") ?? []
    @Published private(set) var cottageDecorations = UserDefaults.standard.integer(forKey: "berryblockblast.cottage.decorations")
    @Published private(set) var ownedCosmetics = UserDefaults.standard.stringArray(forKey: "berryblockblast.shop.owned.v056b2") ?? []
    private var previous: BerryEngine?
    private var previousBerryEarnings = 0
    private var previousRewardEntry: String?
    private var activeMode: BerryMode = .endless
    static let classicSaveKey = "berryblockblast.classic.engine.v055"
    static let classicSavedFlagKey = "berryblockblast.classic.savedFlag.v056b2"
    private static let legacyEndlessSaveKey = "berryblockblast.saved-game.v3"
    private static let legacyEndlessV1Key = "berryblockblast.saved-game.v1"
    private static let legacyEndlessMigratedKey = "berryblockblast.endless.legacyMigrated.v056b2"

    /// One resumable MODE, Sweet Endless, with independent safe slots for
    /// 8×8, 12×12 and 24×24. Each size has its own personal-best score too.
    static func endlessSaveKey(side: Int) -> String {
        switch side {
        case 12: return "berryblockblast.endless.saved-12.v056b2"
        case 24: return "berryblockblast.endless.saved-24.v056b2"
        default: return "berryblockblast.endless.saved-8.v056b2"
        }
    }

    static func savedEndlessEngine(side: Int) -> BerryEngine? {
        guard [8, 12, 24].contains(side) else { return nil }
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: endlessSaveKey(side: side)),
           let snapshot = try? JSONDecoder().decode(BerryEngine.self, from: data),
           snapshot.side == side, snapshot.moves > 0 { return snapshot }

        // Restore the old Build 1 Sweet Endless board once, without writing
        // or deleting that original save. An intentional New Garden sets the
        // migration flag, so the legacy board cannot silently reappear.
        guard side == 8, !defaults.bool(forKey: legacyEndlessMigratedKey) else { return nil }
        if let data = defaults.data(forKey: legacyEndlessSaveKey),
           let snapshot = try? JSONDecoder().decode(Save.self, from: data),
           snapshot.engine.side == 8, snapshot.engine.moves > 0 {
            return snapshot.engine
        }
        if let data = defaults.data(forKey: legacyEndlessV1Key),
           let snapshot = try? JSONDecoder().decode(BerryEngine.self, from: data),
           snapshot.side == 8, snapshot.moves > 0 { return snapshot }
        return nil
    }

    static func hasResumableEndless(side: Int) -> Bool {
        savedEndlessEngine(side: side) != nil
    }
    static var hasResumableClassic: Bool {
        guard let data = UserDefaults.standard.data(forKey: classicSaveKey),
              let saved = try? JSONDecoder().decode(BerryEngine.self, from: data) else { return false }
        return saved.side == 8 && saved.moves > 0 && saved.hasMove()
    }

    static func dailyDateKey() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return String(format: "%04d-%02d-%02d", components.year ?? 2026, components.month ?? 1, components.day ?? 1)
    }
    private func modeKey(_ mode: BerryMode) -> String {
        switch mode {
        case .endless: saveKey
        case .story: "berryblockblast.story.engine.v1"
        case .daily: "berryblockblast.daily.engine." + Self.dailyDateKey()
        case .cozy: "berryblockblast.cozy.engine.v1"
        case .challenge: "berryblockblast.blitz.engine.v1"
        case .superHard: "berryblockblast.nightmare.engine.v1"
        case .classic: Self.classicSaveKey
        }
    }
    func selectMode(_ mode: BerryMode) {
        activeMode = mode
        let scoreKey = bestScoreKey(for: mode)
        // Preserve legacy scores for old modes only. The new 12×12 and 24×24
        // scoreboards must start independently, not inherit an 8×8 record.
        let hasNewBoardSize = mode == .endless &&
            [12, 24].contains(UserDefaults.standard.integer(forKey: "berryblockblast.endless.boardSize.v056b2"))
        if mode != .superHard && mode != .classic && mode != .challenge &&
           !hasNewBoardSize && UserDefaults.standard.object(forKey: scoreKey) == nil {
            // Earlier versions shared one best-score key for five modes.
            // Seed independent records from it so an upgrade never loses that number.
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: bestKey), forKey: scoreKey)
        }
        bestScore = UserDefaults.standard.integer(forKey: scoreKey)
        // Sweet Endless is the only mode that resumes its board. Keep legacy
        // Classic/non-Endless saves on disk for safe rollback, but never resume
        // them in this build. A selected garden size resumes only its own slot.
        let requestedSize = UserDefaults.standard.integer(forKey: "berryblockblast.endless.boardSize.v056b2")
        let size = [8, 12, 24].contains(requestedSize) ? requestedSize : 8
        if mode == .endless, let saved = Self.savedEndlessEngine(side: size) {
            engine = saved
            if size == 8 {
                UserDefaults.standard.set(true, forKey: Self.legacyEndlessMigratedKey)
                if let data = try? JSONEncoder().encode(saved) {
                    UserDefaults.standard.set(data, forKey: Self.endlessSaveKey(side: 8))
                }
            }
        } else {
            engine = freshEngine()
        }
        if mode == .endless && !engine.hasMove() {
            // Older saves can be stuck; rescue the run without losing its score.
            _ = engine.beginNextEndlessSeasonIfStuck()
            save()
        }
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        gameOver = !engine.hasMove()
        lastMessage = nil
        lastEarned = 0
        lastClearedLines = 0
    }

    private func freshEngine() -> BerryEngine {
        if activeMode == .cozy { return BerryEngine(cozy: true) }
        if activeMode == .superHard { return BerryEngine(side: 12, hard: true) }
        if activeMode == .endless {
            let requested = UserDefaults.standard.integer(forKey: "berryblockblast.endless.boardSize.v056b2")
            let side = [8, 12, 24].contains(requested) ? requested : 8
            return side == 8 ? BerryEngine() : BerryEngine(side: side, hard: side == 24)
        }
        guard activeMode == .daily else { return BerryEngine() }
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let number = (components.year ?? 2026) * 10000 + (components.month ?? 1) * 100 + (components.day ?? 1)
        return BerryEngine(seed: UInt64(number))
    }
    private let saveKey = "berryblockblast.saved-game.v3"
    private let bestKey = "berryblockblast.best-score.v1"
    private let nightmareBestKey = "berryblockblast.nightmare.best-score.v1"
    private func bestScoreKey(for mode: BerryMode) -> String {
        switch mode {
        case .endless:
            let side = UserDefaults.standard.integer(forKey: "berryblockblast.endless.boardSize.v056b2")
            return Self.endlessScoreKey(side: side)
        case .story: return "berryblockblast.story.best-score.v055"
        case .daily: return "berryblockblast.daily.best-score.v055"
        case .cozy: return "berryblockblast.cozy.best-score.v055"
        case .challenge: return BerryBlitzVariant.selected.bestScoreKey
        case .superHard: return nightmareBestKey
        case .classic: return "berryblockblast.classic.best-score.v055"
        }
    }
    static func endlessScoreKey(side: Int) -> String {
        switch side {
        case 12: return "berryblockblast.endless.best-12.v056b2"
        case 24: return "berryblockblast.endless.best-24.v056b2"
        default: return "berryblockblast.best-score.v1" // Existing 8×8 record.
        }
    }
    private let inventoryKey = "berryblockblast.inventory.v3"

    private struct Inventory: Codable {
        var berries: Int
        var undos: Int
        var shuffles: Int
        var totalEarnedBerries: Int
        var hints: Int
        private enum CodingKeys: String, CodingKey {
            case berries, undos, shuffles, totalEarnedBerries, hints
        }
        init(berries: Int, undos: Int, shuffles: Int, totalEarnedBerries: Int, hints: Int) {
            self.berries = berries; self.undos = undos; self.shuffles = shuffles
            self.totalEarnedBerries = totalEarnedBerries; self.hints = hints
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            berries = try c.decode(Int.self, forKey: .berries)
            undos = try c.decode(Int.self, forKey: .undos)
            shuffles = try c.decode(Int.self, forKey: .shuffles)
            totalEarnedBerries = try c.decode(Int.self, forKey: .totalEarnedBerries)
            hints = try c.decodeIfPresent(Int.self, forKey: .hints) ?? 0
        }
    }
    private struct Save: Codable {
        var engine: BerryEngine
        var berries: Int
        var undos: Int
        var shuffles: Int
        var totalEarnedBerries: Int
    }

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestKey)
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let restored = try? JSONDecoder().decode(Save.self, from: data),
           restored.engine.board.count == 8, restored.engine.board.allSatisfy({ $0.count == 8 }),
           restored.engine.tray.count == 3 {
            engine = restored.engine
            berries = restored.berries
            undos = restored.undos
            shuffles = restored.shuffles
            totalEarnedBerries = restored.totalEarnedBerries
        } else if let data = UserDefaults.standard.data(forKey: "berryblockblast.saved-game.v1"),
                  let restored = try? JSONDecoder().decode(BerryEngine.self, from: data),
                  restored.board.count == 8, restored.board.allSatisfy({ $0.count == 8 }), restored.tray.count == 3 {
            engine = restored
        } else { engine = BerryEngine() }
        gameOver = !engine.hasMove()
        if let inventory = UserDefaults.standard.data(forKey: inventoryKey), let saved = try? JSONDecoder().decode(Inventory.self, from: inventory) {
            berries = saved.berries; undos = saved.undos; shuffles = saved.shuffles; totalEarnedBerries = saved.totalEarnedBerries; hints = saved.hints
        }
    }

    @discardableResult
    func drop(slot: Int, row: Int, col: Int) -> Bool {
        guard !gameOver else { return false }
        let before = engine
        guard let outcome = engine.place(slot: slot, row: row, col: col) else { return false }
        previous = before
        previousBerryEarnings = 0
        previousRewardEntry = nil
        if engine.score > bestScore {
            bestScore = engine.score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey(for: activeMode))
        }
        lastEarned = outcome.earned
        lastClearedLines = outcome.clearedLines
        if outcome.clearedLines > 0 {
            let gained = outcome.clearedLines * 3 + (outcome.streak > 1 ? outcome.streak : 0) + (outcome.boardClear ? 25 : 0)
            previousBerryEarnings = gained
            earn(gained, reason: "Completed berry lines")
            previousRewardEntry = rewardsLog.first
            celebration += 1
            lastMessage = outcome.boardClear ? "PERFECT GARDEN! +300 ✨" :
                outcome.clearedLines >= 3 ? "BERRY SPECTACULAR! ✨" :
                outcome.streak >= 2 ? "SWEET COMBO ×\(outcome.streak)! 🍓" : "BERRY DELICIOUS! 🍰"
        } else { lastMessage = nil }
        let nextSeason = activeMode == .endless && !engine.hasMove() &&
            engine.beginNextEndlessSeasonIfStuck()
        if nextSeason {
            // Undoing across a renewed season would restore an unwinnable
            // full board. Keep the uninterrupted score and disable that undo.
            previous = nil
            previousBerryEarnings = 0
            previousRewardEntry = nil
            lastMessage = "🍓 A fresh berry season! Your score continues!"
        }
        // Never terminate a timed score chase just because the tray is stuck.
        // Keep score, records, moves and earned berries. Nightmare remains
        // deliberately unforgiving and may end when no legal move remains.
        if activeMode == .challenge && !engine.hasMove() {
            if engine.beginNextTimedBoardIfStuck() {
                previous = nil
                previousBerryEarnings = 0
                previousRewardEntry = nil
                lastMessage = "🍓 Fresh pieces! Keep racing the clock!"
            }
        }
        gameOver = !engine.hasMove()
        save()
        return true
    }

    /// A separate menu-level session can refresh currency after leaving play.
    func refreshEconomyFromDisk() {
        if let data = UserDefaults.standard.data(forKey: inventoryKey),
           let saved = try? JSONDecoder().decode(Inventory.self, from: data) {
            berries = saved.berries
            undos = saved.undos
            shuffles = saved.shuffles
            hints = saved.hints
            totalEarnedBerries = saved.totalEarnedBerries
        }
        ownedCosmetics = UserDefaults.standard.stringArray(forKey: "berryblockblast.shop.owned.v056b2") ?? []
        cottageDecorations = UserDefaults.standard.integer(forKey: "berryblockblast.cottage.decorations")
        rewardsLog = UserDefaults.standard.stringArray(forKey: "berryblockblast.rewards.v1") ?? []
    }

    @discardableResult
    func undo() -> Int {
        guard undos > 0, let previous else { return 0 }
        let revertedLines = max(0, engine.totalLines - previous.totalLines)
        engine = previous
        berries = max(0, berries - previousBerryEarnings)
        totalEarnedBerries = max(0, totalEarnedBerries - previousBerryEarnings)
        if let entry = previousRewardEntry, let index = rewardsLog.firstIndex(of: entry) {
            rewardsLog.remove(at: index)
            UserDefaults.standard.set(rewardsLog, forKey: "berryblockblast.rewards.v1")
        }
        previousRewardEntry = nil
        previousBerryEarnings = 0
        self.previous = nil
        undos -= 1
        if activeMode == .endless { _ = engine.beginNextEndlessSeasonIfStuck() }
        gameOver = !engine.hasMove()
        lastMessage = "A little second chance! 💗"
        lastEarned = 0
        lastClearedLines = 0
        save()
        return revertedLines
    }

    @discardableResult
    func shuffle() -> Bool {
        guard shuffles > 0, engine.canRescueWithShuffle else { return false }
        guard engine.reshuffleTray() else { return false }
        shuffles -= 1
        if activeMode == .endless { _ = engine.beginNextEndlessSeasonIfStuck() }
        gameOver = !engine.hasMove()
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        lastMessage = "Freshly picked berry blocks! 🍓"
        lastEarned = 0
        lastClearedLines = 0
        save()
        return true
    }

    func earn(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        berries = amount > Int.max - berries ? Int.max : berries + amount
        totalEarnedBerries = amount > Int.max - totalEarnedBerries ? Int.max : totalEarnedBerries + amount
        rewardsLog.insert("🍓 +\(amount) • \(reason)", at: 0)
        rewardsLog = Array(rewardsLog.prefix(20))
        UserDefaults.standard.set(rewardsLog, forKey: "berryblockblast.rewards.v1")
        save()
    }
    func awardOnce(_ name: String, amount: Int, reason: String) {
        let key = "berryblockblast.award." + name
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        earn(amount, reason: reason)
    }
    func rewardTutorial() { awardOnce("tutorial", amount: 25, reason: "Strawberry School") }
    func rewardDaily() {
        let day = Self.dailyDateKey()
        awardOnce("daily-" + day, amount: 30, reason: "Daily Harvest")
    }
    func rewardStory(_ chapter: Int) {
        awardOnce("chapter-" + String(chapter), amount: 15 + min(35, chapter * 5), reason: "Story chapter")
    }
    func buyCottageDecoration() {
        // There are six unique Cottage upgrades. Earlier buyers with more
        // decorations keep them, but never spend berries for a duplicate.
        guard berries >= 50, cottageDecorations < 6 else { return }
        // Purchases must invalidate the undo snapshot to prevent currency duplication.
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        berries -= 50
        cottageDecorations += 1
        UserDefaults.standard.set(cottageDecorations, forKey: "berryblockblast.cottage.decorations")
        save()
    }
    func buyUndo() {
        guard berries >= 25 else { return }
        // Purchases must invalidate the undo snapshot to prevent currency duplication.
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        berries -= 25
        undos += 1
        save()
    }

    func buyShuffle() {
        guard berries >= 25 else { return }
        // Purchases must invalidate the undo snapshot to prevent currency duplication.
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        berries -= 25
        shuffles += 1
        save()
    }

    func buyHint() {
        guard berries >= 20 else { return }
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        berries -= 20
        hints += 1
        save()
    }

    @discardableResult
    func useHintIfPossible() -> BerryEngine.BerryHint? {
        guard hints > 0, !gameOver, let hint = engine.suggestedMove() else { return nil }
        hints -= 1
        save()
        return hint
    }

    var canUndo: Bool { undos > 0 && previous != nil }

    func newGame() {
        if activeMode == .endless && engine.side == 8 {
            // A deliberate restart must not resurrect the old pre-Build-2 save.
            UserDefaults.standard.set(true, forKey: Self.legacyEndlessMigratedKey)
        }
        engine = freshEngine()
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        gameOver = false
        lastMessage = nil
        lastEarned = 0
        lastClearedLines = 0
        // Existing helper counts remain untouched. Replaying a chapter must
        // not mint new free inventory or undermine the earned berry economy.
        save()
    }

    /// Shop purchases are cosmetics only. Core rules and Berry Classic scoring
    /// never depend on purchases; old earned strawberries remain spendable.
    func buyCosmetic(id: String, cost: Int) -> Bool {
        let valid: [String:Int] = ["strawberry-fruit":0,"blueberry-blocks":90,"vanilla-blocks":90,
            "rose-border":75,"mint-border":75,"berry-sparkle":100,
            "raspberry-blocks":110,"lemon-blocks":110,"chocolate-blocks":120,
            "mint-blocks":110,"blackberry-blocks":130]
        guard valid[id] == cost, cost >= 0, berries >= cost,
              !ownedCosmetics.contains(id) else { return false }
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        berries -= cost
        ownedCosmetics.append(id)
        UserDefaults.standard.set(ownedCosmetics, forKey: "berryblockblast.shop.owned.v056b2")
        rewardsLog.insert("🧺 -\(cost) • Berry Boutique: \(id)", at: 0)
        rewardsLog = Array(rewardsLog.prefix(20))
        UserDefaults.standard.set(rewardsLog, forKey: "berryblockblast.rewards.v1")
        save()
        return true
    }

    private func save() {
        let inventory = Inventory(berries: berries, undos: undos, shuffles: shuffles,
                                  totalEarnedBerries: totalEarnedBerries, hints: hints)
        if let data = try? JSONEncoder().encode(inventory) { UserDefaults.standard.set(data, forKey: inventoryKey) }
        // Only Sweet Endless persists an unfinished board. Each board size
        // keeps its own ongoing run. Original Build 1 and Classic save keys
        // are never overwritten, which preserves the stable rollback.
        guard activeMode == .endless else { return }
        let key = Self.endlessSaveKey(side: engine.side)
        if engine.moves > 0, let data = try? JSONEncoder().encode(engine) {
            UserDefaults.standard.set(data, forKey: key)
        } else if engine.moves == 0 {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
