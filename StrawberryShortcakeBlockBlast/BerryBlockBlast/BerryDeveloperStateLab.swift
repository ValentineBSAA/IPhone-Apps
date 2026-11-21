import Foundation

#if BERRY_INTERNAL_QA
/// D0b: a pure value-type policy laboratory. No BerryGameSession, no
/// UserDefaults, no global wallet, no Keychain, no database, and no disk IO.
/// This verifies boundary policies against actual game price/timer constants;
/// it does NOT replace integration tests for production purchase handlers.
enum BerryQAStateScenario: String, CaseIterable, Identifiable {
    case exactPriceUndo = "Exact-Price Undo"
    case oneBerryShort = "One Berry Short"
    case zeroToolCharge = "Zero Tool Charges"
    case memorySave = "In-Memory Save"
    case corruptedSave = "Corrupted Save"
    case virtualTimer = "Three-Second Timer"

    var id: String { rawValue }
    var details: String {
        switch self {
        case .exactPriceUndo: return "Start with exactly 40 test strawberries, buy one Undo charge."
        case .oneBerryShort: return "Start with 49 test strawberries. Reject a 50-strawberry Shuffle."
        case .zeroToolCharge: return "Try to use a test Hint with zero charges."
        case .memorySave: return "Save and restore a seeded puzzle, entirely in memory."
        case .corruptedSave: return "Reject malformed saved-engine bytes without affecting the good copy."
        case .virtualTimer: return "Pause with two seconds left, then resume after ten virtual seconds."
        }
    }
    var expected: String {
        switch self {
        case .exactPriceUndo: return "Undo purchase succeeds once: wallet 0, one charge."
        case .oneBerryShort: return "Shuffle purchase rejected: wallet remains 49, no charge."
        case .zeroToolCharge: return "Hint use rejected: zero charges and wallet unchanged."
        case .memorySave: return "Decoded engine matches original; no file or game save touched."
        case .corruptedSave: return "Corrupt payload rejected; independent good snapshot survives."
        case .virtualTimer: return "Paused at 2 sec, resumes at 2 sec, expires exactly at new deadline."
        }
    }
}

enum BerryQAIsolatedTool: String, Hashable {
    case undo, shuffle, hint
    var price: Int {
        switch self {
        case .undo: return BerryEconomy.undoPrice
        case .shuffle: return BerryEconomy.shufflePrice
        case .hint: return BerryEconomy.hintPrice
        }
    }
}

/// Minimal transaction guard used ONLY by this sandbox. It deliberately reads
/// the real immutable prices, but is not the app's real purchase workflow.
struct BerryQAIsolatedWallet {
    private(set) var balance: Int
    private(set) var charges: [BerryQAIsolatedTool: Int]

    init(balance: Int, charges: [BerryQAIsolatedTool: Int] = [:]) {
        precondition(balance >= 0 && charges.values.allSatisfy { $0 >= 0 })
        self.balance = balance
        self.charges = charges
    }

    func chargeCount(for tool: BerryQAIsolatedTool) -> Int { charges[tool, default: 0] }

    @discardableResult
    mutating func buy(_ tool: BerryQAIsolatedTool) -> Bool {
        let cost = tool.price
        guard cost > 0, balance >= cost,
              chargeCount(for: tool) < Int.max else { return false }
        balance -= cost
        charges[tool] = chargeCount(for: tool) + 1
        return true
    }

    @discardableResult
    mutating func use(_ tool: BerryQAIsolatedTool) -> Bool {
        let count = chargeCount(for: tool)
        guard count > 0 else { return false }
        charges[tool] = count - 1
        return true
    }
}

/// Never writes files or production saved-game keys; Codable is exercised
/// using the existing BerryEngine schema in an ephemeral dictionary.
struct BerryQAMemorySaveStore {
    private var slots: [String: Data] = [:]

    mutating func save(_ engine: BerryEngine, key: String) throws {
        slots[key] = try JSONEncoder().encode(engine)
    }

    func restore(key: String) throws -> BerryEngine? {
        guard let data = slots[key] else { return nil }
        return try JSONDecoder().decode(BerryEngine.self, from: data)
    }

    mutating func setCorruptedBytes(_ bytes: Data, key: String) {
        slots[key] = bytes
    }

    func byteCount(key: String) -> Int { slots[key]?.count ?? 0 }
}

struct BerryQAVirtualClock {
    private(set) var now: Date
    mutating func advance(by seconds: TimeInterval) {
        precondition(seconds >= 0 && seconds.isFinite)
        now = now.addingTimeInterval(seconds)
    }
}

struct BerryQAStateLabReceipt: Equatable {
    let scenario: BerryQAStateScenario
    let passed: Bool
    let expected: String
    let actual: String
}

/// One-tap D0b scenario executor. Every run uses new value state and a fixed
/// virtual instant. It cannot leak a scenario into a real playing session.
struct BerryDeveloperStateLab {
    private(set) var scenario: BerryQAStateScenario = .exactPriceUndo
    private(set) var wallet = BerryQAIsolatedWallet(balance: 40)
    private(set) var saves = BerryQAMemorySaveStore()
    private(set) var clock = BerryQAVirtualClock(now: Date(timeIntervalSince1970: 1_800_000_000))
    private(set) var latest: BerryQAStateLabReceipt?

    init() { prepare(.exactPriceUndo) }

    /// Stable data comparisons across encodes; ordinary JSON dictionaries
    /// have no guaranteed key order.
    private static func canonicalBytes(_ engine: BerryEngine) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(engine)
    }

    mutating func prepare(_ next: BerryQAStateScenario) {
        scenario = next
        let balance: Int
        switch next {
        case .exactPriceUndo: balance = BerryEconomy.undoPrice
        case .oneBerryShort: balance = BerryEconomy.shufflePrice - 1
        default: balance = 0
        }
        wallet = BerryQAIsolatedWallet(balance: balance)
        saves = BerryQAMemorySaveStore()
        clock = BerryQAVirtualClock(now: Date(timeIntervalSince1970: 1_800_000_000))
        latest = nil
    }

    mutating func discard() { prepare(.exactPriceUndo) }

    @discardableResult
    mutating func run() -> BerryQAStateLabReceipt {
        prepare(scenario)
        let success: Bool
        let actual: String
        switch scenario {
        case .exactPriceUndo:
            let bought = wallet.buy(.undo)
            success = bought && wallet.balance == 0 &&
                wallet.chargeCount(for: .undo) == 1
            actual = "Accepted: \(bought); berries: \(wallet.balance); Undo charges: \(wallet.chargeCount(for: .undo))."

        case .oneBerryShort:
            let before = wallet.balance
            let bought = wallet.buy(.shuffle)
            success = !bought && wallet.balance == before &&
                wallet.chargeCount(for: .shuffle) == 0
            actual = "Accepted: \(bought); berries: \(wallet.balance); Shuffle charges: \(wallet.chargeCount(for: .shuffle))."

        case .zeroToolCharge:
            let used = wallet.use(.hint)
            success = !used && wallet.balance == 0 &&
                wallet.chargeCount(for: .hint) == 0
            actual = "Hint used: \(used); berries: \(wallet.balance); charges: \(wallet.chargeCount(for: .hint))."

        case .memorySave:
            let original = BerryEngine(side: 8, seed: 20261120)
            let encoded = Self.canonicalBytes(original)
            do {
                try saves.save(original, key: "fixture")
                let restored = try saves.restore(key: "fixture")
                let match = encoded != nil &&
                    restored.flatMap { Self.canonicalBytes($0) } == encoded
                success = match && saves.byteCount(key: "fixture") > 0
                actual = "In-memory bytes: \(saves.byteCount(key: "fixture")); restored identical: \(match)."
            } catch {
                success = false
                actual = "In-memory snapshot failed: \(error.localizedDescription)."
            }

        case .corruptedSave:
            let original = BerryEngine(side: 12, seed: 20261120)
            do {
                try saves.save(original, key: "good")
                saves.setCorruptedBytes(Data("{not valid engine".utf8), key: "bad")
                let originalBytes = Self.canonicalBytes(original)
                let good = try saves.restore(key: "good")
                let goodBytes = good.flatMap { Self.canonicalBytes($0) }
                let corruptionRejected: Bool
                do {
                    _ = try saves.restore(key: "bad")
                    corruptionRejected = false
                } catch {
                    corruptionRejected = true
                }
                success = corruptionRejected && originalBytes != nil &&
                    originalBytes == goodBytes
                actual = "Bad payload rejected: \(corruptionRejected); good snapshot intact: \(originalBytes == goodBytes)."
            } catch {
                success = false
                actual = "Isolated save fixture failed: \(error.localizedDescription)."
            }

        case .virtualTimer:
            let start = clock.now
            let originalDeadline = start.addingTimeInterval(3)
            clock.advance(by: 1)
            let pausedAt = clock.now
            let paused = BerryTimedLifecycle.pausedSeconds(
                deadline: originalDeadline, pausedAt: pausedAt, fallback: 0)
            clock.advance(by: 10)
            let restored = BerryTimedLifecycle.restoredDeadline(
                originalDeadline, pausedAt: pausedAt, resumedAt: clock.now)
            let resumesWithTwo = BerryCountdownMath.seconds(
                deadline: restored, now: clock.now, pausedAt: nil, fallback: 0) == 2
            clock.advance(by: 1)
            let oneSecondLeft = BerryTimedLifecycle.canPlay(
                now: clock.now, deadline: restored,
                running: true, foreground: true, pausedAt: nil)
            clock.advance(by: 1)
            let expired = !BerryTimedLifecycle.canPlay(
                now: clock.now, deadline: restored,
                running: true, foreground: true, pausedAt: nil)
            success = paused == 2 && resumesWithTwo && oneSecondLeft && expired &&
                restored == originalDeadline.addingTimeInterval(10)
            actual = "Paused: \(paused)s; resumed at 2s: \(resumesWithTwo); valid 1s before: \(oneSecondLeft); expired at 0: \(expired)."
        }
        let receipt = BerryQAStateLabReceipt(
            scenario: scenario, passed: success,
            expected: scenario.expected, actual: actual)
        latest = receipt
        return receipt
    }
}
#endif
