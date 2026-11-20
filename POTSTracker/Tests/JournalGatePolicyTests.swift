import XCTest
import SwiftUI
@testable import POTSTracker

final class JournalGatePolicyTests: XCTestCase {
    func testInactiveIsNotBackgroundAndMustNotLockAnAlreadyUnlockedJournal() {
        XCTAssertFalse(JournalGatePolicy.shouldLockForScene(.inactive))
        XCTAssertFalse(JournalGatePolicy.shouldLockForScene(.active))
        XCTAssertTrue(JournalGatePolicy.shouldLockForScene(.background))

        // Face ID may temporarily make SwiftUI report inactive.
        // A successful authentication still counts as unlocked.
        XCTAssertFalse(JournalGatePolicy.needsPrompt(
            enabled: true, unlocked: true, waitingForReply: false, scene: .inactive
        ))
        XCTAssertFalse(JournalGatePolicy.needsPrompt(
            enabled: true, unlocked: true, waitingForReply: false, scene: .active
        ))
    }

    func testInitialJournalEntryPromptsOnceAndNotWhilePending() {
        XCTAssertTrue(JournalGatePolicy.needsPrompt(
            enabled: true, unlocked: false, waitingForReply: false, scene: .active
        ))
        XCTAssertFalse(JournalGatePolicy.needsPrompt(
            enabled: true, unlocked: false, waitingForReply: true, scene: .active
        ))
    }

    func testBackgroundThenForegroundCanReauthenticate() {
        XCTAssertFalse(JournalGatePolicy.needsPrompt(
            enabled: true, unlocked: false, waitingForReply: false, scene: .background
        ))
        XCTAssertTrue(JournalGatePolicy.needsPrompt(
            enabled: true, unlocked: false, waitingForReply: false, scene: .active
        ))
    }

    func testDisabledLockDoesNotPromptInAnyScene() {
        for scene: ScenePhase in [.active, .inactive, .background] {
            XCTAssertFalse(JournalGatePolicy.needsPrompt(
                enabled: false, unlocked: false, waitingForReply: false, scene: scene
            ))
        }
    }

    func testRetryRequiresPendingAttemptToBeClearedBeforePrompt() {
        XCTAssertFalse(JournalGatePolicy.needsPrompt(
            enabled: true, unlocked: false, waitingForReply: true, scene: .active
        ))
        XCTAssertTrue(JournalGatePolicy.needsPrompt(
            enabled: true, unlocked: false, waitingForReply: false, scene: .active
        ))
    }
}
