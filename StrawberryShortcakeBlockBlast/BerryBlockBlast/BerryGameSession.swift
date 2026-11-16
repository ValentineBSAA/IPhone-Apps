import SwiftUI

@MainActor
final class BerryGameSession: ObservableObject {
    @Published private(set) var engine: BerryEngine
    @Published private(set) var bestScore: Int
    @Published private(set) var gameOver = false
    @Published private(set) var lastMessage: String? = nil
    @Published private(set) var celebration = 0
    @Published private(set) var lastEarned = 0
    @Published private(set) var berries = 0
    @Published private(set) var undos = 2
    @Published private(set) var shuffles = 2
    @Published private(set) var totalEarnedBerries = 0
    @Published private(set) var rewardsLog: [String] = UserDefaults.standard.stringArray(forKey: "berryblockblast.rewards.v1") ?? []
    private var previous: BerryEngine?
    private var activeMode: BerryMode = .endless
    private func modeKey(_ mode: BerryMode) -> String {
        switch mode {
        case .endless: saveKey
        case .story: "berryblockblast.story.engine.v1"
        case .daily: "berryblockblast.daily.engine." + Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        case .cozy: "berryblockblast.cozy.engine.v1"
        case .challenge: "berryblockblast.blitz.engine.v1"
        }
    }
    func selectMode(_ mode: BerryMode) {
        guard activeMode != mode else { return }
        activeMode = mode
        if mode == .endless {
            if let data = UserDefaults.standard.data(forKey: saveKey),
               let snapshot = try? JSONDecoder().decode(Save.self, from: data) { engine = snapshot.engine }
        } else if let data = UserDefaults.standard.data(forKey: modeKey(mode)),
                  let restored = try? JSONDecoder().decode(BerryEngine.self, from: data) { engine = restored }
        else { engine = BerryEngine() }
        previous = nil
        gameOver = !engine.hasMove()
        lastMessage = nil
    }

    private let saveKey = "berryblockblast.saved-game.v3"
    private let bestKey = "berryblockblast.best-score.v1"
    private let inventoryKey = "berryblockblast.inventory.v3"

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
    }

    @discardableResult
    func drop(slot: Int, row: Int, col: Int) -> Bool {
        guard !gameOver else { return false }
        let before = engine
        guard let outcome = engine.place(slot: slot, row: row, col: col) else { return false }
        previous = before
        if engine.score > bestScore {
            bestScore = engine.score
            UserDefaults.standard.set(bestScore, forKey: bestKey)
        }
        lastEarned = outcome.earned
        if outcome.clearedLines > 0 {
            let gained = outcome.clearedLines * 3 + (outcome.streak > 1 ? outcome.streak : 0) + (outcome.boardClear ? 25 : 0)
            earn(gained, reason: "Completed berry lines")
            celebration += 1
            lastMessage = outcome.boardClear ? "PERFECT GARDEN! +300 ✨" :
                outcome.clearedLines >= 3 ? "BERRY SPECTACULAR! ✨" :
                outcome.streak >= 2 ? "SWEET COMBO ×\(outcome.streak)! 🍓" : "BERRY DELICIOUS! 🍰"
        } else { lastMessage = nil }
        gameOver = !engine.hasMove()
        save()
        return true
    }

    func undo() {
        guard undos > 0, let previous else { return }
        engine = previous
        self.previous = nil
        undos -= 1
        gameOver = !engine.hasMove()
        lastMessage = "A little second chance! 💗"
        save()
    }

    func shuffle() {
        guard shuffles > 0 else { return }
        engine.reshuffleTray()
        shuffles -= 1
        gameOver = !engine.hasMove()
        previous = nil
        lastMessage = "Freshly picked berry blocks! 🍓"
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
        let day = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        awardOnce("daily-" + day, amount: 30, reason: "Daily Harvest")
    }
    func rewardStory(_ chapter: Int) {
        awardOnce("chapter-" + String(chapter), amount: 15 + min(35, chapter * 5), reason: "Story chapter")
    }
    func buyUndo() {
        guard berries >= 25 else { return }
        berries -= 25
        undos += 1
        save()
    }

    func buyShuffle() {
        guard berries >= 25 else { return }
        berries -= 25
        shuffles += 1
        save()
    }

    var canUndo: Bool { undos > 0 && previous != nil }

    func newGame() {
        engine = BerryEngine()
        previous = nil
        gameOver = false
        lastMessage = nil
        lastEarned = 0
        undos = max(undos, 2)
        shuffles = max(shuffles, 2)
        save()
    }

    private func save() {
        let snapshot = Save(engine: engine, berries: berries, undos: undos, shuffles: shuffles, totalEarnedBerries: totalEarnedBerries)
        if activeMode == .endless {
            if let data = try? JSONEncoder().encode(snapshot) { UserDefaults.standard.set(data, forKey: saveKey) }
        } else if let data = try? JSONEncoder().encode(engine) {
            UserDefaults.standard.set(data, forKey: modeKey(activeMode))
        }
    }
}
