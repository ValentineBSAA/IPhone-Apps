import SwiftUI

// All contact actions operate on the restored fictional directory only.
struct LumaCallRoute: Hashable {
    let neighbor: Neighbor
}

/// An explicitly recovered historical exchange, separate from live messages.
enum NoraFriendArchive {
    static let marker = "messages.friend-fragment.opened"
    static let recordID = "messages:maya-restored-fragment"
    static let title = "Maya · recovered conversation fragment"
    struct Line: Identifiable {
        let id:Int
        let fromNora:Bool
        let text:String
        var speaker:String { fromNora ? "Nora" : "Maya" }
    }
    static let lines:[Line] = [
        .init(id:0,fromNora:true,text:"I deleted a caption this morning and then put it back. It's ridiculous that I have to think this hard about a picture of my own breakfast."),
        .init(id:1,fromNora:false,text:"You don't have to explain yourself to strangers. Or to me. Want me to come round?"),
        .init(id:2,fromNora:true,text:"Maybe tomorrow. I want one evening where I don't have to talk about it. I still have half a book to finish."),
        .init(id:3,fromNora:true,text:"That phrase about a collection isn't mine. Someone keeps describing the pictures like I made them for an audience. I didn't."),
        .init(id:4,fromNora:false,text:"Then keep the actual messages. Don't send me any pictures you don't want me to see. We'll work out what you want to do, not what they want."),
        .init(id:5,fromNora:true,text:"Thanks. Coffee when I can look at my phone without thinking about this. The proper kind, not five minutes between meetings.")
    ]
    static func ready(_ world:PhoneWorld)->Bool {
        guard SocialArchiveReview.opened(world),
              world.flags.contains("veil.correspondence.opened"),
              Neighbor.visible(in:world).contains(.maya) else { return false }
        return (world.connectedWorld?.evidenceConnections ?? []).prefix(40).contains {
            Set([$0.first,$0.second]) == Set([SocialArchiveReview.recordID,"veil:conversation"]) &&
                $0.relation == .wording
        }
    }
    static func opened(_ world:PhoneWorld)->Bool { ready(world) && world.flags.contains(marker) }
}

struct NoraFriendArchiveView:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("lastseen.lab.horrorEffects") private var horrorEffects=true
    @AppStorage("lastseen.lab.atmosphereIntensity") private var atmosphereIntensity=LumaArchiveAtmosphere.Intensity.standard.rawValue
    @AppStorage("lastseen.veil.security") private var security="Standard"
    var body:some View {
        ScrollView {
            if NoraFriendArchive.ready(world.state),phase == .active {
                VStack(alignment:.leading,spacing:15) {
                    Text(NoraFriendArchive.title).font(.title2.bold())
                    Text("Restored fragment · Historical sender labels · Original timestamps unavailable").font(.caption).foregroundColor(.secondary)
                    ForEach(NoraFriendArchive.lines) { line in
                        VStack(alignment:line.fromNora ? .trailing : .leading,spacing:4) {
                            Text(line.speaker).font(.caption).foregroundColor(.secondary)
                            Text(line.text).textSelection(.enabled).padding(12)
                                .background(line.fromNora ? Color.teal.opacity(0.23) : Color.secondary.opacity(0.13),in:RoundedRectangle(cornerRadius:14))
                        }.frame(maxWidth:.infinity,alignment:line.fromNora ? .trailing : .leading)
                    }
                    if NoraFriendArchive.opened(world.state) {
                        NavigationLink { EvidenceComparisonView(initialRecordID:NoraFriendArchive.recordID) } label: {
                            Label("Compare with earlier discoveries",systemImage:"rectangle.split.2x1")
                        }
                    }
                    Text("End of restored fragment. This is not a new message or a current statement from Maya.").font(.caption).foregroundColor(.secondary)
                }.padding(16)
            } else { Text("Recovered conversation unavailable.").padding() }
        }.navigationTitle("Recovered messages")
        .overlay {
            if let treatment=LumaArchiveAtmosphere.friendTreatment(world:world.state,active:phase == .active,
                enabled:horrorEffects,intensity:LumaArchiveAtmosphere.Intensity(rawValue:atmosphereIntensity) ?? .off,
                reduceMotion:reduceMotion,security:security) {
                LumaArchiveEdgeTreatment(opacity:treatment.edgeOpacity)
            }
        }
        .onAppear { if phase == .active { world.recordNoraFriendArchiveOpened() } }
        .onChange(of:phase) { if $0 == .active { world.recordNoraFriendArchiveOpened() } }
    }
}

/// Directory search is read-only and never marks a message or archive opened.
enum LumaMessageDirectorySearch {
    struct Row:Identifiable {
        let person:Neighbor
        let message:NeighborMessage
        let unread:Int
        let matchedMessage:Bool
        let preview:String
        let latestDate:Date
        var id:String {person.id}
    }
    static func query(_ raw:String)->String {raw.trimmingCharacters(in:.whitespacesAndNewlines)}
    static func rows(_ world:PhoneWorld,search:String="",unreadOnly:Bool=false)->[Row] {
        let q=query(search)
        return Neighbor.visible(in:world).compactMap { person -> Row? in
            let messages=world.threads[person.id] ?? []
            guard let latest=messages.last else{return nil}
            let unread=messages.filter{!$0.fromPlayer && !$0.read}.count
            guard !unreadOnly || unread>0 else{return nil}
            let contactMatch=q.isEmpty || person.name.localizedCaseInsensitiveContains(q)
            func titles(_ message:NeighborMessage)->[String] {
                (message.attachments ?? []).compactMap {
                    LumaMessageAttachmentCatalog.title($0,world:world)
                }
            }
            let matched = q.isEmpty ? nil : messages.last(where:{
                $0.text.localizedCaseInsensitiveContains(q) || titles($0).contains{$0.localizedCaseInsensitiveContains(q)}
            })
            guard contactMatch || matched != nil else{return nil}
            let selected=matched ?? latest
            let attachments=titles(selected)
            let preview=selected.text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty ?
                (attachments.isEmpty ? "Message" : attachments.joined(separator:", ")) : selected.text
            return Row(person:person,message:selected,unread:unread,matchedMessage:matched != nil,
                       preview:preview,latestDate:latest.at)
        }.sorted {
            let a=q.isEmpty ? $0.latestDate:$0.message.at
            let b=q.isEmpty ? $1.latestDate:$1.message.at
            return a == b ? $0.person.id < $1.person.id : a > b
        }
    }
    static func recoveredSenderMatches(_ world:PhoneWorld,search:String,unreadOnly:Bool)->Bool {
        guard VeilArchive.authorized(world),!unreadOnly else{return false}
        let q=query(search)
        return q.isEmpty || VeilArchive.contactName.localizedCaseInsensitiveContains(q) ||
            (world.flags.contains("veil.correspondence.opened") && VeilArchive.messages(world).contains{$0.text.localizedCaseInsensitiveContains(q)})
    }
    static func recoveredFriendMatches(_ world:PhoneWorld,search:String,unreadOnly:Bool)->Bool {
        guard NoraFriendArchive.ready(world),!unreadOnly else{return false}
        let q=query(search)
        return q.isEmpty || NoraFriendArchive.title.localizedCaseInsensitiveContains(q) ||
            (NoraFriendArchive.opened(world) && NoraFriendArchive.lines.contains{$0.text.localizedCaseInsensitiveContains(q)})
    }
}

struct LumaMessagesDirectory: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var search = ""
    @State private var unreadOnly = false
    @State private var compose = false
    private var rows:[LumaMessageDirectorySearch.Row] {
        LumaMessageDirectorySearch.rows(world.state,search:search,unreadOnly:unreadOnly)
    }
    private var historicalMatch:Bool {
        LumaMessageDirectorySearch.recoveredSenderMatches(world.state,search:search,unreadOnly:unreadOnly)
    }
    private var friendMatch:Bool {
        LumaMessageDirectorySearch.recoveredFriendMatches(world.state,search:search,unreadOnly:unreadOnly)
    }
    var body: some View {
        List {
            Section {
                Picker("Filter conversations", selection: $unreadOnly) {
                    Text("All").tag(false)
                    Text("Unread").tag(true)
                }.pickerStyle(.segmented)
            }.listRowBackground(Color.clear).listRowSeparator(.hidden)
            if rows.isEmpty && !historicalMatch && !friendMatch {
                Label(unreadOnly ? "No unread conversations" : "No conversations found", systemImage: "bubble.left.and.bubble.right")
                    .foregroundColor(.secondary)
            }
            ForEach(rows) { row in
                NavigationLink(value: AppPage.worldThread(row.person)) {
                    HStack(alignment: .center, spacing: 12) {
                        Circle().fill(row.unread > 0 ? LumaDesign.accent : Color.clear).frame(width: 8, height: 8)
                        NeighborAvatar(neighbor: row.person, size: 50)
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(row.person.name).font(.headline)
                                Spacer(minLength: 4)
                                if Calendar.current.isDateInToday(row.message.at) {
                                    Text(row.message.at,style:.time).font(.caption).foregroundColor(.secondary)
                                } else {
                                    Text(row.message.at,style:.date).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            if row.matchedMessage {
                                Text("Matching message").font(.caption2).foregroundColor(LumaDesign.accent)
                            }
                            Text(row.preview).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
                        }
                    }.padding(.vertical, 9)
                }.listRowBackground(LumaDesign.background)
                    .accessibilityHint(row.matchedMessage ? "Opens the matching conversation" : "Opens conversation")
            }
            if historicalMatch || friendMatch {
                Section("Recovered conversations") {
                    if historicalMatch {
                        NavigationLink { VeilHistoricalConversation() } label: {
                            Label("Unknown Number · Recovered conversation",systemImage:"person.crop.circle.badge.questionmark")
                        }
                    }
                    if friendMatch {
                        NavigationLink { NoraFriendArchiveView() } label: {
                            Label(NoraFriendArchive.title,systemImage:"archivebox")
                        }
                    }
                    Text("Historical records do not count as new messages.").font(.caption).foregroundColor(.secondary)
                }
            }
        }.listStyle(.plain).scrollContentBackground(.hidden)
            .background(LumaDesign.background.ignoresSafeArea())
            .navigationTitle("Messages")
            .searchable(text: $search, prompt: "Search messages")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button { compose = true } label: { Image(systemName: "square.and.pencil").accessibilityLabel("New message") }
            } }
            .navigationDestination(isPresented: $compose) { LumaContactsDirectory(messagePicker: true) }
    }
}

struct LumaContactsDirectory: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var search = ""
    var messagePicker = false
    private var people: [Neighbor] {
        LumaPhoneDirectoryPolicy.contacts(world.state,query:search)
    }
    var body: some View {
        List {
            if !messagePicker && search.isEmpty {
                Section {
                    HStack(spacing: 14) {
                        Image(RestoredPhoneBackup.ownerPortrait).resizable().scaledToFill().frame(width: 66, height: 66).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            Text(RestoredPhoneBackup.ownerName).font(.title3.weight(.semibold))
                            Text("My Card").font(.subheadline).foregroundColor(.secondary)
                        }
                    }.padding(.vertical, 10)
                }
            }
            if !messagePicker && VeilArchive.authorized(world.state) && (search.isEmpty || VeilArchive.contactName.localizedCaseInsensitiveContains(search)) {
                NavigationLink { VeilHistoricalConversation() } label: {
                    Label("Unknown Number · Recovered sender",systemImage:"person.crop.circle.badge.questionmark")
                }
            }
            if people.isEmpty { Text("No contacts found").foregroundColor(.secondary) }
            ForEach(people) { person in
                NavigationLink(value: messagePicker ? AppPage.worldThread(person) : AppPage.worldProfile(person)) {
                    LumaContactRow(person: person)
                }
            }
            Text("\(people.count) contacts").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity)
        }.listStyle(.insetGrouped).scrollContentBackground(.hidden)
            .background(LumaDesign.background.ignoresSafeArea())
            .navigationTitle(messagePicker ? "New message" : "Contacts")
            .searchable(text: $search, prompt: "Search contacts")
    }
}

private struct LumaContactRow: View {
    let person: Neighbor
    var body: some View {
        HStack(spacing: 12) {
            NeighborAvatar(neighbor: person, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name).font(.headline)
                Text(person.subtitle).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 6)
    }
}

struct LumaPhoneDirectory: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.lab.messageSound") private var sound = true
    @AppStorage("lastseen.lab.messageHaptics") private var haptics = true
    @State private var dialDigits = ""
    @State private var tab = 0
    @State private var search = ""
    private var people: [Neighbor] {
        LumaPhoneDirectoryPolicy.contacts(world.state,query:search,favoritesOnly:tab==0)
    }
    var body: some View {
        VStack(spacing: 0) {
            if tab == 3 { keypad } else {
            List {
                if tab == 1 {
                    let recents=LumaPhoneDirectoryPolicy.recents(world.state,query:search)
                    if recents.isEmpty { Text(search.isEmpty ? "No recent calls":"No matching calls").foregroundColor(.secondary) }
                    ForEach(recents) { call in
                        NavigationLink(value: LumaCallRoute(neighbor: call.contact)) {
                            HStack {
                                LumaContactRow(person: call.contact)
                                VStack(alignment: .trailing) {
                                    if Calendar.current.isDateInToday(call.date) {
                                        Text(call.date,style:.time).font(.caption)
                                    } else {
                                        Text(call.date,style:.date).font(.caption)
                                    }
                                    Text(call.outcomeTitle).font(.caption2)
                                }.foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    if people.isEmpty { Text(tab == 0 ? "Add favorites from Contacts" : "No contacts found").foregroundColor(.secondary) }
                    ForEach(people) { person in
                        NavigationLink(value: LumaCallRoute(neighbor: person)) { LumaContactRow(person: person) }
                            .swipeActions(edge:.trailing,allowsFullSwipe:false) {
                                Button {
                                    world.toggleFavoriteContact(person)
                                } label:{
                                    Label((world.state.favoriteContacts ?? []).contains(person.id) ? "Remove favorite":"Favorite",systemImage:"star")
                                }.tint(.orange)
                            }
                    }
                }
            }.listStyle(.plain).scrollContentBackground(.hidden)
            }
            Divider()
            HStack {
                tabButton(0, "Favorites", "star.fill")
                tabButton(1, "Recents", "clock")
                tabButton(2, "Contacts", "person.crop.circle")
                tabButton(3, "Keypad", "circle.grid.3x3.fill")
            }.padding(.vertical, 8).background(LumaDesign.surface)
        }.background(LumaDesign.background.ignoresSafeArea())
            .navigationTitle("Phone").searchable(text: $search, prompt: "Search phone")
    }
    private var keypad: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(dialDigits.isEmpty ? "Enter number" : dialDigits)
                    .font(.title.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.5)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(["1","2","3","4","5","6","7","8","9","*","0","#"], id: \.self) { key in
                        Button {
                            guard dialDigits.count < 24 else { return }
                            dialDigits += key
                            PhoneSensoryEngine.play(.dialerKeypress, sound: sound, haptics: haptics, horrorEnabled: false)
                        } label: {
                            Text(key).font(.title2).frame(maxWidth: .infinity, minHeight: 48).lumaSurface(radius: 18)
                        }.buttonStyle(.plain)
                    }
                }.frame(maxWidth: 310)
                HStack {
                    Button("Delete digit") { if !dialDigits.isEmpty { dialDigits.removeLast() } }.disabled(dialDigits.isEmpty)
                    Spacer()
                    Button("Clear") {dialDigits=""}.disabled(dialDigits.isEmpty)
                }.frame(maxWidth:310)
                Text("Fictional keypad only. Use Contacts to place a simulated call. No real number is dialed.").font(.caption).foregroundColor(.secondary)
            }.padding()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private func tabButton(_ index: Int, _ name: String, _ icon: String) -> some View {
        Button { tab = index } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.title3)
                Text(name).font(.caption)
            }.frame(maxWidth: .infinity, minHeight: 48)
                .foregroundColor(tab == index ? LumaDesign.accent : .secondary)
        }.buttonStyle(.plain).accessibilityAddTraits(tab == index ? .isSelected : []).accessibilityIdentifier("luma.phone.tab." + name)
    }
}

struct LumaCallView: View {
    let neighbor: Neighbor
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var status = "Ready to call"
    @State private var calling = false
    @State private var attemptID:UUID?
    private var available:Bool {LumaPhoneDirectoryPolicy.canCall(neighbor,in:world.state)}
    private func finish(_ outcome:LumaCallRecord.Outcome) {
        if let id=attemptID {world.finishCallAttempt(id,outcome:outcome)}
        attemptID=nil;calling=false;status=outcome.title
    }
    var body: some View {
        VStack(spacing: 24) {
            if available && phase == .active {
            Spacer()
            NeighborAvatar(neighbor: neighbor, size: 132)
            Text(neighbor.name).font(.largeTitle.weight(.semibold))
            Text(status).foregroundColor(.secondary).accessibilityAddTraits(.updatesFrequently)
            Spacer()
            HStack(spacing: 36) {
                NavigationLink(value: AppPage.worldThread(neighbor)) {
                    Label("Message", systemImage: "message.fill").frame(minHeight: 44)
                }
                Button {
                    if calling {finish(.ended)}
                    else if phase == .active,let id=world.recordCallAttempt(neighbor) {
                        attemptID=id;status="Calling…";calling=true
                    }
                } label: {
                    Image(systemName: calling ? "phone.down.fill" : "phone.fill").font(.title2)
                        .frame(width: 68, height: 68)
                        .background(calling ? Color.red : Color.green, in: Circle()).foregroundColor(.white)
                        .accessibilityLabel(calling ? "End fictional call" : "Start fictional call")
                }.buttonStyle(.plain).accessibilityIdentifier("luma.phone.call")
            }
            Text("Fictional calls only. No real dialing or connected voice call.").font(.caption)
                .foregroundColor(.secondary).multilineTextAlignment(.center)
            } else {Text("Contact unavailable.").foregroundColor(.secondary)}
        }.padding(24).frame(maxWidth: .infinity)
            .background(LumaDesign.background.ignoresSafeArea())
            .navigationTitle("Call").navigationBarTitleDisplayMode(.inline)
            .task(id: calling) {
                guard calling else { return }
                do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
                guard !Task.isCancelled, calling else { return }
                finish(.noAnswer)
            }
            .onChange(of:phase) {if $0 != .active && calling {finish(.ended)}}
            .onChange(of:available) {if !$0 && calling {attemptID=nil;calling=false;status="Contact unavailable."}}
            .onChange(of:world.state.callHistory) {records in
                if let id=attemptID,!(records ?? []).contains(where:{$0.id==id}) {
                    attemptID=nil;calling=false;status="Ready to call"
                }
            }
            .onDisappear {if calling {finish(.ended)}}
    }
}
