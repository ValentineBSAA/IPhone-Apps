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
                    VStack(alignment: .leading, spacing: 9) {
                        Label("Your records, your choice", systemImage: "externaldrive.fill")
                            .font(.title3.bold()).foregroundStyle(Color.potsTeal)
                        Text("Exports are generated offline. Nothing is uploaded automatically. Always review where you share a report or backup.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report range").font(.headline)
                        Picker("Time period", selection: $dateRange) {
                            ForEach(PosiesDateRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.menu)

                        Text("Include these trackers").font(.headline)
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Full backup & restore").font(.headline)
                        Text("A JSON backup includes every saved entry, timestamps, units, notes and private Journal items. It is not encrypted with a separate password.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        Button {
                            exportAction = "backup"
                            confirmExport = true
                        } label: {
                            Label("Create complete JSON backup", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.potsButtonFill)
                        .disabled(!canSeeJournal || entries.isEmpty)
                        Button {
                            showImporter = true
                        } label: {
                            Label("Preview and import backup", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity, minHeight: 46)
                        }
                        .buttonStyle(.bordered)
                        Text("Restore previews new records first, skips existing UUIDs, and never overwrites your current entries. Test with sample data before relying on backup files.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Data & backups")
        .navigationBarTitleDisplayMode(.inline)
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
            Text("The destination you choose can receive sensitive information. Files are created only on your iPhone until you explicitly share them.")
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
