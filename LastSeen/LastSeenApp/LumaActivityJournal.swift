import SwiftUI

/// Fictional local activity. No real push messages, network or OS notification access.
struct LumaActivityNotice: Codable, Equatable, Identifiable {
    enum Kind: String, Codable { case mail, social, timer, dayblink, security, support, motionwell }
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
        case .security: return "HavenWatch"
        case .support: return "Relay Support"
        case .motionwell: return "Motionwell"
        }
    }
    var symbol: String {
        switch kind {
        case .mail: return "envelope.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .timer: return "timer"
        case .dayblink: return "camera.fill"
        case .security: return "shield.lefthalf.filled"
        case .support: return "headset"
        case .motionwell: return "play.rectangle.fill"
        }
    }
    var cue: PhoneCue { kind == .timer ? .timerCompleted : kind == .security ? .corrupted : .general }
    var profile: PhoneHapticProfile {
        switch kind {
        case .mail: return .mail
        case .social, .dayblink, .support, .motionwell: return .social
        case .timer: return .cue(.timerCompleted)
        case .security: return .security
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
            guard prefs.notificationsEnabled, !(author.map { prefs.mutedAuthors.contains($0) } ?? false),
                  LumaSocialCatalog.visible(channel, world: state).contains(where: { $0.id == targetID }) else { return false }
            if id.hasPrefix("community-post-") {
                guard prefs.followedPostAlerts ?? true, let author,
                      state.connectedWorld?.follows.contains(channel.rawValue + "|" + author) == true,
                      state.connectedWorld?.communityActivity?.posts.contains(where: { $0.id == targetID && $0.author == author && $0.channel == channel }) == true else { return false }
            }
            return true
        case .timer: return true
        case .motionwell:
            guard let targetID else { return false }
            return MotionwellArchive.canNotify(targetID, world: state)
        case .support:
            guard let targetID, let history = state.relaySupport,
                  history.activeInstallation == true, history.notificationsEnabled ?? true,
                  !(history.seenIDs ?? []).contains(targetID) else { return false }
            return history.messages.contains { !$0.outgoing && $0.id == targetID }
        case .security:
            return (state.connectedWorld?.havenWatch?.alertsEnabled ?? true) && HavenWatchEvents.visible(state).map { $0.id == targetID } == true
        case .dayblink:
            guard state.everydayArchiveRevision != nil, let targetID, let d = state.connectedWorld?.dayblink,
                  d.notificationsEnabled,
                  let record = d.messages.first(where: { $0.id == targetID }),
                  !d.muted.contains(record.friend) else { return false }
            return DayblinkArchive.image(for: record, state: d) != nil
        }
    }
    func hidePreview(in state: PhoneWorld) -> Bool {
        if kind == .security { return true }
        if kind == .support { return !(state.relaySupport?.previewsEnabled ?? false) }
        if kind == .motionwell { return !(state.connectedWorld?.motionwell?.previewsEnabled ?? false) }
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

/// Transient foreground presentation queue. Persisted records remain in
/// activityJournal; suppressing a banner never removes its destination.
struct LumaActivityBannerQueue {
    private(set) var ids: [String] = []
    mutating func enqueue(_ notices: [LumaActivityNotice], showing: String?) {
        for notice in notices where notice.id != showing && !ids.contains(notice.id) {
            ids.append(notice.id)
        }
        // The full history remains accessible if a large restore batch arrives.
        ids = Array(ids.prefix(20))
    }
    mutating func next(in state: PhoneWorld) -> LumaActivityNotice? {
        let visible = LumaActivityCatalog.visible(state)
        while !ids.isEmpty {
            let id = ids.removeFirst()
            if let notice = visible.first(where: { $0.id == id }) { return notice }
        }
        return nil
    }
    mutating func clear() { ids.removeAll() }
}

/// One completion per timer deadline, independent of whether the alert
/// was presented while the app was active.
enum LumaTimerCompletion {
    static func due(end: Double, delivered: Double, now: Double) -> Bool {
        end.isFinite && now.isFinite && end > 0 && end != delivered && end <= now
    }
    static func restoredDeadline(_ end: Double, savedAt: Double, now: Double) -> Double {
        guard end.isFinite, savedAt.isFinite, now.isFinite, end > 0 else { return 0 }
        // Completed timers retain their original journal identity; only running
        // timers have their remaining duration rebased.
        return end <= savedAt ? end : now + (end - savedAt)
    }
}

struct LumaActivityRoute: Hashable {
    let id: String
}

enum LumaActivityCatalog {
    static func visible(_ state: PhoneWorld) -> [LumaActivityNotice] {
        (state.connectedWorld?.activityJournal ?? []).filter { !$0.dismissed && $0.canPresent(in: state) }
            .sorted { ($0.date, $0.id) > ($1.date, $1.id) }
    }
    /// The visible timer must use current persisted eligibility rather than
    /// the original banner snapshot, including dismissal and privacy changes.
    static func presentedID(_ notice: LumaActivityNotice?, in state: PhoneWorld, unobstructed: Bool) -> String? {
        guard unobstructed, let id = notice?.id,
              visible(state).contains(where: { $0.id == id }) else { return nil }
        return id
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
        (world.connected.activityJournal ?? []).first { notice in
            guard notice.id == id else { return false }
            if notice.kind == .motionwell {
                return MotionwellArchive.visible(world.state).contains { $0.id == notice.targetID }
            }
            return notice.canPresent(in: world.state)
        }
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
            case .security:
                HavenWatchEventDetail()
            case .support:
                RelaySupportView()
            case .motionwell:
                if let target = notice.targetID, let clip = MotionwellArchive.visible(world.state).first(where: { $0.id == target }) {
                    MotionwellPlayerView(clip: clip)
                } else { Text("Video unavailable") }
            case .dayblink:
                if let author = notice.author, let friend = DayblinkFriend(rawValue: author) {
                    DayblinkThread(friend: friend)
                } else { Text("Conversation unavailable") }
            }
        } else { Text("Activity unavailable").padding() }
    }
}
