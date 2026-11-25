import XCTest
import AVFoundation
@testable import LastSeen

@MainActor
final class PhoneFeedbackTests: XCTestCase {
    func testOriginalCuesAreDecodableAndBounded() throws {
        for cue in PhoneCue.allCases {
            let wav = cue.waveData()
            XCTAssertEqual(String(data: wav.prefix(4), encoding: .ascii), "RIFF")
            let audio = try AVAudioPlayer(data: wav)
            XCTAssertEqual(audio.duration, cue.duration, accuracy: 0.002)
            XCTAssertLessThan(audio.duration, 1)
            XCTAssertTrue(cue.pulses.allSatisfy { (0...1).contains($0.intensity) && (0...1).contains($0.sharpness) })
        }
        XCTAssertNotEqual(PhoneCue.message.waveData(), PhoneCue.scare.waveData())
        XCTAssertNotEqual(PhoneCue.suspense.waveData(), PhoneCue.scare.waveData())
    }

    func testAllFifteenOriginalAssetsDecodeAndPlayOnce() throws {
        XCTAssertEqual(PhoneCue.allCases.count, 15)
        XCTAssertEqual(Set(PhoneCue.allCases.map(\.assetName)).count, 15)
        XCTAssertEqual(PhoneCue.allCases.filter(\.isHorror).count, 5)
        for cue in PhoneCue.allCases {
            let url = try XCTUnwrap(cue.audioURL(in: Bundle(for: PhoneWorldStore.self)), cue.assetName)
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(player.duration, 0.3)
            XCTAssertLessThan(player.duration, 16)
            XCTAssertEqual(player.numberOfLoops, 0)
        }
    }

    func testCorrectiveCueClassification() {
        XCTAssertTrue(PhoneCue.unlock.isAuthentication)
        XCTAssertTrue(PhoneCue.authenticationFailed.isAuthentication)
        XCTAssertTrue(PhoneCue.passcodeKeypress.isKeypress)
        XCTAssertTrue(PhoneCue.dialerKeypress.isKeypress)
        XCTAssertFalse(PhoneCue.timerCompleted.isHorror)
        XCTAssertFalse(PhoneCue.message.isAuthentication)
    }

    func testIncomingDetectionDoesNotDependOnUnreadState() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        let initial = PhoneMessageArrival.incomingIDs(in: store.state)
        XCTAssertNil(PhoneMessageArrival.newest(in: store.state, previous: initial))
        store.startPhoneTutorial(now: now)
        store.markRead(.maya)
        XCTAssertEqual(PhoneMessageArrival.newest(in: store.state, previous: initial)?.message.id, "phone-tutorial-contact")
        let afterFirst = PhoneMessageArrival.incomingIDs(in: store.state)
        XCTAssertNil(PhoneMessageArrival.newest(in: store.state, previous: afterFirst))
        XCTAssertTrue(store.reply(to: .maya, text: store.tutorialChoices[0], now: now.addingTimeInterval(1)))
        let newest = PhoneMessageArrival.newest(in: store.state, previous: afterFirst)
        XCTAssertEqual(newest?.message.id, "phone-tutorial-notes")
        XCTAssertEqual(newest?.message.fromPlayer, false)
        store.markRead(.maya)
        XCTAssertNil(PhoneMessageArrival.newest(in: store.state, previous: PhoneMessageArrival.incomingIDs(in: store.state)))
    }

    func testTutorialReplayPreservesOtherDataAndCanAlertAgain() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("world.json")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        try RestoredPhoneBackup.restore(to: url, now: now)
        let store = PhoneWorldStore(storageURL: url)
        store.startPhoneTutorial(now: now)
        let custom = store.addNote(title: "Player note", body: "Keep this", now: now)
        XCTAssertTrue(store.reply(to: .denise, text: store.choices(.denise)[0], now: now))
        XCTAssertTrue(store.reply(to: .maya, text: store.tutorialChoices[0], now: now))
        for id in ["note", "desk", "reservation", "journal"] { store.recordTutorialVisit(id, now: now) }
        XCTAssertTrue(store.tutorialFinished)
        let denise = store.messages(.denise)
        let originalMaya = store.messages(.maya).filter { !$0.id.hasPrefix("phone-tutorial-") }
        let events = store.state.events
        store.resetPhoneTutorial()
        XCTAssertFalse(store.tutorialStarted)
        XCTAssertFalse(store.tutorialFinished)
        XCTAssertEqual(store.messages(.denise), denise)
        XCTAssertEqual(store.messages(.maya), originalMaya)
        XCTAssertEqual(store.state.events, events)
        XCTAssertTrue(store.state.notes.contains { $0.id == custom })
        let baseline = PhoneMessageArrival.incomingIDs(in: store.state)
        let resumed = PhoneWorldStore(storageURL: url)
        XCTAssertFalse(resumed.tutorialStarted)
        resumed.startPhoneTutorial(now: now.addingTimeInterval(10))
        resumed.startPhoneTutorial(now: now.addingTimeInterval(10))
        XCTAssertEqual(resumed.state.notes.filter { $0.id == PhoneWorldStore.tutorialNoteID }.count, 1)
        XCTAssertEqual(resumed.messages(.maya).filter { $0.id == "phone-tutorial-contact" }.count, 1)
        XCTAssertEqual(PhoneMessageArrival.newest(in: resumed.state, previous: baseline)?.message.id, "phone-tutorial-contact")
    }
}
