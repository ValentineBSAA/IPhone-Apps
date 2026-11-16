import SwiftUI

@MainActor
final class BerryGameSession: ObservableObject {
    @Published private(set) var engine: BerryEngine
    @Published private(set) var bestScore: Int
    @Published private(set) var gameOver = false
    @Published private(set) var lastMessage: String? = nil
    @Published private(set) var celebration = 0
    @Published private(set) var lastEarned = 0

    private let saveKey = "berryblockblast.saved-game.v1"
    private let bestKey = "berryblockblast.best-score.v1"

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestKey)
        if let saved = UserDefaults.standard.data(forKey: saveKey),
           let restored = try? JSONDecoder().decode(BerryEngine.self, from: saved),
           restored.board.count == BerryEngine.side,
           restored.board.allSatisfy({ $0.count == BerryEngine.side }),
           restored.tray.count == 3 {
            engine = restored
        } else {
            engine = BerryEngine()
        }
        gameOver = !engine.hasMove()
    }

    @discardableResult
    func drop(slot: Int, row: Int, col: Int) -> Bool {
        guard !gameOver, let outcome = engine.place(slot: slot, row: row, col: col) else { return false }
        if engine.score > bestScore {
            bestScore = engine.score
            UserDefaults.standard.set(bestScore, forKey: bestKey)
        }
        lastEarned = outcome.earned
        if outcome.clearedLines > 0 {
            celebration += 1
            lastMessage = outcome.boardClear ? "PERFECT BOARD! +300 ✨" :
                outcome.clearedLines >= 3 ? "BERRY AMAZING! ✨" :
                outcome.streak >= 2 ? "SWEET COMBO ×\(outcome.streak)! 🍓" : "DELICIOUS! 🍰"
        } else {
            lastMessage = nil
        }
        gameOver = !engine.hasMove()
        save()
        return true
    }

    func newGame() {
        engine = BerryEngine()
        gameOver = false
        lastMessage = nil
        lastEarned = 0
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(engine) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
}
