import XCTest
import UIKit
@testable import LastSeen

@MainActor final class CommunityMediaUseTests: XCTestCase {
    func testCommunityMediaIsBoundToAuthoredPublicRecords() throws {
        let world = RestoredPhoneBackup.snapshot(now: Date(timeIntervalSince1970: 1_800_000_000))
        let posts = LumaSocialCommunity.posts(anchor: world.createdAt)
        let images = posts.compactMap { LumaSocialCatalog.visiblePhoto($0, world: world) }
        XCTAssertEqual(images.count, 6)
        XCTAssertEqual(Set(images).count, 6)
        for asset in images {
            XCTAssertNotNil(UIImage(named: asset, in: Bundle(for: PhoneWorldStore.self), compatibleWith: nil), asset)
        }
        let original = try XCTUnwrap(posts.first(where: { $0.photo != nil }))
        let forged = LumaSocialPost(id: original.id, channel: original.channel, author: "Repair desk", handle: original.handle, body: original.body, date: original.date, portrait: nil, photo: original.photo, gate: nil)
        XCTAssertNil(LumaSocialCommunity.publicPhoto(forged))
        let base = PhoneWorldStore(persistToDisk: false)
        XCTAssertNil(LumaSocialCatalog.visiblePhoto(original, world: base.state))
        XCTAssertTrue(LumaSocialCatalog.visible(.afterframe, world: base.state).isEmpty)
    }
}
