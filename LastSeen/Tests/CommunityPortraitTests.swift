import XCTest
import UIKit
@testable import LastSeen

@MainActor final class CommunityPortraitTests: XCTestCase {
    func testAllPortraitsAreBundledAndDistinctAssignments() throws {
        for i in 1...18 {
            let name = String(format: "CommunityPortrait_%02d", i)
            let art = try XCTUnwrap(UIImage(named: name, in: Bundle(for: PhoneWorldStore.self), compatibleWith: nil), name)
            XCTAssertGreaterThanOrEqual(art.size.width, 128)
            XCTAssertGreaterThanOrEqual(art.size.height, 128)
        }
        let posts = LumaSocialCommunity.posts(anchor: Date(timeIntervalSince1970: 1_800_000_000))
        XCTAssertEqual(Set(posts.compactMap(\.portrait)).count, 36)
        for name in Set(posts.compactMap(\.portrait)) {
            let art = try XCTUnwrap(UIImage(named: name, in: Bundle(for: PhoneWorldStore.self), compatibleWith: nil), name)
            XCTAssertGreaterThanOrEqual(art.size.width, 128)
            XCTAssertGreaterThanOrEqual(art.size.height, 128)
        }
        XCTAssertTrue(posts.allSatisfy { $0.portrait != nil })
        XCTAssertEqual(LumaSocialCommunity.portraits.count, 36)
    }
}
