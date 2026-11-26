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
}
struct RelaySupportHistory: Codable, Equatable {
    var messages: [RelaySupportMessage]
}
struct RelaySupportView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    @State private var tab = "Chat"
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
                        Text("Natural-language reply provider not yet available.").foregroundColor(.secondary)
                    }
                default:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(world.state.relaySupport?.messages ?? []) { message in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(message.text).padding(12).lumaSurface(radius: 16)
                                    Text(message.at, style: .time).font(.caption2).foregroundColor(.secondary)
                                }
                            }
                            Text("Technical guide library is available. Custom chat is not enabled in this development stage.").font(.caption).foregroundColor(.secondary)
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else { Text("Relay Support is not installed.").foregroundColor(.secondary) }
        }.navigationTitle("Relay Support").navigationBarTitleDisplayMode(.inline)
            .onAppear { world.beginRelaySupport(installed: installed) }
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
