import SwiftUI
import UIKit

/// Bounded, local QA telemetry. Only known game event labels and timing, never text input,
/// passcodes, biometric data, device identifiers, images or real personal records.
enum OpeningQA {
    static let key = "lastseen.qa.opening.events.v1"
    static let limit = 180

    static func record(_ event: String) {
        let defaults = UserDefaults.standard
        var lines = defaults.stringArray(forKey: key) ?? []
        let stamp = ISO8601DateFormatter().string(from: Date())
        lines.append(stamp + " | " + event)
        defaults.set(Array(lines.suffix(limit)), forKey: key)
    }

    static func report() -> String {
        let d = UserDefaults.standard
        let events = d.stringArray(forKey: key) ?? []
        let bundle = Bundle.main
        return [
            "LAST SEEN — Opening QA",
            "Version: \(bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(bundle.infoDictionary?["CFBundleVersion"] as? String ?? "?"))",
            "iOS: \(UIDevice.current.systemVersion)",
            "Recovery stage: \(d.integer(forKey: "lastseen.recovery.stage"))",
            "Stage elapsed: \(d.integer(forKey: "lastseen.recovery.progress")) seconds",
            "Virtual connection selected: \(d.bool(forKey: "lastseen.recovery.simulated"))",
            "Permission review complete: \(d.bool(forKey: "lastseen.permissions.reviewed.v1"))",
            "Biometric preparation: \(d.bool(forKey: "lastseen.permissions.biometricPrepared"))",
            "Native alerts preference: \(d.bool(forKey: "lastseen.lab.nativeAlerts"))",
            "Setup stage: \(d.integer(forKey: "lastseen.setup.stage"))",
            "Events: \(events.count) (last \(limit) maximum)",
            "Automatic events are observations, not human visual or hardware QA passes.",
            "No passcodes, entered text, biometric data, device identifiers or personal records.",
            "", "SESSION EVENTS", events.joined(separator: "\n")
        ].joined(separator: "\n")
    }

    static func export() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Last-Seen-Opening-QA-\(UUID().uuidString).txt")
        try report().write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

struct OpeningDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var report = ""
    @State private var file: URL?
    @State private var error = false
    @State private var confirmClear = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Local development report. Nothing is sent automatically. Share the report only when you choose. Visual quality, sound and haptics still need your own confirmation.").font(.footnote).foregroundColor(.secondary)
                    Button("Refresh report") { refresh() }
                    if let file {
                        ShareLink(item: file) { Label("Export QA report (.txt)", systemImage: "square.and.arrow.up") }
                    }
                    Button("Copy report") { UIPasteboard.general.string = report }
                    Button("Clear diagnostic history", role: .destructive) { confirmClear = true }
                }
                Section("Report") {
                    Text(report).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                }
            }.navigationTitle("Developer Diagnostics")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
                .onAppear { refresh() }
                .alert("Unable to create report", isPresented: $error) { Button("OK", role: .cancel) {} }
                .confirmationDialog("Clear local QA events?", isPresented: $confirmClear) {
                    Button("Clear", role: .destructive) { UserDefaults.standard.removeObject(forKey: OpeningQA.key); refresh() }
                }
        }.preferredColorScheme(.dark)
    }
    private func refresh() {
        report = OpeningQA.report()
        do { file = try OpeningQA.export() } catch { file = nil; self.error = true }
    }
}
