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
    @Published private(set) var totalEarnedBerries = 0
    @Published private(set) var rewardsLog: [String] = UserDefaults.standard.stringArray(forKey: "berryblockblast.rewards.v1") ?? []
    @Published private(set) var cottageDecorations = UserDefaults.standard.integer(forKey: "berryblockblast.cottage.decorations")
    private var previous: BerryEngine?
    private var previousBerryEarnings = 0
    private var previousRewardEntry: String?
    private var activeMode: BerryMode = .endless
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
        }
    }
    func selectMode(_ mode: BerryMode) {
        activeMode = mode
        bestScore = UserDefaults.standard.integer(forKey: mode == .superHard ? nightmareBestKey : bestKey)
        if mode == .endless {
            if let data = UserDefaults.standard.data(forKey: saveKey),
               let snapshot = try? JSONDecoder().decode(Save.self, from: data) { engine = snapshot.engine }
            else { engine = freshEngine() }
        } else if let data = UserDefaults.standard.data(forKey: modeKey(mode)),
                  let restored = try? JSONDecoder().decode(BerryEngine.self, from: data) { engine = restored }
        else { engine = freshEngine() }
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
        guard activeMode == .daily else { return BerryEngine() }
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let number = (components.year ?? 2026) * 10000 + (components.month ?? 1) * 100 + (components.day ?? 1)
        return BerryEngine(seed: UInt64(number))
    }
    private let saveKey = "berryblockblast.saved-game.v3"
    private let bestKey = "berryblockblast.best-score.v1"
    private let nightmareBestKey = "berryblockblast.nightmare.best-score.v1"
    private let inventoryKey = "berryblockblast.inventory.v3"

    private struct Inventory: Codable { var berries: Int; var undos: Int; var shuffles: Int; var totalEarnedBerries: Int }
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
            berries = saved.berries; undos = saved.undos; shuffles = saved.shuffles; totalEarnedBerries = saved.totalEarnedBerries
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
            UserDefaults.standard.set(bestScore, forKey: activeMode == .superHard ? nightmareBestKey : bestKey)
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
        gameOver = !engine.hasMove()
        save()
        return true
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
        gameOver = !engine.hasMove()
        lastMessage = "A little second chance! 💗"
        lastEarned = 0
        lastClearedLines = 0
        save()
        return revertedLines
    }

    func shuffle() {
        guard shuffles > 0 else { return }
        engine.reshuffleTray()
        shuffles -= 1
        gameOver = !engine.hasMove()
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        lastMessage = "Freshly picked berry blocks! 🍓"
        lastEarned = 0
        lastClearedLines = 0
        save()
    }

    func earn(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        berries += amount
        totalEarnedBerries += amount
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
        guard berries >= 50 else { return }
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

    var canUndo: Bool { undos > 0 && previous != nil }

    func newGame() {
        engine = freshEngine()
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        gameOver = false
        lastMessage = nil
        lastEarned = 0
        lastClearedLines = 0
        undos = max(undos, 2)
        shuffles = max(shuffles, 2)
        save()
    }

    private func save() {
        let inventory = Inventory(berries: berries, undos: undos, shuffles: shuffles, totalEarnedBerries: totalEarnedBerries)
        if let data = try? JSONEncoder().encode(inventory) { UserDefaults.standard.set(data, forKey: inventoryKey) }
        let snapshot = Save(engine: engine, berries: berries, undos: undos, shuffles: shuffles, totalEarnedBerries: totalEarnedBerries)
        if activeMode == .endless {
            if let data = try? JSONEncoder().encode(snapshot) { UserDefaults.standard.set(data, forKey: saveKey) }
        } else if let data = try? JSONEncoder().encode(engine) {
            UserDefaults.standard.set(data, forKey: modeKey(activeMode))
        }
    }
}
