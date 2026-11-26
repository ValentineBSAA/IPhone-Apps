import SwiftUI

/// Fictional local activity. No real push messages, network or OS notification access.
struct LumaActivityNotice: Codable, Equatable, Identifiable {
    enum Kind: String, Codable { case mail, social, timer, dayblink }
    let id: String
    let kind: Kind
    let date: Date
    let title: String
    let detail: String
    let targetID: String?
    let channel: LumaSocialChannel?
    let author: String?
    var dismissed = false
    var appTitle: String {
        switch kind {
        case .mail: return "Mail"
        case .social: return channel?.rawValue ?? "Social"
        case .timer: return "Clock"
        case .dayblink: return "Dayblink"
        }
    }
    var symbol: String {
        switch kind {
        case .mail: return "envelope.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .timer: return "timer"
        case .dayblink: return "camera.fill"
        }
    }
    var cue: PhoneCue { kind == .timer ? .timerCompleted : .general }
    var profile: PhoneHapticProfile {
        switch kind {
        case .mail: return .mail
        case .social, .dayblink: return .social
        case .timer: return .cue(.timerCompleted)
        }
    }
    func canPresent(in state: PhoneWorld) -> Bool {
        switch kind {
        case .mail:
            guard let targetID else { return false }
            return (state.connectedWorld?.mail ?? []).contains { $0.id == targetID && $0.kind == "inbox" }
                && (targetID != InvestigationReview.mailID || InvestigationReview.availableMail(state))
                && (targetID != InvestigationResolution.mailID || InvestigationResolution.availableMail(state))
                && (state.connectedWorld?.mailFolders[targetID] == nil || state.connectedWorld?.mailFolders[targetID] == "original")
        case .social:
            guard let channel, let targetID else { return false }
            let prefs = state.connectedWorld?.socialPreferences?[channel.rawValue] ?? LumaSocialPreferences()
            return prefs.notificationsEnabled && !(author.map { prefs.mutedAuthors.contains($0) } ?? false)
                && LumaSocialCatalog.visible(channel, world: state).contains { $0.id == targetID }
        case .timer: return true
        case .dayblink:
            guard state.everydayArchiveRevision != nil, let targetID, let d = state.connectedWorld?.dayblink,
                  d.notificationsEnabled,
                  let record = d.messages.first(where: { $0.id == targetID }),
                  !d.muted.contains(record.friend) else { return false }
            return DayblinkArchive.image(for: record, state: d) != nil
        }
    }
    func hidePreview(in state: PhoneWorld) -> Bool {
        if kind == .dayblink { return !(state.connectedWorld?.dayblink?.previewsEnabled ?? false) }
        guard let channel else { return false }
        return !(state.connectedWorld?.socialPreferences?[channel.rawValue]?.showPreviews ?? true)
    }
}

struct LumaPendingSocialReply: Codable, Equatable {
    let channel: LumaSocialChannel
    let reply: LumaSocialComment
    let dueAt: Date
}

struct LumaActivityRoute: Hashable {
    let id: String
}

enum LumaActivityCatalog {
    static func visible(_ state: PhoneWorld) -> [LumaActivityNotice] {
        (state.connectedWorld?.activityJournal ?? []).filter { !$0.dismissed && $0.canPresent(in: state) }
            .sorted { ($0.date, $0.id) > ($1.date, $1.id) }
    }
    static func newEntries(_ state: PhoneWorld, previous: Set<String>) -> [LumaActivityNotice] {
        Array(visible(state).filter { !previous.contains($0.id) }.reversed())
    }
    static func allIDs(_ state: PhoneWorld) -> Set<String> {
        Set((state.connectedWorld?.activityJournal ?? []).map(\.id))
    }
    /// Limited authored reactions, only from independent community accounts.
    /// Never impersonate the restored phone owner, infer private details or reply to arbitrary text.
    static func communityReply(post: LumaSocialPost, text: String, id: String, now: Date) -> LumaPendingSocialReply? {
        guard LumaSocialCommunity.people.contains(where: { $0.handle == post.handle && $0.name == post.author }),
              post.id.hasPrefix("b32-community-") else { return nil }
        let clean = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let responses = ["thank you": "You're welcome!", "thanks": "You're welcome!", "nice post": "Thanks! Glad you liked it.", "love this": "Thank you, that's kind of you."]
        guard let answer = responses[clean] else { return nil }
        let due = now.addingTimeInterval(18)
        return .init(channel: post.channel, reply: .init(id: "community-reply-" + id, postID: post.id, author: post.author, body: answer, date: due), dueAt: due)
    }
}

struct LumaActivityCard: View {
    let notice: LumaActivityNotice
    let hidePreview: Bool
    let open: () -> Void
    var body: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Image(systemName: notice.symbol).foregroundColor(.teal)
                    Text(notice.appTitle.uppercased()).font(.caption2.weight(.semibold))
                    Spacer()
                    Text(notice.date, style: .relative).font(.caption2)
                }.foregroundColor(.secondary)
                Text(hidePreview ? "New activity" : notice.title).font(.subheadline.bold())
                Text(hidePreview ? "Open app to view" : notice.detail).font(.subheadline).lineLimit(3)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(13).lumaSurface(radius: 20)
        }.buttonStyle(.plain)
            .accessibilityLabel(hidePreview ? notice.appTitle + ", new activity" : notice.appTitle + ", " + notice.title + ", " + notice.detail)
    }
}

struct LumaActivityDetail: View {
    let id: String
    @EnvironmentObject private var world: PhoneWorldStore
    private var notice: LumaActivityNotice? {
        (world.connected.activityJournal ?? []).first { $0.id == id && $0.canPresent(in: world.state) }
    }
    var body: some View {
        if let notice {
            switch notice.kind {
            case .mail:
                if let target = notice.targetID { LumaMailDetail(id: target) }
                else { Text("Message unavailable") }
            case .social:
                if let channel = notice.channel, let target = notice.targetID { LumaSocialDiscussion(channel: channel, postID: target) }
                else { Text("Discussion unavailable") }
            case .timer:
                Text("Your timer has finished.").padding().navigationTitle("Clock")
            case .dayblink:
                if let author = notice.author, let friend = DayblinkFriend(rawValue: author) {
                    DayblinkThread(friend: friend)
                } else { Text("Conversation unavailable") }
            }
        } else { Text("Activity unavailable").padding() }
    }
}
