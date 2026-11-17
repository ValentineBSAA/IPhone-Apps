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
        XCTAssertEqual(BerryBlitzVariant.allCases.count, 2)
    }

    func testMegaGardenSupports24x24AndOriginalClassicRemains8x8() throws {
        let mega = BerryEngine(side: 24, hard: true)
        XCTAssertEqual(mega.board.count, 24)
        XCTAssertTrue(mega.board.allSatisfy { $0.count == 24 })
        XCTAssertTrue(mega.hasMove())
        XCTAssertTrue(mega.tray.compactMap { $0 }.allSatisfy { $0.points.count >= 7 })
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
}
