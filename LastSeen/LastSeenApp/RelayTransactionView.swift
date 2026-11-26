import SwiftUI
import UIKit
import Combine

/// Confirmation and staged, cancellable in-game package transaction.
/// Persistent changes are applied by the parent only after the respring completes.
struct RelayTransactionView: View {
    let changes: [RelayChange]
    var canRestart: () -> Bool = {true}
    let onCancel: () -> Void
    let onComplete: () -> Void
    // Common-mode timer survives scrolling and foreground transitions.
    private let clock = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    @State private var tick = 0
    @State private var restarting = false
    @State private var completed = false
    @State private var validationNotice=""
    private var messages: [String] {
        ["Reading package lists…", "Building dependency tree…", "Checking package state…", "Preparing transaction…"] +
        changes.flatMap { change in [
            "\(change.action.rawValue): \(change.package.title)",
            "Processing \(change.package.id)",
            "Package metadata verified"
        ] } + ["Refreshing package database…", "Preparing LumaShell changes…", "Ready for restart; changes pending"]
    }
    var body: some View {
        Group {
            if restarting {
                ThemeRespringView {
                    guard !completed else { return }
                    completed = true
                    onComplete()
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        OpeningArt(name: "Opening_Install", size: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tick >= messages.count ? "Ready to restart" : "Processing changes").font(.title2.bold())
                            Text("\(changes.count) " + (changes.count == 1 ? "package" : "packages")).font(.caption).foregroundColor(.secondary)
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
                        Button {
                            guard UIApplication.shared.applicationState == .active,canRestart() else {
                                validationNotice="Package state changed. Cancel and review the queue."
                                return
                            }
                            validationNotice="";restarting=true
                        } label: {
                            Label("Restart LumaShell", systemImage: "arrow.clockwise").frame(maxWidth: .infinity).padding(.vertical, 8)
                        }.buttonStyle(.borderedProminent).tint(.teal).accessibilityIdentifier("relay.transaction.restart")
                    } else {
                        // Presentation only. Validation and commit still occur in the parent after respring.
                        Button("Skip processing animation") { tick = messages.count }
                            .font(.caption).frame(maxWidth: .infinity).accessibilityIdentifier("relay.transaction.skip")
                    }
                    if !validationNotice.isEmpty {Text(validationNotice).font(.caption).foregroundColor(.orange)}
                    Button("Cancel", role: .cancel, action: onCancel).frame(maxWidth: .infinity).accessibilityIdentifier("relay.transaction.cancel")
                    Text("Changes remain pending until the restart finishes.").font(.caption2).foregroundColor(.secondary)
                }.padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.035, green: 0.06, blue: 0.10).ignoresSafeArea())
                    .onReceive(clock) { _ in
                        guard UIApplication.shared.applicationState == .active,
                              tick < messages.count, !restarting else { return }
                        tick += 1
                    }
            }
        }.preferredColorScheme(.dark).interactiveDismissDisabled()
    }
}
