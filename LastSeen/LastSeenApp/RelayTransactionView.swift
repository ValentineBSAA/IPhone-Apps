import SwiftUI

/// Confirmation and staged, cancellable in-game package transaction.
/// Persistent changes are applied by the parent only after the respring completes.
struct RelayTransactionView: View {
    let changes: [RelayChange]
    let onCancel: () -> Void
    let onComplete: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @State private var tick = 0
    @State private var restarting = false
    private var messages: [String] {
        ["Reading package lists…", "Building dependency tree…", "Checking package state…", "Preparing transaction…"] +
        changes.flatMap { change in [
            "\(change.action.rawValue): \(change.package.title)",
            "Processing \(change.package.id)",
            "Package metadata verified"
        ] } + ["Refreshing package database…", "Processing SpringBoard changes…", "Transaction complete"]
    }
    var body: some View {
        Group {
            if restarting {
                ThemeRespringView(onComplete: onComplete)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        OpeningArt(name: "Opening_Install", size: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tick >= messages.count ? "Complete" : "Processing changes").font(.title2.bold())
                            Text("\(changes.count) packages").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    ProgressView(value: Double(tick), total: Double(messages.count)).tint(.teal)
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 7) {
                                ForEach(Array(messages.prefix(tick).enumerated()), id: \.offset) { entry in
                                    Text(entry.element).font(.system(.footnote, design: .monospaced)).foregroundColor(.teal)
                                }
                                Color.clear.frame(height: 8).id("tail")
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
                        }.background(.black, in: RoundedRectangle(cornerRadius: 12))
                            .onChange(of: tick) { _ in proxy.scrollTo("tail", anchor: .bottom) }
                    }
                    if tick >= messages.count {
                        Button { restarting = true } label: {
                            Label("Restart SpringBoard", systemImage: "arrow.clockwise").frame(maxWidth: .infinity).padding(.vertical, 8)
                        }.buttonStyle(.borderedProminent).tint(.teal)
                    }
                    Button("Cancel", role: .cancel, action: onCancel).frame(maxWidth: .infinity)
                    Text("Changes remain pending until the restart finishes.").font(.caption2).foregroundColor(.secondary)
                }.padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.035, green: 0.06, blue: 0.10).ignoresSafeArea())
                    .task {
                        while tick < messages.count && !Task.isCancelled {
                            do { try await Task.sleep(nanoseconds: 150_000_000) } catch { return }
                            guard scenePhase == .active else { continue }
                            tick += 1
                        }
                    }
            }
        }.preferredColorScheme(.dark).interactiveDismissDisabled()
    }
}
