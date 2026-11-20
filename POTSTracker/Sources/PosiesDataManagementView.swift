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
                                : "Automatic iCloud backup isn't available here. You can still save a copy using Files, including iCloud Drive if it's available."))
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
                        .disabled(cloud.iCloudAvailable != true || (journalLockEnabled && !canSeeJournal))
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
                        Text("Automatic backups can include sensitive health details and private Journal notes. Keep them in your private iCloud account. They don't have an extra app password.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Save or restore a copy").font(.headline)
                        Text("Want to keep a copy in iCloud? Choose Save to Files, then iCloud Drive if it's available.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        Button {
                            prepareManualBackup()
                        } label: {
                            Label("Save my backup", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.potsButtonFill)
                        .accessibilityHint("Opens a backup, explains when no entries exist, or requests Face ID to include private Journal notes.")
                        VStack(alignment: .leading, spacing: 5) {
                            Label("A little privacy reminder", systemImage: "lock.shield")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.potsTeal)
                            Text("Your backup may include sensitive health details and private Journal notes. Keep it somewhere only you can access, and please don't share it publicly. The file doesn't have an extra password.")
                                .font(.subheadline)
                                .foregroundStyle(Color.potsSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 14))
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
                        Button { prepareManualBackup() } label: {
                            Label("Export JSON (advanced)", systemImage: "doc.text")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
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
        .confirmationDialog("A little privacy reminder", isPresented: $confirmExport,
                            titleVisibility: .visible) {
            Button(exportAction == "backup" ? "Continue to save backup" : "Continue to export") {
                generateExport()
            }
            Button("Not now", role: .cancel) { exportAction = nil }
        } message: {
            Text("This file can contain sensitive health information and private Journal notes. Keep it in a private place, such as your personal Files or iCloud Drive, and don't share it publicly. Anyone with the file may be able to read it, since it has no extra password.")
        }
        .sheet(isPresented: $showRestoreConfirmation, onDismiss: { preview = nil }) {
            if let preview {
                PosiesRestorePreviewSheet(
                    existingCount: preview.existing,
                    newCount: preview.additions,
                    onRestore: { restorePreview(preview) },
                    onDone: {
                        self.preview = nil
                        showRestoreConfirmation = false
                    }
                )
            }
        }
        .alert(errorText == nil ? "All set!" : "We couldn't finish that", isPresented: Binding(
            get: { errorText != nil || outcomeText != nil },
            set: { if !$0 { errorText = nil; outcomeText = nil } }
        )) {
            Button("OK") { errorText = nil; outcomeText = nil }
        } message: {
            Text(errorText ?? outcomeText ?? "")
        }
    }

    private func restorePreview(_ approved: PosiesImportPreview) {
        guard approved.additions > 0 else {
            showRestoreConfirmation = false
            preview = nil
            return
        }
        do {
            let count = try PosiesDataTransfer.restore(approved, context: context)
            showRestoreConfirmation = false
            preview = nil
            outcomeText = count == 1
                ? "Your entry is back on this iPhone. Your existing notes were left as they were."
                : "Your \(count) entries are back on this iPhone. Your existing notes were left as they were."
        } catch {
            showRestoreConfirmation = false
            preview = nil
            errorText = "We couldn't finish restoring this backup. Your existing entries have not been replaced. \(error.localizedDescription)"
        }
    }

    private func prepareManualBackup() {
        guard PersistenceController.shared.loadError == nil else {
            errorText = "Your saved records couldn't be opened. The app won't export an incomplete backup."
            return
        }
        switch PosiesManualBackupAccess.evaluate(
            recordCount: entries.count, lockEnabled: journalLockEnabled,
            unlocked: journalAccess.unlocked
        ) {
        case .noEntries:
            errorText = "Nothing has been recorded yet. Save a first entry, then return here to create a backup. You don't need to connect iCloud."
        case .ready:
            exportAction = "backup"
            confirmExport = true
        case .needsUnlock:
            journalAccess.authenticate(reason: "Include private Journal entries in your backup") { success, error in
                if success {
                    exportAction = "backup"
                    confirmExport = true
                } else {
                    errorText = error ?? "Journal stayed locked. No backup was created."
                }
            }
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


/// The preview words and primary action are the same in both themes,
/// and do not mistake matching record IDs for verified byte-for-byte matches.
enum PosiesRestoreCopy {
    static func heading(newCount: Int) -> String {
        newCount == 0 ? "You're all caught up!" : "Let's bring your notes back"
    }

    static func detail(existingCount: Int, newCount: Int) -> String {
        if newCount == 0 {
            return "All \(existingCount) \(existingCount == 1 ? "entry in this backup is" : "entries in this backup are") already on your iPhone. Nothing new needs to be added."
        }
        return "\(newCount) new \(newCount == 1 ? "entry is" : "entries are") ready to restore. \(existingCount) \(existingCount == 1 ? "entry is" : "entries are") already here and won't be duplicated."
    }

    static func button(newCount: Int) -> String {
        newCount == 0 ? "All done" : "Restore \(newCount) \(newCount == 1 ? "entry" : "entries")"
    }
}

/// Calm, readable backup preview. It never offers an inert "Restore 0" action.
private struct PosiesRestorePreviewSheet: View {
    let existingCount: Int
    let newCount: Int
    let onRestore: () -> Void
    let onDone: () -> Void

    private var allHere: Bool { newCount == 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Spacer()
                    Image(systemName: allHere ? "heart.circle.fill" : "arrow.down.heart.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.potsTeal)
                        .accessibilityHidden(true)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(PosiesRestoreCopy.heading(newCount: newCount))
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text(PosiesRestoreCopy.detail(existingCount: existingCount, newCount: newCount))
                        .font(.body)
                        .foregroundStyle(Color.potsSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(alignment: .leading, spacing: 7) {
                    Label("Keep your backup just for you", systemImage: "lock.shield")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.potsTeal)
                    Text("It may contain private Journal notes and sensitive health details. Store the file somewhere secure and avoid sharing it publicly. It doesn't have an extra password.")
                        .font(.subheadline)
                        .foregroundStyle(Color.potsSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.potsSurfaceMuted, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    if allHere { onDone() } else { onRestore() }
                } label: {
                    Text(PosiesRestoreCopy.button(newCount: newCount))
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.potsButtonFill)
                if !allHere {
                    Button("Not now", action: onDone)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.potsTeal)
                }
            }
            .padding(24)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityElement(children: .contain)
    }
}
