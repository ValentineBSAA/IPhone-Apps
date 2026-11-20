import Foundation
import CoreData
import SwiftUI

/// iCloud Documents needs a provisioning-profile entitlement. An unsigned IPA
/// cannot grant it, and AltStore may sign without it. Never report iCloud
/// success merely because the user is signed into their Apple Account.
/// The app defaults to offering iCloud Drive as the preferred *destination*,
/// but uploading private records is separately and explicitly opted into.
enum PosiesBackupPolicy {
    static let preferenceKey = "posiesBackupDestinationV025"
    static let automaticConsentKey = "posiesAutomaticCloudConsentV025"
    static let lastSuccessfulKey = "posiesCloudLastVerifiedV025"
    static let lastCountKey = "posiesCloudLastCountV025"

    static func lastSuccessful(_ defaults: UserDefaults = .standard) -> Date? {
        defaults.object(forKey: lastSuccessfulKey) as? Date
    }

    static func needsForegroundCheck(now: Date = Date(), last: Date?) -> Bool {
        guard let last else { return true }
        // Save-triggered snapshots are immediate; this is only a lightweight
        // foreground refresh if no backup has succeeded recently.
        return now.timeIntervalSince(last) > 6 * 60 * 60
    }

    static func safeToReplacePreviousBackup(newCount: Int, priorCount: Int) -> Bool {
        // A damaged empty database must not silently overwrite the last backup.
        // Legitimate deliberate deletion of *all* records requires manual backup.
        newCount > 0
    }
}

@MainActor
final class PosiesCloudBackup: ObservableObject {
    static let shared = PosiesCloudBackup()

    @Published private(set) var iCloudAvailable: Bool?
    @Published private(set) var isSaving = false
    @Published private(set) var lastSuccess: Date?
    @Published private(set) var lastRecordCount: Int = 0
    @Published private(set) var statusMessage: String?

    private var container: URL?
    private var queuedRetry = false
    private let defaults: UserDefaults = .standard
    private init() {
        lastSuccess = PosiesBackupPolicy.lastSuccessful()
        lastRecordCount = defaults.integer(forKey: PosiesBackupPolicy.lastCountKey)
    }

    var optedIn: Bool {
        defaults.bool(forKey: PosiesBackupPolicy.automaticConsentKey)
    }

    func checkAvailability() {
        // Discover on background queue: file provider may respond slowly.
        DispatchQueue.global(qos: .utility).async {
            let available = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            DispatchQueue.main.async {
                self.container = available
                self.iCloudAvailable = available != nil
                if available == nil {
                    self.statusMessage = "Automatic iCloud Drive backup isn't available with this installation or iCloud configuration. You can still save a backup to iCloud Drive through Files."
                } else if self.optedIn && PosiesBackupPolicy.needsForegroundCheck(last: self.lastSuccess) {
                    self.makeBackup()
                }
            }
        }
    }

    func setAutomaticConsent(_ agreed: Bool) {
        if !agreed {
            defaults.set(false, forKey: PosiesBackupPolicy.automaticConsentKey)
            statusMessage = "Automatic backup is off. Saved backups aren't deleted."
            return
        }
        guard iCloudAvailable == true, container != nil else {
            defaults.set(false, forKey: PosiesBackupPolicy.automaticConsentKey)
            statusMessage = "iCloud Drive isn't available to this signed app. Save a backup using Files instead."
            return
        }
        defaults.set(true, forKey: PosiesBackupPolicy.automaticConsentKey)
        makeBackup()
    }

    func noteRecordSaved() {
        guard optedIn else { return }
        // Save is called by all manual trackers; use the committed local store.
        makeBackup()
    }

    func makeBackup() {
        guard optedIn else { return }
        guard let container, iCloudAvailable == true else {
            statusMessage = "Automatic cloud backup is unavailable. No upload was attempted."
            return
        }
        guard !isSaving else {
            queuedRetry = true
            return
        }
        guard PersistenceController.shared.loadError == nil else {
            statusMessage = "The journal couldn't be loaded. Your previous backup was not changed."
            return
        }
        isSaving = true
        statusMessage = "Preparing a private backup…"
        let context = PersistenceController.shared.container.viewContext
        context.perform {
            do {
                let request = NSFetchRequest<POTSLogEntry>(entityName: POTSData.entityName)
                let records = try context.fetch(request).filter { !$0.isDeleted }.map(PosiesPortableRecord.init)
                guard PosiesBackupPolicy.safeToReplacePreviousBackup(
                    newCount: records.count, priorCount: self.lastRecordCount
                ) else {
                    DispatchQueue.main.async {
                        self.finishWithError("No saved entries were found. Existing iCloud backups were left unchanged.")
                    }
                    return
                }
                let data = try PosiesDataTransfer.encodeBackup(records)
                DispatchQueue.global(qos: .utility).async {
                    do {
                        try Self.writeAndVerify(data, to: container, count: records.count)
                        DispatchQueue.main.async {
                            let completedAt = Date()
                            self.defaults.set(completedAt, forKey: PosiesBackupPolicy.lastSuccessfulKey)
                            self.defaults.set(records.count, forKey: PosiesBackupPolicy.lastCountKey)
                            self.lastSuccess = completedAt
                            self.lastRecordCount = records.count
                            self.statusMessage = "iCloud Drive backup verified."
                            self.complete()
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.finishWithError("iCloud backup did not complete: \(error.localizedDescription). Your previous backup was not reported as updated.")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async { self.finishWithError("Could not read records for backup: \(error.localizedDescription)") }
            }
        }
    }

    private func complete() {
        isSaving = false
        if queuedRetry {
            queuedRetry = false
            makeBackup()
        }
    }
    private func finishWithError(_ reason: String) {
        statusMessage = reason
        complete()
    }

    private static func writeAndVerify(_ data: Data, to ubiquityContainer: URL, count: Int) throws {
        let fileManager = FileManager.default
        let folder = ubiquityContainer
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("POTS and Posies Backups", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let day = DateFormatter()
        day.locale = Locale(identifier: "en_US_POSIX")
        day.timeZone = .current
        day.dateFormat = "yyyy-MM-dd"
        let target = folder.appendingPathComponent("POTS-and-Posies-\(day.string(from: Date())).json")
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var writeFailure: Error?
        let options: NSFileCoordinator.WritingOptions = fileManager.fileExists(atPath: target.path) ? .forReplacing : []
        coordinator.coordinate(writingItemAt: target, options: options, error: &coordinationError) { coordinatedURL in
            do {
                // Don't expose partially written JSON to another Files reader.
                try data.write(to: coordinatedURL, options: .atomic)
                let verified = try Data(contentsOf: coordinatedURL)
                let inspection = try PosiesDataTransfer.inspect(
                    verified, existingIDs: [], journalUnlocked: true
                )
                guard inspection.archive.records.count == count else {
                    throw CocoaError(.fileReadCorruptFile)
                }
            } catch {
                writeFailure = error
            }
        }
        if let error = coordinationError { throw error }
        if let error = writeFailure { throw error }
        // Keep a small rolling history for recovery from accidental changes.
        let backups = try fileManager.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.lastPathComponent.hasPrefix("POTS-and-Posies-") && $0.pathExtension == "json" }
        let ordered = backups.sorted { lhs, rhs in
            let left = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            let right = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            return left > right
        }
        for obsolete in ordered.dropFirst(7) {
            try? fileManager.removeItem(at: obsolete)
        }
    }
}
