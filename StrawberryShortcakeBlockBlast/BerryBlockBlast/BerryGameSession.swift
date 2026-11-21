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
    // New premium supplies have their own keys, independent of old inventory.
    @Published private(set) var premiumCharges = UserDefaults.standard.dictionary(forKey: "berryberryblast.premium.charges.v059") as? [String: Int] ?? [:]
    @Published private(set) var premiumOwned = UserDefaults.standard.stringArray(forKey: "berryberryblast.premium.permanent.v059") ?? []
    private var previous: BerryEngine?
    private var previousBerryEarnings = 0
    private var previousRewardEntry: String?
    private var activeMode: BerryMode = .endless
    /// Normal gameplay uses standard defaults and the shared ledger.
    /// An isolated QA instance can inject an independent preferences suite
    /// and ledger. Only standard-tool buy paths are currently certified for
    /// this injection; unrelated singleton-backed game modes are not.
    private let checkoutDefaults: UserDefaults
    private let checkoutLedger: BerryEconomyLedger
    nonisolated static let goldenStrawberryCost = 250
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

    static func savedEndlessEngine(side: Int,
                                  defaults: UserDefaults = .standard) -> BerryEngine? {
        guard [8, 12, 24].contains(side) else { return nil }
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
        // D2a: selected game mode reads its own injected store for Endless
        // board/size/migration. Normal sessions still use standard defaults.
        activeMode = mode
        let scoreKey = bestScoreKey(for: mode)
        // Preserve legacy scores for old modes only. The new 12×12 and 24×24
        // scoreboards must start independently, not inherit an 8×8 record.
        let hasNewBoardSize = mode == .endless &&
            [12, 24].contains(checkoutDefaults.integer(forKey: "berryblockblast.endless.boardSize.v056b2"))
        if mode != .superHard && mode != .classic && mode != .challenge &&
           !hasNewBoardSize && checkoutDefaults.object(forKey: scoreKey) == nil {
            // Earlier versions shared one best-score key for five modes.
            // Seed independent records from it so an upgrade never loses that number.
            checkoutDefaults.set(checkoutDefaults.integer(forKey: bestKey), forKey: scoreKey)
        }
        bestScore = checkoutDefaults.integer(forKey: scoreKey)
        // Sweet Endless is the only mode that resumes its board. Keep legacy
        // Classic/non-Endless saves on disk for safe rollback, but never resume
        // them in this build. A selected garden size resumes only its own slot.
        let requestedSize = checkoutDefaults.integer(forKey: "berryblockblast.endless.boardSize.v056b2")
        let size = [8, 12, 24].contains(requestedSize) ? requestedSize : 8
        if mode == .daily {
            // A daily attempt is consumed when the player enters play, not
            // only when they win. Save the exact engine for same-day resume.
            guard BerryDailyHistory.beginToday() else {
                engine = freshEngine()
                previous = nil
                gameOver = true
                lastMessage = "Today's Daily Harvest is finished. A new attempt unlocks at midnight."
                return
            }
            engine = BerryDailyHistory.activeEngine() ?? freshEngine()
            BerryDailyHistory.saveActiveEngine(engine)
        } else if mode == .endless, let saved = Self.savedEndlessEngine(side: size, defaults: checkoutDefaults) {
            engine = saved
            if size == 8 {
                checkoutDefaults.set(true, forKey: Self.legacyEndlessMigratedKey)
                if let data = try? JSONEncoder().encode(saved) {
                    checkoutDefaults.set(data, forKey: Self.endlessSaveKey(side: 8))
                }
            }
        } else {
            engine = freshEngine()
        }
        // Only these three modes opt into bounded adaptive hand selection.
        // Existing saved trays never regenerate upon mode entry.
        switch mode {
        case .endless: engine.configureDifficulty(.endlessAdaptive, stage: engine.seasons)
        case .cozy: engine.configureDifficulty(.cozyGentle)
        case .story:
            engine.configureDifficulty(.storyProgressive,
                stage: checkoutDefaults.integer(forKey: "berryblockblast.story.level"))
        default: engine.configureDifficulty(nil)
        }
        lastMessage = nil
        if mode == .endless && !engine.hasMove() {
            // Legacy 24x24 saves remain intact and automatically resume on
            // whichever full-size 12x12 patch can accept a piece.
            let previousSeason = engine.seasons
            let previousSection = engine.activeGardenSection
            _ = engine.beginNextEndlessSeasonIfStuck()
            endlessRecoveryMessage(previousSection: previousSection, previousSeason: previousSeason)
            save()
        }
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        gameOver = !engine.hasMove()
        if mode == .daily && gameOver { BerryDailyHistory.markLostToday() }
        lastEarned = 0
        lastClearedLines = 0
    }

    private func freshEngine() -> BerryEngine {
        if activeMode == .cozy { return BerryEngine(cozy: true) }
        if activeMode == .superHard { return BerryEngine(side: 12, hard: true) }
        if activeMode == .endless {
            let requested = checkoutDefaults.integer(forKey: "berryblockblast.endless.boardSize.v056b2")
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
            let side = checkoutDefaults.integer(forKey: "berryblockblast.endless.boardSize.v056b2")
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
    #if BERRY_INTERNAL_QA
    // Internal QA only. Use the existing saved Inventory data, never the board
    // save slot, and never the natural-earnings or economy reporting counters.
    static let qaGrantAuditKey = "berryberryblast.internalQA.grants.v046"
    static let qaWalletChanged = Notification.Name("berryberryblast.qaWalletDidChange.v046")

    static func qaWalletBalance(defaults: UserDefaults = .standard) -> Int {
        guard let bytes = defaults.data(forKey: "berryblockblast.inventory.v3"),
              let inventory = try? JSONDecoder().decode(Inventory.self, from: bytes)
        else { return 0 }
        return max(0, inventory.berries)
    }

    static func qaGrantHistory(defaults: UserDefaults = .standard) -> [String] {
        defaults.stringArray(forKey: qaGrantAuditKey) ?? []
    }

    @discardableResult
    static func grantQAStrawberries(_ amount: Int,
                                   defaults: UserDefaults = .standard) -> Int? {
        guard amount > 0 else { return nil }
        let key = "berryblockblast.inventory.v3"
        let existing = defaults.data(forKey: key).flatMap {
            try? JSONDecoder().decode(Inventory.self, from: $0)
        }
        guard var inventory = existing else { return nil }
        guard inventory.berries >= 0,
              amount <= Int.max - inventory.berries else { return nil }
        let before = inventory.berries
        inventory.berries += amount
        guard let updated = try? JSONEncoder().encode(inventory) else { return nil }
        defaults.set(updated, forKey: key)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let record = "\(timestamp) | QA +\(amount) | \(before) → \(inventory.berries)"
        var history = defaults.stringArray(forKey: qaGrantAuditKey) ?? []
        history.insert(record, at: 0)
        defaults.set(Array(history.prefix(30)), forKey: qaGrantAuditKey)
        NotificationCenter.default.post(name: qaWalletChanged, object: nil)
        return inventory.berries
    }
    #endif

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

    init(checkoutDefaults: UserDefaults = .standard,
         checkoutLedger: BerryEconomyLedger? = nil) {
        self.checkoutDefaults = checkoutDefaults
        let selectedLedger = checkoutLedger ?? .shared
        self.checkoutLedger = selectedLedger
        // Complete an interrupted standard-tool purchase BEFORE decoding
        // inventory. This replays absolute values and never charges twice.
        _ = BerryStandardPurchaseJournal.recover(
            in: checkoutDefaults, ledger: selectedLedger)
        bestScore = checkoutDefaults.integer(forKey: bestKey)
        if let data = checkoutDefaults.data(forKey: saveKey),
           let restored = try? JSONDecoder().decode(Save.self, from: data),
           restored.engine.board.count == 8, restored.engine.board.allSatisfy({ $0.count == 8 }),
           restored.engine.tray.count == 3 {
            engine = restored.engine
            berries = restored.berries
            undos = restored.undos
            shuffles = restored.shuffles
            totalEarnedBerries = restored.totalEarnedBerries
        } else if let data = checkoutDefaults.data(forKey: "berryblockblast.saved-game.v1"),
                  let restored = try? JSONDecoder().decode(BerryEngine.self, from: data),
                  restored.board.count == 8, restored.board.allSatisfy({ $0.count == 8 }), restored.tray.count == 3 {
            engine = restored
        } else { engine = BerryEngine() }
        gameOver = !engine.hasMove()
        if let inventory = checkoutDefaults.data(forKey: inventoryKey), let saved = try? JSONDecoder().decode(Inventory.self, from: inventory) {
            berries = saved.berries; undos = saved.undos; shuffles = saved.shuffles; totalEarnedBerries = saved.totalEarnedBerries; hints = saved.hints
        }
        // D1a: Boutique purchases and reward receipts load from the same
        // injected store as inventory. Production defaults remain unchanged.
        ownedCosmetics = checkoutDefaults.stringArray(forKey: "berryblockblast.shop.owned.v056b2") ?? []
        rewardsLog = checkoutDefaults.stringArray(forKey: "berryblockblast.rewards.v1") ?? []
        // D1b: load Cottage and premium ownership from the same selected store.
        // Live sessions still use standard preferences; QA stays disposable.
        cottageDecorations = checkoutDefaults.integer(forKey: "berryblockblast.cottage.decorations")
        premiumCharges = checkoutDefaults.dictionary(forKey: "berryberryblast.premium.charges.v059") as? [String: Int] ?? [:]
        premiumOwned = checkoutDefaults.stringArray(forKey: "berryberryblast.premium.permanent.v059") ?? []
    }

    @discardableResult
    func drop(slot: Int, row: Int, col: Int) -> Bool {
        guard !gameOver else { return false }
        let before = engine
        let oldSection = engine.activeGardenSection
        let oldSeason = engine.seasons
        guard let outcome = engine.place(slot: slot, row: row, col: col) else { return false }
        previous = before
        previousBerryEarnings = 0
        previousRewardEntry = nil
        if engine.score > bestScore {
            bestScore = engine.score
            checkoutDefaults.set(bestScore, forKey: bestScoreKey(for: activeMode))
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
        if activeMode == .endless {
            // Auto-completed patches may advance while the remaining hand is
            // still playable. Announce those transitions as well as rescues.
            var progressed = engine.activeGardenSection != oldSection ||
                engine.seasons != oldSeason
            if !engine.hasMove() {
                progressed = engine.beginNextEndlessSeasonIfStuck() || progressed
            }
            if progressed {
                previous = nil
                previousBerryEarnings = 0
                previousRewardEntry = nil
                endlessRecoveryMessage(previousSection: oldSection, previousSeason: oldSeason)
            }
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
        // Isolated QA sessions must not write real daily quest counters.
        // The normal live session retains original progression callbacks.
        if checkoutDefaults === UserDefaults.standard {
            BerryProgression.shared.recordPlacement(mode: activeMode,
                                                     clearedLines: outcome.clearedLines)
        }
        save()
        return true
    }

    /// Apply the same no-cost recovery after every inventory action, not
    /// only after a normal drag-drop. Endless must never display Game Over.
    private func ensureEndlessPlayable() {
        guard activeMode == .endless, !engine.hasMove() else { return }
        let oldSection = engine.activeGardenSection
        let oldSeason = engine.seasons
        if engine.beginNextEndlessSeasonIfStuck() {
            previous = nil
            previousBerryEarnings = 0
            previousRewardEntry = nil
            endlessRecoveryMessage(previousSection: oldSection, previousSeason: oldSeason)
        }
    }

    private func endlessRecoveryMessage(previousSection: Int, previousSeason: Int) {
        if engine.seasons > previousSeason {
            lastMessage = "🍓 New garden season! Your score and berries continue!"
        } else if engine.side == 24 && engine.activeGardenSection != previousSection {
            let names = ["Rose Garden", "Berry Patch", "Flower Meadow", "Cottage Orchard"]
            lastMessage = "🌷 Next patch: \(names[engine.activeGardenSection])!"
        } else {
            lastMessage = "🍓 Fresh playable pieces, on the house!"
        }
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
        premiumCharges = UserDefaults.standard.dictionary(forKey: "berryberryblast.premium.charges.v059") as? [String: Int] ?? [:]
        premiumOwned = UserDefaults.standard.stringArray(forKey: "berryberryblast.premium.permanent.v059") ?? []
    }

    @discardableResult
    func undo() -> Int {
        guard undos > 0, let previous else { return 0 }
        let revertedLines = max(0, engine.totalLines - previous.totalLines)
        engine = previous
        berries = max(0, berries - previousBerryEarnings)
        totalEarnedBerries = max(0, totalEarnedBerries - previousBerryEarnings)
        BerryEconomyLedger.shared.reverseUndoneLineEarnings(
            previousBerryEarnings, mode: activeMode)
        if let entry = previousRewardEntry, let index = rewardsLog.firstIndex(of: entry) {
            rewardsLog.remove(at: index)
            UserDefaults.standard.set(rewardsLog, forKey: "berryblockblast.rewards.v1")
        }
        previousRewardEntry = nil
        previousBerryEarnings = 0
        self.previous = nil
        undos -= 1
        ensureEndlessPlayable()
        gameOver = !engine.hasMove()
        lastMessage = "A little second chance! 💗"
        lastEarned = 0
        lastClearedLines = 0
        save()
        return revertedLines
    }

    /// Shuffle is a valid Game Over Continue only when the current board has
    /// at least one empty square. Never rescue Classic or timed score trials.
    var canContinueWithShuffle: Bool {
        activeMode != .classic && activeMode != .challenge &&
            activeMode != .superHard &&
            !(activeMode == .daily && gameOver) &&
            engine.canRescueWithShuffle
    }

    @discardableResult
    func shuffle() -> Bool {
        guard shuffles > 0, canContinueWithShuffle,
              engine.reshuffleTray() else { return false }
        // An owned Shuffle is consumed only AFTER a legal hand was produced.
        shuffles -= 1
        ensureEndlessPlayable()
        gameOver = !engine.hasMove()
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        lastMessage = "🍓 Continue with Shuffle! Three fresh playable pieces."
        lastEarned = 0
        lastClearedLines = 0
        save()
        return true
    }

    /// Purchase and apply a Shuffle directly from Game Over when the player
    /// doesn't already own one. Both the berry debit and the board change
    /// happen only after the replacement tray is confirmed legal.
    @discardableResult
    func buyAndContinueWithShuffle() -> Bool {
        guard shuffles == 0, canContinueWithShuffle,
              berries >= BerryEconomy.shufflePrice,
              engine.reshuffleTray() else { return false }
        berries -= BerryEconomy.shufflePrice
        BerryEconomyLedger.shared.recordSpend(BerryEconomy.shufflePrice,
                                              item: "Shuffle Continue")
        ensureEndlessPlayable()
        gameOver = !engine.hasMove()
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        lastEarned = 0
        lastClearedLines = 0
        lastMessage = "🍓 Shuffle Continue! Your garden and score are safe."
        rewardsLog.insert("🍓 -\(BerryEconomy.shufflePrice) • Shuffle Continue", at: 0)
        rewardsLog = Array(rewardsLog.prefix(20))
        UserDefaults.standard.set(rewardsLog, forKey: "berryblockblast.rewards.v1")
        save()
        return true
    }

    func earn(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        berries = amount > Int.max - berries ? Int.max : berries + amount
        totalEarnedBerries = amount > Int.max - totalEarnedBerries ? Int.max : totalEarnedBerries + amount
        if reason == "Completed berry lines" {
            BerryEconomyLedger.shared.recordLineEarnings(amount, mode: activeMode)
        }
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
        // Migrated completions were already paid by prior app versions.
        // Never pay a second reward for a completed legacy date.
        guard !BerryDailyHistory.completed.contains(day) else { return }
        let dayNumber = BerryDailyHistory.nextStreakDay
        let amount = BerryDailyHistory.reward(forStreakDay: dayNumber)
        awardOnce("daily-" + day, amount: amount,
                  reason: "Daily Harvest · Day \(dayNumber) streak")
        if dayNumber == 7 {
            BerryProgression.shared.celebrate("🏆 Seven-day berry streak! +50 strawberries!")
        }
    }
    func rewardStory(_ chapter: Int) {
        awardOnce("chapter-" + String(chapter), amount: 15 + min(35, chapter * 5), reason: "Story chapter")
        BerryProgression.shared.recordStoryChapter(chapter)
    }
    var nextCottageDecorationPrice: Int? {
        BerryEconomy.nextCottagePrice(owned: cottageDecorations)
    }

    func buyCottageDecoration() {
        // Old purchases remain owned; rising prices apply ONLY to the next
        // undecorated slot, without altering anybody's existing berry wallet.
        guard let price = nextCottageDecorationPrice, berries >= price else { return }
        // Purchases must invalidate the undo snapshot to prevent currency duplication.
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        berries -= price
        checkoutLedger.recordSpend(price, item: "Cottage Decoration")
        cottageDecorations += 1
        checkoutDefaults.set(cottageDecorations, forKey: "berryblockblast.cottage.decorations")
        // Buying decor changes inventory only, not the current puzzle board.
        saveInventoryOnly()
    }
    private func persistPremium(boardChanged: Bool = true) {
        checkoutDefaults.set(premiumCharges, forKey: "berryberryblast.premium.charges.v059")
        checkoutDefaults.set(premiumOwned, forKey: "berryberryblast.premium.permanent.v059")
        // Purchasing only changes inventory. Actual tool usage changes
        // the game board and retains its original board-saving behavior.
        if boardChanged {
            save()
        } else {
            saveInventoryOnly()
        }
    }

    /// Golden Trowel 150, Ribbon Twister 200 (three uses), Starberry Seed 230,
    /// Golden Strawberry 250, Picnic Pantry 600 and Berry Spyglass 900 (permanent).
    @discardableResult
    func buyPremium(_ id: String) -> Bool {
        let prices = ["trowel": 150, "twister": 200, "seed": 230,
                      "golden-strawberry": Self.goldenStrawberryCost,
                      "pantry": 600, "spyglass": 900]
        guard let price = prices[id], berries >= price else { return false }
        let permanent = id == "pantry" || id == "spyglass"
        if permanent && premiumOwned.contains(id) { return false }
        if !permanent {
            let increment = id == "twister" ? 3 : 1
            guard premiumCharges[id, default: 0] >= 0,
                  premiumCharges[id, default: 0] <= Int.max - increment else {
                return false
            }
        }
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        berries -= price
        checkoutLedger.recordSpend(price, item: id)
        if permanent {
            premiumOwned.append(id)
            // Avoid posting a real progression celebration from an isolated QA session.
            if checkoutDefaults === UserDefaults.standard {
                BerryProgression.shared.celebrate("✨ Lifetime upgrade unlocked: " + id.capitalized)
            }
        } else {
            premiumCharges[id, default: 0] += id == "twister" ? 3 : 1
        }
        persistPremium(boardChanged: false)
        return true
    }

    var canUsePremium: Bool {
        activeMode == .endless || activeMode == .story || activeMode == .cozy
    }

    var canContinueWithGoldenStrawberry: Bool {
        canUsePremium && engine.canRescueWithGoldenStrawberry
    }

    var pantryPiece: BerryPiece? { engine.pantryPiece }
    var spyglassPiece: BerryPiece? {
        guard premiumOwned.contains("spyglass"), canUsePremium else { return nil }
        return engine.spyglassNext
    }

    /// The emergency rescue may be triggered even from the Story Game Over
    /// screen. One purchased charge is spent only after actual cells clear.
    /// Saving through persistPremium keeps the currency and board atomic.
    @discardableResult
    func useGoldenStrawberry() -> Bool {
        guard canContinueWithGoldenStrawberry,
              premiumCharges["golden-strawberry", default: 0] > 0,
              engine.clearBoardWithGoldenStrawberry() else { return false }
        premiumCharges["golden-strawberry", default: 0] -= 1
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        gameOver = !engine.hasMove()
        lastClearedLines = 0
        lastEarned = 0
        lastMessage = "✨ Golden Strawberry! Your garden is clear!"
        persistPremium()
        return true
    }

    /// Emergency Game Over checkout. Buying and clearing is one operation,
    /// avoiding a paid but unusable item and keeping the run intact.
    @discardableResult
    func buyAndUseGoldenStrawberry() -> Bool {
        guard canContinueWithGoldenStrawberry,
              premiumCharges["golden-strawberry", default: 0] == 0,
              berries >= Self.goldenStrawberryCost,
              !engine.goldenRescueUsed,
              engine.clearBoardWithGoldenStrawberry() else { return false }
        berries -= Self.goldenStrawberryCost
        BerryEconomyLedger.shared.recordSpend(Self.goldenStrawberryCost,
                                              item: "Golden Strawberry Continue")
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        gameOver = !engine.hasMove()
        lastClearedLines = 0
        lastEarned = 0
        lastMessage = "✨ Golden Strawberry! You can keep playing!"
        rewardsLog.insert("🍓 -\(Self.goldenStrawberryCost) • Golden Strawberry Continue", at: 0)
        rewardsLog = Array(rewardsLog.prefix(20))
        UserDefaults.standard.set(rewardsLog, forKey: "berryblockblast.rewards.v1")
        persistPremium()
        return true
    }

    @discardableResult
    func useGoldenTrowel(row: Int, col: Int) -> Bool {
        guard canUsePremium, premiumCharges["trowel", default: 0] > 0,
              engine.removeOneOccupiedCell(row: row, col: col) else { return false }
        premiumCharges["trowel", default: 0] -= 1
        previous = nil
        ensureEndlessPlayable()
        gameOver = !engine.hasMove()
        lastMessage = "✨ A little garden space!"
        persistPremium()
        return true
    }

    @discardableResult
    func useStarberrySeed(row: Int, col: Int) -> Bool {
        guard canUsePremium, premiumCharges["seed", default: 0] > 0,
              let outcome = engine.plantOneSeed(row: row, col: col) else { return false }
        premiumCharges["seed", default: 0] -= 1
        previous = nil
        lastClearedLines = outcome.clearedLines
        if outcome.clearedLines > 0 {
            earn(outcome.clearedLines * 3, reason: "Starberry Seed line clearing")
            BerryProgression.shared.recordPlacement(mode: activeMode,
                                                     clearedLines: outcome.clearedLines)
        }
        if engine.score > bestScore {
            bestScore = engine.score
            checkoutDefaults.set(bestScore, forKey: bestScoreKey(for: activeMode))
        }
        ensureEndlessPlayable()
        gameOver = !engine.hasMove()
        lastMessage = "🌱 Starberry Seed planted!"
        persistPremium()
        return true
    }

    @discardableResult
    func useRibbonTwister(slot: Int) -> Bool {
        guard canUsePremium, premiumCharges["twister", default: 0] > 0,
              engine.rotateTrayPiece(slot: slot) else { return false }
        premiumCharges["twister", default: 0] -= 1
        previous = nil
        ensureEndlessPlayable()
        gameOver = !engine.hasMove()
        lastMessage = "🎀 Berry piece rotated!"
        persistPremium()
        return true
    }

    @discardableResult
    func usePicnicPantry(slot: Int) -> Bool {
        guard canUsePremium, premiumOwned.contains("pantry"),
              engine.swapPantry(slot: slot) else { return false }
        previous = nil
        ensureEndlessPlayable()
        gameOver = !engine.hasMove()
        lastMessage = "🧺 A piece saved for later!"
        save()
        return true
    }

    /// Shared standard-tool checkout, with one recovery intent written
    /// before either inventory or spending-ledger keys are modified.
    /// Only Undo/Shuffle/Hint are D0e-covered, not other shop purchases.
    private func buyStandardTool(_ tool: BerryStandardToolKind) {
        let charges: Int
        switch tool {
        case .undo: charges = undos
        case .shuffle: charges = shuffles
        case .hint: charges = hints
        }
        _ = BerryStandardToolCheckout.purchase(
            tool, berries: berries, charges: charges
        ) { receipt in
            // Assemble the exact post-purchase inventory BEFORE changing
            // any in-memory game state or legacy preference key.
            var afterUndos = undos
            var afterShuffles = shuffles
            var afterHints = hints
            switch tool {
            case .undo: afterUndos = receipt.chargesAfter
            case .shuffle: afterShuffles = receipt.chargesAfter
            case .hint: afterHints = receipt.chargesAfter
            }
            let postInventory = Inventory(
                berries: receipt.berriesAfter,
                undos: afterUndos,
                shuffles: afterShuffles,
                totalEarnedBerries: totalEarnedBerries,
                hints: afterHints
            )
            guard let bytes = try? JSONEncoder().encode(postInventory),
                  let intent = BerryStandardPurchaseJournal.prepare(
                    receipt: receipt, inventoryAfter: bytes,
                    ledger: checkoutLedger
                  ),
                  BerryStandardPurchaseJournal.stage(
                    intent, in: checkoutDefaults
                  ) else { return }

            // Commit+repair the real inventory and real ledger through
            // the SAME narrow recovery path tested by an interrupted
            // process launch. If persistence is interrupted, the staged
            // intent is applied on next session init.
            guard BerryStandardPurchaseJournal.recover(
                in: checkoutDefaults, ledger: checkoutLedger
            ) else { return }

            previous = nil
            previousBerryEarnings = 0
            previousRewardEntry = nil
            berries = receipt.berriesAfter
            undos = afterUndos
            shuffles = afterShuffles
            hints = afterHints
            // Buying a helper changes inventory, not the board. A separate
            // menu session must never clear a saved 8×8 Endless garden.
            saveInventoryOnly()
        }
    }

    func buyUndo() { buyStandardTool(.undo) }

    func buyShuffle() { buyStandardTool(.shuffle) }

    func buyHint() { buyStandardTool(.hint) }

    @discardableResult
    func useHintIfPossible() -> BerryEngine.BerryHint? {
        guard hints > 0, !gameOver, let hint = engine.suggestedMove() else { return nil }
        guard let remaining = BerryStandardToolTransaction.consumeCharge(
            hints, actionIsValid: true) else { return nil }
        hints = remaining
        save()
        return hint
    }

    var canUndo: Bool { undos > 0 && previous != nil }

    func newGame() {
        // A lost (or completed) Daily Harvest cannot be restarted. Leaving
        // the unfinished run and returning the same day resumes its save.
        guard activeMode != .daily else { return }
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
        guard BerryBoutiquePurchasePolicy.canPurchase(
            id: id, proposedCost: cost, berries: berries,
            owned: ownedCosmetics
        ) else { return false }
        previous = nil
        previousBerryEarnings = 0
        previousRewardEntry = nil
        berries -= cost
        checkoutLedger.recordSpend(cost, item: id)
        ownedCosmetics.append(id)
        checkoutDefaults.set(ownedCosmetics, forKey: "berryblockblast.shop.owned.v056b2")
        rewardsLog.insert("🧺 -\(cost) • Berry Boutique: \(id)", at: 0)
        rewardsLog = Array(rewardsLog.prefix(20))
        checkoutDefaults.set(rewardsLog, forKey: "berryblockblast.rewards.v1")
        // Cosmetics do not change the game board; do not clear an unrelated
        // saved Endless garden when shopping from the menu.
        saveInventoryOnly()
        return true
    }

    private func saveInventoryOnly() {
        let inventory = Inventory(berries: berries, undos: undos, shuffles: shuffles,
                                  totalEarnedBerries: totalEarnedBerries, hints: hints)
        if let data = try? JSONEncoder().encode(inventory) {
            checkoutDefaults.set(data, forKey: inventoryKey)
        }
    }

    private func save() {
        saveInventoryOnly()
        // Daily Harvest keeps its independent original save policy.
        // Only the three standard-tool buy methods are D0d-certified.
        if activeMode == .daily {
            BerryDailyHistory.saveActiveEngine(engine)
            return
        }
        // Only Sweet Endless persists an unfinished indefinite board.
        guard activeMode == .endless else { return }
        let key = Self.endlessSaveKey(side: engine.side)
        if engine.moves > 0, let data = try? JSONEncoder().encode(engine) {
            checkoutDefaults.set(data, forKey: key)
        } else if engine.moves == 0 {
            checkoutDefaults.removeObject(forKey: key)
        }
    }
}
