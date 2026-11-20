import SwiftUI
import CoreData
import UniformTypeIdentifiers

enum PosiesDateRange: String, CaseIterable, Identifiable {
    case seven = "7 days"
    case thirty = "30 days"
    case ninety = "90 days"
    case year = "365 days"
    case all = "All time"
    var id: String { rawValue }

    func includes(_ date: Date, reference: Date = Date(), calendar: Calendar = .current) -> Bool {
        if self == .all { return date <= reference }
        let count: Int
        switch self {
        case .seven: count = 7
        case .thirty: count = 30
        case .ninety: count = 90
        case .year: count = 365
        case .all: return true
        }
        let dayStart = calendar.startOfDay(for: reference)
        let start = calendar.date(byAdding: .day, value: -(count - 1), to: dayStart) ?? dayStart
        return date >= start && date <= reference
    }
}

private struct PosiesExportRoute: Identifiable {
    let file: URL
    var id: String { file.path }
}

struct PosiesDataManagementView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "recordedAt", ascending: false)])
    private var entries: FetchedResults<POTSLogEntry>
    @AppStorage("journalLockEnabled") private var journalLockEnabled = false
    @ObservedObject private var journalAccess = JournalAccess.shared
    @State private var dateRange: PosiesDateRange = .thirty
    @State private var chosen = Set(LogCategory.allCases.map(\.rawValue))
    @State private var includeNotes = false
    @State private var exportFile: PosiesExportRoute?
    @State private var showImporter = false
    @State private var showRestoreConfirmation = false
    @State private var preview: PosiesImportPreview?
    @State private var exportAction: String?
    @State private var confirmExport = false
    @State private var errorText: String?
    @State private var outcomeText: String?
    @AppStorage("posiesBackupDestinationV025") private var preferredDestination = "icloud"
    @AppStorage("posiesAutomaticCloudConsentV025") private var automaticCloudBackup = false
    @ObservedObject private var cloud = PosiesCloudBackup.shared
    @State private var showCloudConsent = false
    @State private var advancedOpen = false

    private var canSeeJournal: Bool { !journalLockEnabled || journalAccess.unlocked }
    private var visible: [PosiesPortableRecord] {
        Array(entries).filter { !$0.isDeleted &&
            (canSeeJournal || $0.category != LogCategory.journal.rawValue) }
            .map(PosiesPortableRecord.init)
    }
    private var selected: [PosiesPortableRecord] {
        visible.filter { chosen.contains($0.category) && dateRange.includes($0.recordedAt) }
    }
    private var exportRestricted: Bool {
        journalLockEnabled && !canSeeJournal && chosen.contains(LogCategory.journal.rawValue)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Keep your memories safe", systemImage: "heart.text.square.fill")
                            .font(.title3.bold()).foregroundStyle(Color.potsTeal)
                        Text("Your entries live on this iPhone. You can save another copy to Files, including iCloud Drive, without needing to understand file formats.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        Text("Preferred backup location: iCloud Drive")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.potsTeal)
                        Text("No backup is sent to the cloud without your choice.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Automatic backup", systemImage: "icloud")
                            .font(.headline)
                        Text(cloud.iCloudAvailable == true
                             ? "This installation can access app-managed iCloud Drive backups."
                             : (cloud.iCloudAvailable == nil
                                ? "Checking iCloud Drive support…"
                                : "Automatic iCloud Drive backup isn't available with this signing profile or iCloud setup. You can still save a copy through Files."))
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)

                        Toggle("Automatically back up to iCloud Drive", isOn: Binding(
                            get: { automaticCloudBackup },
                            set: { enabled in
                                if enabled {
                                    showCloudConsent = true
                                } else {
                                    automaticCloudBackup = false
                                    cloud.setAutomaticConsent(false)
                                }
                            }
                        ))
                        .tint(.potsTeal)
                        .disabled(cloud.iCloudAvailable != true)
                        if cloud.isSaving {
                            ProgressView("Backing up…")
                                .font(.subheadline)
                        }
                        if let completed = cloud.lastSuccess {
                            Label("Last verified backup: \(completed.formatted(date: .abbreviated, time: .shortened))",
                                  systemImage: "checkmark.shield.fill")
                                .font(.caption).foregroundStyle(Color.potsTeal)
                        } else {
                            Text("No automatic iCloud backup has been verified.")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                        if let status = cloud.statusMessage {
                            Text(status).font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                        if automaticCloudBackup && cloud.iCloudAvailable == true {
                            Button("Back up now") { cloud.makeBackup() }
                                .buttonStyle(.bordered)
                                .disabled(cloud.isSaving)
                        }
                        Text("Cloud copies contain private journal information and aren't protected by a separate app password. Automatic backup is optional and needs a compatible Apple provisioning profile.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Save or restore a copy").font(.headline)
                        Text("For iCloud Drive: choose Save to Files, then iCloud Drive in the share sheet. This works without the app-managed iCloud entitlement.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        Button {
                            exportAction = "backup"
                            confirmExport = true
                        } label: {
                            Label("Save my backup", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.potsButtonFill)
                        .disabled(!canSeeJournal || entries.isEmpty)
                        Button { showImporter = true } label: {
                            Label("Restore from a backup", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        Text("Before restoring, you'll see which entries are new. Your current records aren't overwritten. Saving a file isn't verified until you confirm it exists in Files.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }

                if journalLockEnabled && !canSeeJournal {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Private Journal is locked", systemImage: "lock.shield")
                                .font(.headline)
                            Text("Unlock to create a complete backup or include private Journal entries in a report.")
                                .font(.subheadline).foregroundStyle(Color.potsSecondary)
                            Button("Unlock private records") {
                                journalAccess.authenticate(reason: "Export or restore private Journal records") {
                                    success, error in
                                    if !success { errorText = error ?? "Journal is still locked." }
                                }
                            }
                            .buttonStyle(.borderedProminent).tint(Color.potsButtonFill)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { advancedOpen.toggle() }
                        } label: {
                            HStack {
                                Label("Advanced exports", systemImage: "doc.text.magnifyingglass")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: advancedOpen ? "chevron.up" : "chevron.down")
                            }
                            .frame(minHeight: 48)
                        }
                        .buttonStyle(.plain)
                        Text("PDF reports for appointments and CSV/JSON for people who need raw files.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }
                if advancedOpen {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export a report").font(.headline)
                        Picker("Time period", selection: $dateRange) {
                            ForEach(PosiesDateRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.menu)

                        Text("What to include").font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                            ForEach(LogCategory.allCases) { category in
                                Toggle(category.title, isOn: Binding(
                                    get: { chosen.contains(category.rawValue) },
                                    set: { active in
                                        if active { chosen.insert(category.rawValue) }
                                        else { chosen.remove(category.rawValue) }
                                    }
                                ))
                                .font(.caption)
                                .tint(.potsTeal)
                            }
                        }
                        Toggle("Include freeform notes in reports", isOn: $includeNotes)
                            .tint(.potsTeal)
                        Text("\(selected.count) selected entries")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.potsTeal)
                        if exportRestricted {
                            Text("Uncheck Journal for a partial report, or unlock it above to include private entries.")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                        HStack {
                            Button {
                                exportAction = "csv"
                                confirmExport = true
                            } label: {
                                Label("CSV", systemImage: "tablecells")
                                    .frame(maxWidth: .infinity, minHeight: 47)
                            }
                            Button {
                                exportAction = "pdf"
                                confirmExport = true
                            } label: {
                                Label("PDF", systemImage: "doc.richtext")
                                    .frame(maxWidth: .infinity, minHeight: 47)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.potsButtonFill)
                        .disabled(selected.isEmpty || exportRestricted)
                    }
                }


                    GlassCard {
                        Button {
                            exportAction = "backup"
                            confirmExport = true
                        } label: {
                            Label("Export JSON (advanced)", systemImage: "doc.text")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!canSeeJournal || entries.isEmpty)
                    }
                }

            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Data & backups")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            preferredDestination = "icloud"
            cloud.checkAvailability()
        }
        .alert("Allow automatic iCloud backups?", isPresented: $showCloudConsent) {
            Button("Enable backups") {
                cloud.setAutomaticConsent(true)
                automaticCloudBackup = cloud.optedIn
            }
            Button("Not now", role: .cancel) { automaticCloudBackup = false }
        } message: {
            Text("The app will copy all your saved entries, including private Journal notes, into your own iCloud Drive when available. Backups have no separate password. You can turn this off anytime.")
        }
        .sheet(item: $exportFile) { output in
            PosiesShareSheet(file: output.file)
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let file):
                let scoped = file.startAccessingSecurityScopedResource()
                defer { if scoped { file.stopAccessingSecurityScopedResource() } }
                do {
                    let data = try Data(contentsOf: file)
                    let request = NSFetchRequest<POTSLogEntry>(entityName: POTSData.entityName)
                    let ids = Set(try context.fetch(request).map(\.id))
                    let p = try PosiesDataTransfer.inspect(
                        data, existingIDs: ids, journalUnlocked: canSeeJournal
                    )
                    preview = p
                    showRestoreConfirmation = true
                } catch {
                    errorText = error.localizedDescription
                }
            case .failure(let error):
                errorText = error.localizedDescription
            }
        }
        .confirmationDialog("Share private health records?", isPresented: $confirmExport,
                            titleVisibility: .visible) {
            Button("Generate and share \(exportAction?.uppercased() ?? "file")") {
                generateExport()
            }
            Button("Cancel", role: .cancel) { exportAction = nil }
        } message: {
            Text("The file may contain private health notes. Choose a trusted destination in the system share sheet, such as Save to Files > iCloud Drive.")
        }
        .alert("Preview backup", isPresented: $showRestoreConfirmation) {
            Button("Import \(preview?.additions ?? 0) new entries") {
                guard let preview else { return }
                do {
                    let count = try PosiesDataTransfer.restore(preview, context: context)
                    outcomeText = "\(count) new entries imported. Existing entries were unchanged."
                    self.preview = nil
                } catch {
                    errorText = error.localizedDescription
                }
            }
            .disabled((preview?.additions ?? 0) == 0)
            Button("Cancel", role: .cancel) { preview = nil }
        } message: {
            Text("\(preview?.archive.records.count ?? 0) entries in file. \(preview?.existing ?? 0) already exist; \(preview?.additions ?? 0) are new. This never erases or overwrites records.")
        }
        .alert("Data transfer", isPresented: Binding(
            get: { errorText != nil || outcomeText != nil },
            set: { if !$0 { errorText = nil; outcomeText = nil } }
        )) {
            Button("OK") { errorText = nil; outcomeText = nil }
        } message: {
            Text(errorText ?? outcomeText ?? "")
        }
    }

    private func generateExport() {
        do {
            let action = exportAction ?? ""
            let file: URL
            switch action {
            case "csv":
                file = try PosiesDataTransfer.writeTemporary(
                    Data(PosiesDataTransfer.csv(selected, includeNotes: includeNotes).utf8),
                    suffix: "report", ext: "csv")
            case "pdf":
                file = try PosiesDataTransfer.writeTemporary(
                    PosiesDataTransfer.pdf(selected, includeNotes: includeNotes),
                    suffix: "report", ext: "pdf")
            case "backup":
                guard canSeeJournal else { throw PosiesDataTransfer.TransferError.locked }
                file = try PosiesDataTransfer.writeTemporary(
                    PosiesDataTransfer.encodeBackup(visible),
                    suffix: "full-backup", ext: "json")
            default:
                return
            }
            exportFile = PosiesExportRoute(file: file)
        } catch {
            errorText = error.localizedDescription
        }
        exportAction = nil
    }
}
