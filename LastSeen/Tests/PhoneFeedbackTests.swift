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

    func testLiveCueAdmissionAndAuthenticationCancellationClassification() {
        for cue in PhoneCue.allCases {
            for enabled in [false, true] {
                for preference in [false, true] {
                    XCTAssertEqual(PhoneAudioPriority.allowsCue(cue, horrorEnabled: enabled,
                        horrorPreference: preference), !cue.isHorror || (enabled && preference))
                }
            }
            XCTAssertEqual(PhoneAudioPriority.cancelsForAuthentication(cue), cue.isAuthentication)
        }
        XCTAssertFalse(PhoneAudioPriority.cancelsForAuthentication(nil))
        var queue = PhoneAudioQueue()
        queue.append(.init(cue: .message, horrorEnabled: false))
        queue.append(.init(cue: .authenticationFailed, horrorEnabled: false))
        queue.append(.init(cue: .timerCompleted, horrorEnabled: false))
        queue.cancelAuthentication()
        XCTAssertEqual(queue.entries.map(\.cue), [.message, .timerCompleted])
    }

    func testAudioAdmissionPreservesAlertsAndAuthenticationPriority() {
        XCTAssertEqual(PhoneAudioPriority.decision(for: .passcodeKeypress, playing: .message, waiting: false), .drop)
        XCTAssertEqual(PhoneAudioPriority.decision(for: .outgoing, playing: nil, waiting: true), .drop)
        XCTAssertEqual(PhoneAudioPriority.decision(for: .message, playing: .passcodeKeypress, waiting: false), .start)
        XCTAssertEqual(PhoneAudioPriority.decision(for: .general, playing: nil, waiting: true), .enqueue)
        XCTAssertEqual(PhoneAudioPriority.decision(for: .unlock, playing: .message, waiting: false), .enqueue)
        XCTAssertEqual(PhoneAudioPriority.decision(for: .unlock, playing: .passcodeKeypress, waiting: true), .start)
        XCTAssertEqual(PhoneAudioPriority.decision(for: .unlock, playing: nil, waiting: true), .start)
    }

    func testOptionalAtmosphereRequiresAnIdleUnreservedAudioChannel() {
        for playing in [false, true] {
            for waiting in [false, true] {
                for media in [false, true] {
                    XCTAssertEqual(PhoneAudioPriority.allowsAtmosphere(playing: playing,
                        waiting: waiting, mediaReserved: media), !playing && !waiting && !media)
                }
            }
        }
        // The normal admission policy still prioritizes authentication and
        // preserves meaningful alerts; the optional path never enters this queue.
        XCTAssertEqual(PhoneAudioPriority.decision(for: .unlock, playing: nil, waiting: true), .start)
        XCTAssertEqual(PhoneAudioPriority.decision(for: .message, playing: nil, waiting: false), .start)
    }

    func testAudioQueueBoundsOrderingAndCancellation() {
        var queue = PhoneAudioQueue()
        for cue in [PhoneCue.message, .general, .timerCompleted] {
            queue.append(.init(cue: cue, horrorEnabled: false))
        }
        queue.append(.init(cue: .authenticationFailed, horrorEnabled: false))
        queue.append(.init(cue: .unlock, horrorEnabled: false))
        XCTAssertEqual(queue.next()?.cue, .unlock)
        XCTAssertEqual(queue.next()?.cue, .message)
        XCTAssertEqual(queue.next()?.cue, .general)
        queue.append(.init(cue: .authenticationFailed, horrorEnabled: false))
        queue.cancelAuthentication()
        XCTAssertEqual(queue.next()?.cue, .timerCompleted)
        XCTAssertNil(queue.next())
        for _ in 0..<20 { queue.append(.init(cue: .message, horrorEnabled: false)) }
        XCTAssertEqual(queue.entries.count, 12)
        queue.append(.init(cue: .unlock, horrorEnabled: false))
        XCTAssertEqual(queue.entries.count, 12)
        XCTAssertEqual(queue.next()?.cue, .unlock)
    }

    func testPreviewLeaseRejectsStaleCancellationAndCoversAllRecordings() {
        var lease = PhonePreviewLease()
        let first = UUID(), second = UUID()
        lease.begin(first)
        lease.begin(second)
        XCTAssertFalse(lease.end(first))
        XCTAssertEqual(lease.owner, second)
        XCTAssertTrue(lease.end(second))
        XCTAssertFalse(lease.end(second))
        lease.begin(first)
        XCTAssertTrue(lease.end())
        XCTAssertNil(lease.owner)
        let items = PhoneCue.allCases.map(PhoneSoundPreview.phone) +
            RestartAudio.assetNames.map(PhoneSoundPreview.restart)
        XCTAssertEqual(Set(items).count, 19)
        XCTAssertEqual(items.filter(\.isRestart).count, 4)
        XCTAssertEqual(items.filter(\.isHorror).count, 5)
        XCTAssertTrue(items.filter(\.isRestart).allSatisfy { $0.profile == nil })
    }

    func testHorrorCancellationPreservesOrdinaryQueueAndAuthentication() {
        var queue = PhoneAudioQueue()
        for cue in [PhoneCue.suspense, .message, .phantom, .timerCompleted, .unlock] {
            queue.append(.init(cue: cue, horrorEnabled: true))
        }
        queue.cancelHorror()
        XCTAssertEqual(queue.entries.map(\.cue), [.unlock, .message, .timerCompleted])
        XCTAssertTrue(PhoneHapticProfile.cue(.suspense).isHorror)
        XCTAssertFalse(PhoneHapticProfile.cue(.unlock).isHorror)
        XCTAssertFalse(PhoneHapticProfile.mail.isHorror)
        XCTAssertFalse(PhoneHapticProfile.security.isHorror)
    }

    func testMediaReservationsAreIndependentAndIdempotent() {
        var reservations = PhoneMediaAudioReservations()
        let first = UUID(), second = UUID()
        XCTAssertFalse(reservations.isReserved)
        reservations.begin(first)
        reservations.begin(first)
        reservations.begin(second)
        XCTAssertTrue(reservations.isReserved)
        XCTAssertEqual(reservations.owners.count, 2)
        reservations.end(first)
        reservations.end(first)
        XCTAssertTrue(reservations.isReserved)
        reservations.end(second)
        XCTAssertFalse(reservations.isReserved)
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
