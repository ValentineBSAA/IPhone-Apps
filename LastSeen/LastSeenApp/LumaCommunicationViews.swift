import SwiftUI

// All contact actions operate on the restored fictional directory only.
struct LumaCallRoute: Hashable {
    let neighbor: Neighbor
}

struct LumaMessagesDirectory: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var search = ""
    @State private var unreadOnly = false
    @State private var compose = false
    private var people: [Neighbor] {
        Neighbor.visible(in: world.state).filter { person in
            !world.messages(person).isEmpty &&
            (!unreadOnly || world.countUnread(person) > 0) &&
            (search.isEmpty || person.name.localizedCaseInsensitiveContains(search) ||
             world.messages(person).contains { $0.text.localizedCaseInsensitiveContains(search) })
        }.sorted { (world.messages($0).last?.at ?? .distantPast) > (world.messages($1).last?.at ?? .distantPast) }
    }
    var body: some View {
        List {
            Section {
                Picker("Filter conversations", selection: $unreadOnly) {
                    Text("All").tag(false)
                    Text("Unread").tag(true)
                }.pickerStyle(.segmented)
            }.listRowBackground(Color.clear).listRowSeparator(.hidden)
            if people.isEmpty {
                Label(unreadOnly ? "No unread conversations" : "No conversations found", systemImage: "bubble.left.and.bubble.right")
                    .foregroundColor(.secondary)
            }
            ForEach(people) { person in
                NavigationLink(value: AppPage.worldThread(person)) {
                    HStack(alignment: .center, spacing: 12) {
                        Circle().fill(world.countUnread(person) > 0 ? LumaDesign.accent : Color.clear).frame(width: 8, height: 8)
                        NeighborAvatar(neighbor: person, size: 50)
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(person.name).font(.headline)
                                Spacer(minLength: 4)
                                if let last = world.messages(person).last {
                                    Text(last.at, style: .time).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Text(world.messages(person).last?.text ?? "").font(.subheadline)
                                .foregroundColor(.secondary).lineLimit(2)
                        }
                    }.padding(.vertical, 9)
                }.listRowBackground(LumaDesign.background)
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
        Neighbor.visible(in: world.state).filter { $0 != .unknown && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.subtitle.localizedCaseInsensitiveContains(search)) }
            .sorted { $0.name < $1.name }
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
        Neighbor.visible(in: world.state).filter { person in
            person != .unknown && (tab != 0 || (world.state.favoriteContacts ?? []).contains(person.id)) &&
            (search.isEmpty || person.name.localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            if tab == 3 { keypad } else {
            List {
                if tab == 1 {
                    if (world.state.callHistory ?? []).isEmpty { Text("No recent calls").foregroundColor(.secondary) }
                    ForEach((world.state.callHistory ?? []).filter { search.isEmpty || $0.contact.name.localizedCaseInsensitiveContains(search) }) { call in
                        NavigationLink(value: LumaCallRoute(neighbor: call.contact)) {
                            HStack {
                                LumaContactRow(person: call.contact)
                                VStack(alignment: .trailing) {
                                    Text(call.date, style: .relative).font(.caption)
                                    Text("Outgoing").font(.caption2)
                                }.foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    if people.isEmpty { Text(tab == 0 ? "Add favorites from Contacts" : "No contacts found").foregroundColor(.secondary) }
                    ForEach(people) { person in
                        NavigationLink(value: LumaCallRoute(neighbor: person)) { LumaContactRow(person: person) }
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
                Button("Delete digit") { if !dialDigits.isEmpty { dialDigits.removeLast() } }.disabled(dialDigits.isEmpty)
                Text("Fictional keypad only. No real number is dialed.").font(.caption).foregroundColor(.secondary)
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
    var body: some View {
        VStack(spacing: 24) {
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
                    if calling { calling = false; status = "Call ended" }
                    else { world.recordCallAttempt(neighbor); status = "Calling…"; calling = true }
                } label: {
                    Image(systemName: calling ? "phone.down.fill" : "phone.fill").font(.title2)
                        .frame(width: 68, height: 68)
                        .background(calling ? Color.red : Color.green, in: Circle()).foregroundColor(.white)
                        .accessibilityLabel(calling ? "End fictional call" : "Start fictional call")
                }.buttonStyle(.plain).accessibilityIdentifier("luma.phone.call")
            }
            Text("Fictional calls only. No real dialing or connected voice call.").font(.caption)
                .foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding(24).frame(maxWidth: .infinity)
            .background(LumaDesign.background.ignoresSafeArea())
            .navigationTitle("Call").navigationBarTitleDisplayMode(.inline)
            .task(id: calling) {
                guard calling else { return }
                do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
                guard !Task.isCancelled, calling else { return }
                calling = false; status = "No answer"
            }
            .onChange(of: phase) { if $0 != .active && calling { calling = false; status = "Call ended" } }
    }
}
