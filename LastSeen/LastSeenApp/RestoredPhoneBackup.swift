import Foundation

/// Development snapshot. Nora's owner identity and approved contact portrait are canonical.
enum RestoredPhoneBackup {
    static let ownerName = "Nora Bennett"
    static let ownerPortrait = "Nora_Profile"
    static var url: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("lastseen-restored-phone-v1.json")
    }

    static func snapshot(now: Date = Date()) -> PhoneWorld {
        let day: TimeInterval = 86400
        let calendar = Calendar.current
        let morning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        let inspection = calendar.date(byAdding: .day, value: 1, to: morning) ?? now
        let coffee = calendar.date(byAdding: .day, value: 2, to: morning) ?? now
        var restored = PhoneWorld(createdAt: now,
            threads: [
                "maya": [
                    NeighborMessage(id: "maya-old-1", thread: "maya", text: "Nora, that book you lent me was SO good.", fromPlayer: false, at: now.addingTimeInterval(-day * 7), read: true),
                    NeighborMessage(id: "maya-old-2", thread: "maya", text: "Keep it until next week! I'm not in a rush.", fromPlayer: true, at: now.addingTimeInterval(-day * 7 + 90), read: true),
                    NeighborMessage(id: "maya-old-3", thread: "maya", text: "Thank you for coming over yesterday. Needed that.", fromPlayer: false, at: now.addingTimeInterval(-day * 3), read: true),
                    NeighborMessage(id: "maya-old-4", thread: "maya", text: "Anytime ❤️", fromPlayer: true, at: now.addingTimeInterval(-day * 3 + 65), read: true),
                    NeighborMessage(id: "maya-hello", thread: "maya", text: "Hey! Are we still doing coffee this week?", fromPlayer: false, at: now.addingTimeInterval(-420)),
                    NeighborMessage(id: "maya-followup", thread: "maya", text: "No rush. Just trying to plan around work lol", fromPlayer: false, at: now.addingTimeInterval(-350))
                ],
                "denise": [
                    NeighborMessage(id: "denise-old-1", thread: "denise", text: "Hi Nora, your parcel is at the building office.", fromPlayer: false, at: now.addingTimeInterval(-day * 5), read: true),
                    NeighborMessage(id: "denise-old-2", thread: "denise", text: "Thanks! I'll pick it up after work.", fromPlayer: true, at: now.addingTimeInterval(-day * 5 + 120), read: true),
                    NeighborMessage(id: "denise-hello", thread: "denise", text: "Hi! Elevator maintenance is scheduled this week. The front entrance will stay open.", fromPlayer: false, at: now.addingTimeInterval(-780))
                ]
            ],
            notes: [
                PhoneNote(id: "shopping", title: "Pick up", body: "Coffee beans\nPaper towels\nBatteries", modifiedAt: now.addingTimeInterval(-day), pinned: false),
                PhoneNote(id: "weekend", title: "Weekend", body: "Return Maya's container. Pick up my book. Water the plants.", modifiedAt: now.addingTimeInterval(-day * 2), pinned: false),
                PhoneNote(id: "building", title: "Building information", body: "My apartment: 402\nMaintenance desk: lobby\nDenise: building office", modifiedAt: now.addingTimeInterval(-day * 4), pinned: true),
                PhoneNote(id: "personal", title: "Little things", body: "Find a frame for the new photo. Remember to call Mum on Sunday.\n— Nora", modifiedAt: now.addingTimeInterval(-day * 8), pinned: false)
            ],
            events: [
                PhoneEvent(id: "inspection", title: "Building elevator inspection", detail: "Building office notice. Exact schedule subject to confirmation.", startsAt: inspection, endsAt: inspection.addingTimeInterval(3600)),
                PhoneEvent(id: "coffee", title: "Coffee with Maya?", detail: "Tentative. Confirm by text.", startsAt: coffee.addingTimeInterval(7200), endsAt: coffee.addingTimeInterval(10800)),
                PhoneEvent(id: "pickup", title: "Pick up book", detail: "Maple Street Bookshop", startsAt: morning.addingTimeInterval(25200), endsAt: morning.addingTimeInterval(27000))
            ])
        NoraEverydayArchive.expand(&restored)
        return restored
    }

    enum ExistingStatus:Equatable {case absent,readable,unreadable}
    static func existingStatus(at destination:URL=url)->ExistingStatus {
        guard FileManager.default.fileExists(atPath:destination.path) else{return .absent}
        guard let data=try? Data(contentsOf:destination),
              let world=try? JSONDecoder().decode(PhoneWorld.self,from:data),
              world.version==1 else{return .unreadable}
        return .readable
    }

    /// Atomic and idempotent: never overwrite a player's already-restored world.
    static func restore(to destination: URL = url, now: Date = Date()) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            guard existingStatus(at:destination) == .readable else{throw CocoaError(.fileReadCorruptFile)}
            return
        }
        let data = try JSONEncoder().encode(snapshot(now: now))
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: destination, options: .atomic)
    }
}
