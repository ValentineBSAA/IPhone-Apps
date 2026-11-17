import XCTest
@testable import BerryBlockBlast

final class BerrySoundtrackTests: XCTestCase {
    private func sampleCatalog() -> [BerrySoundtrackTrack] {
        (1...15).map { id in
            BerrySoundtrackTrack(
                id: id,
                file: String(format: "BerryTrack%02d.m4a", id),
                title: "Track \(id)",
                mood: id >= 6 ? "calm" : "upbeat",
                role: id == 1 ? "menu" : id == 5 ? "results" : id == 3 ? "high-score" : "gameplay",
                sha256: "sample", bytes: 2500000, durationSeconds: 120
            )
        }
    }

    func testThreeModesHaveSpecifiedMoods() {
        XCTAssertEqual(BerryMusicMode.cozy.calmChance, 0.90)
        XCTAssertEqual(BerryMusicMode.balanced.calmChance, 0.70)
        XCTAssertEqual(BerryMusicMode.arcade.calmChance, 0.40)
    }

    func testGameShuffleNeverPlaysMenuOrResults() {
        let tracks = sampleCatalog()
        for _ in 0..<300 {
            let index = BerryPlaylistPicker.choose(
                tracks: tracks, lastIndex: nil, history: [],
                mode: .balanced, shuffle: true
            )
            XCTAssertNotNil(index)
            if let index { XCTAssertTrue(["gameplay", "high-score"].contains(tracks[index].role)) }
        }
        XCTAssertEqual(BerryPlaylistPicker.gameplayIndices(tracks).count, 13)
    }

    func testShufflePreventsImmediateSameTrack() {
        let tracks = sampleCatalog()
        for last in BerryPlaylistPicker.gameplayIndices(tracks) {
            for _ in 0..<100 {
                let next = BerryPlaylistPicker.choose(tracks: tracks, lastIndex: last,
                    history: [last], mode: .cozy, shuffle: true)
                XCTAssertNotEqual(next, last)
            }
        }
    }

    func testMoodSelectionUsesSuppliedCatalog() {
        let tracks = sampleCatalog()
        let calm = BerryPlaylistPicker.choose(tracks: tracks, lastIndex: nil,
            history: [], mode: .cozy, shuffle: true, draw: 0.10)
        let upbeat = BerryPlaylistPicker.choose(tracks: tracks, lastIndex: nil,
            history: [], mode: .cozy, shuffle: true, draw: 0.99)
        XCTAssertNotNil(calm)
        XCTAssertNotNil(upbeat)
        if let calm { XCTAssertEqual(tracks[calm].mood, "calm") }
        if let upbeat { XCTAssertEqual(tracks[upbeat].mood, "upbeat") }
    }

    func testSequentialNeverIncludesMenuOrVictory() {
        let tracks = sampleCatalog()
        var last: Int? = nil
        for _ in 0..<45 {
            let next = BerryPlaylistPicker.choose(tracks: tracks,
                lastIndex: last, history: [], mode: .balanced, shuffle: false)
            XCTAssertNotNil(next)
            if let next {
                XCTAssertNotEqual(tracks[next].role, "menu")
                XCTAssertNotEqual(tracks[next].role, "results")
                last = next
            }
        }
    }
}
