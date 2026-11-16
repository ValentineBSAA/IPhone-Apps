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
    private var previous: BerryEngine?
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
            berries += gained
            totalEarnedBerries += gained
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
        if let data = try? JSONEncoder().encode(snapshot) { UserDefaults.standard.set(data, forKey: saveKey) }
    }
}
