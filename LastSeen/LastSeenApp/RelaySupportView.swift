import SwiftUI

enum RelaySupportAccess {
    static func available(installed: String, flags: Set<String>) -> Bool {
        RelayCatalog.tweakActive("relay-support", installed: installed, safeMode: false, flags: flags)
    }
}
struct RelaySupportMessage: Codable, Equatable, Identifiable {
    let id: String
    let text: String
    let at: Date
    let outgoing: Bool
    var guideID: String? = nil
    var packageID: String? = nil
}
struct RelaySupportHistory: Codable, Equatable {
    var messages: [RelaySupportMessage]
}
struct RelaySupportView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    @AppStorage("lastseen.relay.sources") private var sources = RelayCatalog.defaultSources
    @State private var tab = "Chat"
    @State private var draft = ""
    @State private var failure = false
    private var messages: [RelaySupportMessage] { world.state.relaySupport?.messages ?? [] }
    private func send() {
        if world.sendRelaySupport(draft, installed: installed, sources: sources) { draft = "" }
        else { failure = true }
    }
    private var available: Bool { RelaySupportAccess.available(installed: installed, flags: world.state.flags) }
    var body: some View {
        VStack(spacing: 12) {
            if available {
                HStack(spacing: 12) {
                    Image("Support_AlexMorgan").resizable().scaledToFill().frame(width: 52, height: 52).clipShape(Circle())
                    VStack(alignment: .leading) {
                        Text("Alex Morgan").font(.headline)
                        Text("Recovery & technical support").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }.padding(.horizontal, 18)
                Picker("Support section", selection: $tab) {
                    ForEach(["Chat","Guides","Diagnostics","Settings"], id: \.self) { Text($0).tag($0) }
                }.pickerStyle(.segmented).padding(.horizontal, 12)
                switch tab {
                case "Guides":
                    List(RelaySupportKnowledge.generalGuides()) { guide in
                        NavigationLink { RelaySupportGuideReader(id: guide.id) } label: { Label(guide.title, systemImage: "doc.richtext") }
                    }
                case "Diagnostics":
                    List {
                        LabeledContent("Environment", value: safeMode ? "Safe Mode" : "Rootless")
                        Text("Diagnostics are local to the fictional phone. Sharing selected package details with Alex requires a future explicit consent step.").font(.caption).foregroundColor(.secondary)
                    }
                case "Settings":
                    List {
                        Label("Fictional support character", systemImage: "person.crop.circle")
                        Text("Conversation history is separate from the owner's Messages. Removing this package preserves that history. No real-device data or remote service is connected.").font(.subheadline)
                        Text("Local knowledge search · Limited offline help, not generative AI.").foregroundColor(.secondary)
                    }
                default:
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    HStack {
                                        if message.outgoing { Spacer(minLength: 28) }
                                        VStack(alignment: message.outgoing ? .trailing : .leading, spacing: 6) {
                                            Text(message.text).padding(12)
                                                .background(message.outgoing ? Color.teal.opacity(0.3) : LumaDesign.raised, in: RoundedRectangle(cornerRadius: 16))
                                            if let id = message.guideID, let guide = RelaySupportKnowledge.generalGuide(id), !message.outgoing {
                                                NavigationLink { RelaySupportGuideReader(id: id) } label: {
                                                    Label(guide.filename, systemImage: "doc.richtext").font(.caption).padding(10).lumaSurface(radius: 12)
                                                }
                                            }
                                            Text(message.at, style: .time).font(.caption2).foregroundColor(.secondary)
                                        }
                                        if !message.outgoing { Spacer(minLength: 28) }
                                    }.id(message.id)
                                }
                                Color.clear.frame(height: 1).id("support-bottom")
                            }.padding(16)
                        }
                        .onAppear { proxy.scrollTo("support-bottom", anchor: .bottom) }
                        .onChange(of: messages.count) { _ in proxy.scrollTo("support-bottom", anchor: .bottom) }
                    }
                    Text("Limited offline help · Searches approved technical guides").font(.caption2).foregroundColor(.secondary)
                    HStack {
                        TextField("Ask Alex", text: $draft, axis: .vertical).lineLimit(1...3).textFieldStyle(.roundedBorder).submitLabel(.send).onSubmit(send)
                        Button(action: send) { Image(systemName: "arrow.up.circle.fill").font(.title2).frame(width: 44, height: 44) }
                            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityLabel("Send support question")
                    }.padding(.horizontal, 14)
                }
            } else { Text("Relay Support is not installed.").foregroundColor(.secondary) }
        }.navigationTitle("Relay Support").navigationBarTitleDisplayMode(.inline)
            .onAppear { world.beginRelaySupport(installed: installed) }
            .alert("Question not sent", isPresented: $failure) {
                Button("OK", role: .cancel) {}
            } message: { Text("Use up to 2,000 characters and check that Relay Support is installed.") }
    }
}
struct RelaySupportGuideReader: View {
    let id: String
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var installed = ""
    var body: some View {
        ScrollView {
            if RelaySupportAccess.available(installed: installed, flags: world.state.flags),
               let guide = RelaySupportKnowledge.generalGuide(id) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(guide.title).font(.largeTitle.bold())
                    ForEach(Array(guide.sections.enumerated()), id: \.offset) { _, section in
                        Text(section.heading).font(.headline)
                        Text(section.text).textSelection(.enabled)
                    }
                    Text(guide.filename).font(.caption).foregroundColor(.secondary)
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            } else { Text("Guide unavailable").padding() }
        }.navigationTitle("Support guide").navigationBarTitleDisplayMode(.inline)
    }
}
