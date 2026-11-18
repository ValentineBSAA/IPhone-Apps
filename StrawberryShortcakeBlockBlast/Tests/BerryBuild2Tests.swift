import XCTest
@testable import BerryBlockBlast

@MainActor
final class BerryBuild2Tests: XCTestCase {
    func testAllOriginalAudioResourcesAreBundled() {
        XCTAssertEqual(BerryAudio.tracks.count, 51)
        XCTAssertEqual(BerryAudio.effects.count, 16)
        XCTAssertEqual(Set(BerryAudio.tracks.map(\.id)).count, 51)
        XCTAssertEqual(Set(BerryAudio.effects.map(\.eventKey)).count, 16)
        for track in BerryAudio.tracks {
            let name = URL(fileURLWithPath: track.file).deletingPathExtension().lastPathComponent
            XCTAssertNotNil(Bundle.main.url(forResource: name, withExtension: "m4a",
                                             subdirectory: "Music"), "Missing original \(track.file)")
        }
        for effect in BerryAudio.effects {
            let name = URL(fileURLWithPath: effect.file).deletingPathExtension().lastPathComponent
            XCTAssertNotNil(Bundle.main.url(forResource: name, withExtension: "wav",
                                             subdirectory: "Effects"), "Missing original \(effect.file)")
        }
    }

    func testSoundtrackCategoriesMatchSupplied51TrackManifest() {
        let tracks = BerryAudio.tracks
        XCTAssertEqual(BerryPlaylistPicker.indices(tracks, for: .menu).count, 11)
        XCTAssertEqual(BerryPlaylistPicker.indices(tracks, for: .gameplay).count, 22)
        XCTAssertEqual(BerryPlaylistPicker.indices(tracks, for: .blitz).count, 7)
        XCTAssertEqual(BerryPlaylistPicker.indices(tracks, for: .results).count, 11)
    }

    func testAllMixesAvoidImmediateRepeatedSongs() {
        let tracks = BerryAudio.tracks
        for playlist: BerryPlaylistKind in [.menu, .gameplay, .blitz, .results] {
            let indices = BerryPlaylistPicker.indices(tracks, for: playlist)
            XCTAssertGreaterThan(indices.count, 1)
            for last in indices {
                for mode in BerryMusicMode.allCases {
                    for _ in 0..<16 {
                        let next = BerryPlaylistPicker.choose(
                            tracks: tracks, lastIndex: last, history: [last],
                            mode: mode, shuffle: true, playlist: playlist
                        )
                        XCTAssertNotEqual(next, last)
                        if let next { XCTAssertTrue(indices.contains(next)) }
                    }
                }
            }
        }
    }

    func testEachEndlessBoardSizeHasItsOwnScoreKey() {
        let classicKey = BerryGameSession.endlessScoreKey(side: 8)
        let expertKey = BerryGameSession.endlessScoreKey(side: 12)
        let megaKey = BerryGameSession.endlessScoreKey(side: 24)
        XCTAssertNotEqual(classicKey, expertKey)
        XCTAssertNotEqual(expertKey, megaKey)
        XCTAssertNotEqual(classicKey, megaKey)
        XCTAssertEqual(classicKey, "berryblockblast.best-score.v1")
    }

    func testBlitzIs60And120SecondsWithIndependentRecords() {
        XCTAssertEqual(BerryBlitzVariant.quick60.seconds, 60)
        XCTAssertEqual(BerryBlitzVariant.rush120.seconds, 120)
        XCTAssertNotEqual(BerryBlitzVariant.quick60.bestScoreKey,
                          BerryBlitzVariant.rush120.bestScoreKey)
        XCTAssertEqual(BerryBlitzVariant.garden300.seconds, 300)
        XCTAssertEqual(BerryBlitzVariant.marathon600.seconds, 600)
        XCTAssertNotEqual(BerryBlitzVariant.garden300.bestScoreKey, BerryBlitzVariant.marathon600.bestScoreKey)
        XCTAssertEqual(BerryBlitzVariant.allCases.count, 4)
    }

    func testMegaGardenSupports24x24AndOriginalClassicRemains8x8() throws {
        let mega = BerryEngine(side: 24, hard: true)
        XCTAssertEqual(mega.board.count, 24)
        XCTAssertTrue(mega.board.allSatisfy { $0.count == 24 })
        XCTAssertTrue(mega.hasMove())
        // The modern Mega Garden deliberately offers smaller rescue pieces
        // as well as giant blocks. The invariant is a fully playable hand.
        XCTAssertEqual(mega.tray.compactMap { $0 }.count, 3)
        XCTAssertTrue(mega.tray.compactMap { $0 }.allSatisfy {
            !$0.points.isEmpty && mega.hasPlacement(for: $0)
        })
        let restored = try JSONDecoder().decode(BerryEngine.self, from: JSONEncoder().encode(mega))
        XCTAssertEqual(restored.side, 24)
        let classic = BerryEngine()
        XCTAssertEqual(classic.side, 8)
        XCTAssertEqual(classic.tray.count, 3)
    }

    func testTouchCoordinatesStillAcceptRegular8x8() {
        let board = CGRect(x: 20, y: 255, width: 348, height: 348)
        let piece = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 0)
        let target = BerryDropGeometry.target(
            for: CGPoint(x: 43, y: 279), board: board, piece: piece, side: 8
        )
        XCTAssertEqual(target?.row, 0)
        XCTAssertEqual(target?.col, 0)
    }
    func testSweetEndlessHasSeparateSavedSlotsForEveryBoardSize() {
        let slots = [8, 12, 24].map { BerryGameSession.endlessSaveKey(side: $0) }
        XCTAssertEqual(Set(slots).count, 3)
        XCTAssertTrue(slots.allSatisfy { $0.contains("endless.saved") })
    }

    func testStuckEndlessBoardOpensNewSeasonWithoutResettingScore() throws {
        let size = 8
        let blocked = Array(repeating: Array<Int?>(repeating: 2, count: size), count: size)
        let single = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 0)
        var endless = BerryEngine(board: blocked, tray: [single, nil, nil], score: 1728)
        XCTAssertFalse(endless.hasMove())
        XCTAssertTrue(endless.beginNextEndlessSeasonIfStuck())
        XCTAssertEqual(endless.score, 1728)
        XCTAssertEqual(endless.seasons, 1)
        XCTAssertTrue(endless.hasMove())
        XCTAssertEqual(endless.tray.count, 3)
        XCTAssertTrue(endless.board.flatMap { $0 }.allSatisfy { $0 == nil })
        let restored = try JSONDecoder().decode(BerryEngine.self,
                                                from: JSONEncoder().encode(endless))
        XCTAssertEqual(restored.score, 1728)
        XCTAssertEqual(restored.seasons, 1)
    }

    func testStuckMegaGardenOpensSeasonAndContinues() {
        let size = 24
        let blocked = Array(repeating: Array<Int?>(repeating: 3, count: size), count: size)
        let single = BerryPiece(points: [BerryPoint(row: 0, col: 0)], tint: 1)
        var endless = BerryEngine(board: blocked, tray: [single, nil, nil], score: 8000, hard: true)
        XCTAssertFalse(endless.hasMove())
        XCTAssertTrue(endless.beginNextEndlessSeasonIfStuck())
        XCTAssertEqual(endless.score, 8000)
        XCTAssertEqual(endless.side, 24)
        XCTAssertTrue(endless.hasMove())
        XCTAssertEqual(endless.tray.compactMap { $0 }.count, 3)
        XCTAssertTrue(endless.tray.compactMap { $0 }.allSatisfy {
            !$0.points.isEmpty && endless.hasPlacement(for: $0)
        })
    }

    func testLegacySaveDecodesWithoutEndlessSeasonsField() throws {
        let original = BerryEngine(side: 12, hard: true)
        let data = try JSONEncoder().encode(original)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "seasons")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(BerryEngine.self, from: legacy)
        XCTAssertEqual(restored.seasons, 0)
        XCTAssertEqual(restored.side, 12)
    }

    func testEndlessSaveAndResumeEverySize() throws {
        let defaults = UserDefaults.standard
        let sideKey = "berryblockblast.endless.boardSize.v056b2"
        let migratedKey = "berryblockblast.endless.legacyMigrated.v056b2"
        let keys = [sideKey, migratedKey] + [8, 12, 24].map {
            BerryGameSession.endlessSaveKey(side: $0)
        }
        let backups = keys.map { ($0, defaults.object(forKey: $0)) }
        defer {
            for (key, value) in backups {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }

        defaults.set(true, forKey: migratedKey)
        for side in [8, 12, 24] {
            defaults.set(side, forKey: sideKey)
            defaults.removeObject(forKey: BerryGameSession.endlessSaveKey(side: side))
            let playing = BerryGameSession()
            playing.selectMode(.endless)
            XCTAssertEqual(playing.engine.side, side)
            XCTAssertFalse(BerryGameSession.hasResumableEndless(side: side))
            var placement: (Int, Int, Int)?
            for slot in 0..<3 {
                guard let piece = playing.engine.tray[slot] else { continue }
                for row in 0..<side {
                    for col in 0..<side where playing.engine.canPlace(piece, row: row, col: col) {
                        if placement == nil { placement = (slot, row, col) }
                    }
                }
            }
            let legal = try XCTUnwrap(placement)
            XCTAssertTrue(playing.drop(slot: legal.0, row: legal.1, col: legal.2))
            XCTAssertTrue(BerryGameSession.hasResumableEndless(side: side))

            let resumed = BerryGameSession()
            resumed.selectMode(.endless)
            XCTAssertEqual(resumed.engine.side, side)
            XCTAssertEqual(resumed.engine.board, playing.engine.board)
            XCTAssertEqual(resumed.engine.tray, playing.engine.tray)
            XCTAssertEqual(resumed.engine.score, playing.engine.score)

            // New Garden intentionally starts this size fresh, without
            // resurrecting the legacy 8x8 board on the next visit.
            resumed.newGame()
            XCTAssertFalse(BerryGameSession.hasResumableEndless(side: side))
            let restarted = BerryGameSession()
            restarted.selectMode(.endless)
            XCTAssertEqual(restarted.engine.score, 0)
            XCTAssertEqual(restarted.engine.moves, 0)
        }
    }

    func testClassicModeDoesNotResumeItsPreviousBoardInBuild2() throws {
        let first = BerryGameSession()
        first.selectMode(.classic)
        let piece = try XCTUnwrap(first.engine.tray[0])
        let row = try XCTUnwrap((0..<8).first { r in
            (0..<8).contains { c in first.engine.canPlace(piece, row: r, col: c) }
        })
        let col = try XCTUnwrap((0..<8).first { c in first.engine.canPlace(piece, row: row, col: c) })
        XCTAssertTrue(first.drop(slot: 0, row: row, col: col))
        XCTAssertGreaterThan(first.engine.score, 0)
        let again = BerryGameSession()
        again.selectMode(.classic)
        XCTAssertEqual(again.engine.score, 0)
        XCTAssertEqual(again.engine.moves, 0)
    }

}
