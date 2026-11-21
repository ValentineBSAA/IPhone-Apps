import SwiftUI
import Foundation

#if BERRY_INTERNAL_QA
/// D0 experimental QA-only scenarios. There is intentionally NO bridge to
/// BerryGameSession, UserDefaults, inventory, purchases, or file storage.
/// Only ephemeral BerryEngine values are mutated. Release builds omit this.
enum BerryQASandboxScenario: String, CaseIterable, Identifiable {
    case oneMoveLineClear = "One Move From Line Clear"
    case blockedPlacement = "Blocked Placement"

    var id: String { rawValue }
    var explanation: String {
        switch self {
        case .oneMoveLineClear:
            return "Seven cells in row 4 are full. One test berry fills the last cell and clears exactly one row."
        case .blockedPlacement:
            return "A berry already occupies row 3, column 3. Trying that cell again must fail without changing the puzzle."
        }
    }
    var expected: String {
        switch self {
        case .oneMoveLineClear:
            return "Exactly one row cleared, 11 points earned, no other row/column cleared."
        case .blockedPlacement:
            return "Placement rejected with identical before/after puzzle state."
        }
    }
}

struct BerryQASandboxResult: Equatable {
    let scenario: BerryQASandboxScenario
    let passed: Bool
    let expected: String
    let actual: String
    let scoreDelta: Int
    let clearedLines: Int
}

/// Disposable value-type engine harness. No references to production
/// singletons or preferences; the original saved play session is never loaded.
/// Running again always starts from a pristine deterministic fixture.
struct BerryDeveloperSandbox {
    private(set) var scenario: BerryQASandboxScenario = .oneMoveLineClear
    private(set) var engine: BerryEngine
    private(set) var latestResult: BerryQASandboxResult?

    init() {
        engine = Self.makeFixture(.oneMoveLineClear)
    }

    mutating func prepare(_ next: BerryQASandboxScenario) {
        scenario = next
        engine = Self.makeFixture(next)
        latestResult = nil
    }

    mutating func discard() {
        prepare(.oneMoveLineClear)
    }

    @discardableResult
    mutating func run() -> BerryQASandboxResult {
        // Always recreate the same fixed board and UUIDs; re-running a
        // scenario must not depend on any prior tap or random dealt tray.
        engine = Self.makeFixture(scenario)
        let before = engine
        let result: BerryQASandboxResult
        switch scenario {
        case .oneMoveLineClear:
            let move = engine.place(slot: 0, row: 3, col: 7)
            let delta = engine.score - before.score
            let passed = move?.clearedRows == [3]
                && move?.clearedColumns.isEmpty == true
                && move?.clearedLines == 1
                && move?.boardClear == false
                && move?.earned == 11
                && delta == 11
                && engine.totalLines - before.totalLines == 1
                && engine.board[7][7] == 2
            result = BerryQASandboxResult(
                scenario: scenario,
                passed: passed,
                expected: scenario.expected,
                actual: "Rows: \(move?.clearedRows.count ?? 0), columns: \(move?.clearedColumns.count ?? 0), points: \(delta), moves: \(engine.moves - before.moves).",
                scoreDelta: delta,
                clearedLines: move?.clearedLines ?? 0)
        case .blockedPlacement:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let beforeBytes = try? encoder.encode(engine)
            let attempted = engine.place(slot: 0, row: 2, col: 2)
            let afterBytes = try? encoder.encode(engine)
            let unchanged = beforeBytes != nil && beforeBytes == afterBytes
            result = BerryQASandboxResult(
                scenario: scenario,
                passed: attempted == nil && unchanged,
                expected: scenario.expected,
                actual: "Placement \(attempted == nil ? "rejected" : "accepted"); full engine unchanged: \(unchanged ? "yes" : "no").",
                scoreDelta: engine.score - before.score,
                clearedLines: attempted?.clearedLines ?? 0)
        }
        latestResult = result
        return result
    }

    private static func makeFixture(_ scenario: BerryQASandboxScenario) -> BerryEngine {
        var board = Array(repeating: Array<Int?>(repeating: nil, count: 8), count: 8)
        switch scenario {
        case .oneMoveLineClear:
            for col in 0..<7 { board[3][col] = 1 }
            // Keep one other cell occupied so this is NOT a board-clear bonus.
            board[7][7] = 2
        case .blockedPlacement:
            board[2][2] = 2
        }
        // Fixed UUIDs and fixed spare tray slots prevent random refills.
        let pieces: [BerryPiece?] = [
            BerryPiece(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D0")!,
                       points: [BerryPoint(row: 0, col: 0)], tint: 3),
            BerryPiece(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!,
                       points: [BerryPoint(row: 0, col: 0)], tint: 4),
            BerryPiece(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D2")!,
                       points: [BerryPoint(row: 0, col: 0)], tint: 5)
        ]
        return BerryEngine(board: board, tray: pieces, score: 0)
    }
}

/// A compact two-column sandbox page. Its @State is owned solely by this
/// sheet; dismissing it discards the fixture. It never creates a live session.
struct BerryDeveloperSandboxPanel: View {
    @State private var sandbox = BerryDeveloperSandbox()
    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 12) {
            Text("DISPOSABLE QA SANDBOX • NO SAVE WRITES")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.leaf)
                .multilineTextAlignment(.center)
            Text("Choose a fixture, inspect the board, then run the actual puzzle engine. Your saved games, strawberries, purchases and rewards stay untouched.")
                .font(.caption)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BerryQASandboxScenario.allCases) { item in
                    Button {
                        sandbox.prepare(item)
                    } label: {
                        VStack(spacing: 5) {
                            Text(item.rawValue)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                            Text(sandbox.scenario == item ? "SELECTED" : "SET UP")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(sandbox.scenario == item ? BerryStyle.leaf : BerryStyle.strawberry)
                        }
                        .frame(maxWidth: .infinity, minHeight: 76)
                        .background(sandbox.scenario == item ? BerryStyle.softPink : Color.white,
                                    in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15)
                                    .strokeBorder(BerryStyle.strawberry.opacity(0.45), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(sandbox.scenario.explanation)
                .font(.caption)
                .multilineTextAlignment(.center)
            VStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<8, id: \.self) { col in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(sandbox.engine.board[row][col] == nil
                                      ? Color.white : BerryStyle.strawberry)
                                .frame(width: 20, height: 20)
                                .overlay(RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(BerryStyle.strawberry.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(8)
            .background(BerryStyle.softPink.opacity(0.75), in: RoundedRectangle(cornerRadius: 13))
            .accessibilityLabel("Eight by eight test board. \(sandbox.scenario.explanation)")

            Text("Expected: \(sandbox.scenario.expected)")
                .font(.caption)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: 10) {
                Button("Run engine test") {
                    _ = sandbox.run()
                }
                .buttonStyle(.borderedProminent)
                .tint(BerryStyle.leaf)
                Button("Discard & reset") {
                    sandbox.discard()
                }
                .buttonStyle(.bordered)
                .tint(BerryStyle.strawberry)
            }
            if let result = sandbox.latestResult {
                VStack(spacing: 5) {
                    Text(result.passed ? "PASS • ENGINE VERIFIED" : "FAIL • CHECK ENGINE")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(result.passed ? BerryStyle.leaf : Color.red)
                    Text(result.actual)
                        .font(.caption.monospacedDigit())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
            Text("D0 preview only. Additional game modes, tool charges and currency scenarios are planned, not yet runnable.")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .onDisappear { sandbox.discard() }
    }
}
#endif
