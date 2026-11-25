import XCTest
@testable import LastSeen

@MainActor final class PhoneHapticRoutingTests: XCTestCase {
    func testDistinctPhysicalProfilesAndBounds() {
        let profiles: [PhoneHapticProfile] = [.cue(.message), .mail, .social, .security, .cue(.call), .cue(.timerCompleted), .cue(.unlock), .cue(.authenticationFailed)]
        for profile in profiles {
            XCTAssertGreaterThan(profile.duration, 0)
            XCTAssertLessThan(profile.duration, 1)
            XCTAssertFalse(profile.isInteraction)
            XCTAssertTrue(profile.pulses.allSatisfy { $0.time >= 0 && $0.duration > 0 && (0...1).contains($0.intensity) && (0...1).contains($0.sharpness) })
        }
        XCTAssertNotEqual(PhoneHapticProfile.mail.pulses, PhoneHapticProfile.cue(.message).pulses)
        XCTAssertNotEqual(PhoneHapticProfile.mail.pulses, PhoneHapticProfile.social.pulses)
        XCTAssertTrue(PhoneHapticProfile.cue(.passcodeKeypress).isInteraction)
        XCTAssertTrue(PhoneHapticProfile.cue(.dialerKeypress).isInteraction)
    }

    func testMailOnlyAlertsForNewlyDeliveredInboxRecords() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let store = PhoneWorldStore(initial: RestoredPhoneBackup.snapshot(now: now), persistToDisk: false)
        let baseline = PhoneMailArrival.inboxIDs(in: store.state)
        XCTAssertTrue(baseline.isEmpty)
        XCTAssertTrue(store.sendConnectedMail(draftID: nil, peer: .adrian, subject: "Review", body: "Could you clarify the checklist?", now: now))
        XCTAssertTrue(PhoneMailArrival.added(in: store.state, previous: baseline).isEmpty)
        store.advanceConnectedMail(now: now.addingTimeInterval(29))
        XCTAssertTrue(PhoneMailArrival.added(in: store.state, previous: baseline).isEmpty)
        store.advanceConnectedMail(now: now.addingTimeInterval(31))
        let delivered = PhoneMailArrival.inboxIDs(in: store.state)
        XCTAssertEqual(PhoneMailArrival.added(in: store.state, previous: baseline).count, 1)
        let id = try XCTUnwrap(delivered.first)
        store.moveConnectedMail(id, folder: "archive")
        store.advanceConnectedMail(now: now.addingTimeInterval(90))
        XCTAssertTrue(PhoneMailArrival.added(in: store.state, previous: delivered).isEmpty)
        let decoded = try JSONDecoder().decode(PhoneWorld.self, from: JSONEncoder().encode(store.state))
        XCTAssertTrue(PhoneMailArrival.added(in: decoded, previous: delivered).isEmpty)
    }
}
