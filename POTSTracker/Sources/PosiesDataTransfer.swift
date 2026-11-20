import Foundation
import SwiftUI
import CoreData
import UIKit
import UniformTypeIdentifiers

struct PosiesPortableRecord: Codable, Identifiable, Equatable {
    var id: UUID
    var recordedAt: Date
    var category: String
    var title: String
    var severity: Int16
    var firstValue: Int32
    var secondValue: Int32
    var posture: String
    var notes: String
    var timezoneID: String
    var source: String

    init(_ entry: POTSLogEntry) {
        id = entry.id
        recordedAt = entry.recordedAt
        category = entry.category
        title = entry.title
        severity = entry.severity
        firstValue = entry.firstValue
        secondValue = entry.secondValue
        posture = entry.posture
        notes = entry.notes
        timezoneID = entry.timezoneID
        source = entry.source
    }

    var categoryLabel: String { LogCategory(rawValue: category)?.title ?? category }

    var displayDetail: String {
        switch LogCategory(rawValue: category) {
        case .heartRate: return "\(firstValue) bpm" + (posture.isEmpty ? "" : " · \(posture)")
        case .bloodPressure: return "\(firstValue)/\(secondValue) mmHg"
        case .symptom: return severity >= 0 ? "Severity \(severity)/10" : "No severity rating"
        case .hydration:
            let tags = PosiesEntryExtras.read(source).tags ?? []
            return "\(firstValue) mL" + (secondValue > 0 ? " · \(secondValue) mg sodium" : "") +
                (tags.isEmpty ? "" : " · \(tags.prefix(2).joined(separator: ", "))")
        case .medications:
            let extras = PosiesEntryExtras.read(source)
            return posture + (extras.dose.isEmpty ? "" : " · \(extras.dose)") +
                (extras.tags?.isEmpty == false ? " · \(extras.tags!.prefix(2).joined(separator: ", "))" : "")
        case .sleep:
            let recovery = PosiesEntryExtras.read(source).recovery ?? ""
            return "\(firstValue) minutes" + (posture.isEmpty ? "" : " · \(posture)") +
                (recovery.isEmpty ? "" : " · \(recovery)")
        case .posture:
            let tags = PosiesEntryExtras.read(source).tags ?? []
            return posture + (firstValue > 0 ? " · \(firstValue) bpm" : "") +
                (tags.isEmpty ? "" : " · \(tags.prefix(2).joined(separator: ", "))")
        case .checkIn: return CheckInFormat.feeling(title: title, posture: posture) ?? "Check-in"
        case .journal, .none: return "Journal note"
        }
    }
}

struct PosiesBackupFile: Codable {
    var format: String = "pots-posies-local-backup"
    var schemaVersion: Int = 1
    var createdAt: Date = Date()
    var records: [PosiesPortableRecord]
}

struct PosiesImportPreview {
    let archive: PosiesBackupFile
    let existing: Int
    let additions: Int
    let journalCount: Int
}

enum PosiesDataTransfer {
    enum TransferError: LocalizedError {
        case wrongFile
        case tooMany
        case invalidRecord
        case duplicates
        case locked
        var errorDescription: String? {
            switch self {
            case .wrongFile: return "This isn't a compatible POTS & Posies backup."
            case .tooMany: return "This backup is too large for one safe import. Divide it into smaller archives."
            case .invalidRecord: return "This backup contains an invalid entry. No records were imported."
            case .duplicates: return "This backup has duplicate record IDs. No records were imported."
            case .locked: return "Unlock private Journal access before restoring private records."
            }
        }
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }

    static func encodeBackup(_ records: [PosiesPortableRecord]) throws -> Data {
        try encoder().encode(PosiesBackupFile(records: records))
    }

    static func inspect(_ data: Data, existingIDs: Set<UUID>, journalUnlocked: Bool) throws -> PosiesImportPreview {
        guard data.count <= 65 * 1024 * 1024 else { throw TransferError.tooMany }
        let archive = try decoder().decode(PosiesBackupFile.self, from: data)
        guard archive.format == "pots-posies-local-backup", archive.schemaVersion == 1 else {
            throw TransferError.wrongFile
        }
        guard archive.records.count <= 100000 else { throw TransferError.tooMany }
        let ids = archive.records.map(\.id)
        guard Set(ids).count == ids.count else { throw TransferError.duplicates }
        let supported = Set(LogCategory.allCases.map(\.rawValue))
        for record in archive.records {
            guard supported.contains(record.category),
                  record.severity >= -1 && record.severity <= 10,
                  record.title.count <= 500,
                  record.notes.count <= 30000,
                  record.posture.count <= 200,
                  record.timezoneID.count <= 120,
                  record.source.count <= 16000,
                  record.recordedAt.timeIntervalSince1970 > 0,
                  record.recordedAt < Date().addingTimeInterval(86400) else {
                throw TransferError.invalidRecord
            }
        }
        let journalCount = archive.records.filter { $0.category == LogCategory.journal.rawValue }.count
        if journalCount > 0 && !journalUnlocked { throw TransferError.locked }
        let existing = archive.records.filter { existingIDs.contains($0.id) }.count
        return PosiesImportPreview(archive: archive, existing: existing,
                                   additions: ids.count - existing, journalCount: journalCount)
    }

    /// Import only new UUIDs, without overwriting existing records.
    /// Save once after all validation, and roll back atomically on failure.
    @discardableResult
    static func restore(_ preview: PosiesImportPreview, context: NSManagedObjectContext) throws -> Int {
        let fetch = NSFetchRequest<POTSLogEntry>(entityName: POTSData.entityName)
        let existing = Set(try context.fetch(fetch).map(\.id))
        var added = 0
        for source in preview.archive.records where !existing.contains(source.id) {
            let record = POTSLogEntry(context: context)
            record.id = source.id
            record.recordedAt = source.recordedAt
            record.category = source.category
            record.title = source.title
            record.severity = source.severity
            record.firstValue = source.firstValue
            record.secondValue = source.secondValue
            record.posture = source.posture
            record.notes = source.notes
            record.timezoneID = source.timezoneID
            record.source = source.source
            added += 1
        }
        do {
            try POTSData.save(context)
            return added
        } catch {
            context.rollback()
            throw error
        }
    }

    static func csv(_ records: [PosiesPortableRecord], includeNotes: Bool) -> String {
        let headers = ["id", "recorded_at_iso8601", "timezone", "category", "title", "severity_0_to_10",
                       "first_value", "second_value", "posture_or_status", "extra_fields", "notes"]
        var rows = [headers.joined(separator: ",")]
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for r in records {
            let fields = [r.id.uuidString, iso.string(from: r.recordedAt), r.timezoneID,
                          r.category, r.title, r.severity >= 0 ? String(r.severity) : "",
                          String(r.firstValue), String(r.secondValue), r.posture,
                          includeNotes ? r.source : "metadata withheld",
                          includeNotes ? r.notes : ""]
            rows.append(fields.map(csvField).joined(separator: ","))
        }
        return rows.joined(separator: "\r\n") + "\r\n"
    }

    private static func csvField(_ value: String) -> String {
        // Prevent spreadsheet formula execution when opening a CSV in Excel.
        let sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = sanitized.first.map { "=+-@".contains($0) } ?? false
        let safe = prefix ? "'" + value : value
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// An offline, multi-page doctor-friendly PDF of the actual selected data.
    static func pdf(_ records: [PosiesPortableRecord], includeNotes: Bool) -> Data {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { context in
            var y: CGFloat = 0
            func begin() {
                context.beginPage()
                y = 44
            }
            func line(_ text: String, font: UIFont, color: UIColor = .black) {
                if y > page.height - 75 { begin() }
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byTruncatingTail
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font, .foregroundColor: color, .paragraphStyle: paragraph
                ]
                let maxWidth: CGFloat = 522
                let display = String(text.prefix(1400))
                let rect = (display as NSString).boundingRect(
                    with: CGSize(width: maxWidth, height: 180),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes, context: nil
                )
                let height = min(180, max(font.lineHeight + 4, rect.height + 5))
                if y + height > page.height - 50 { begin() }
                (display as NSString).draw(in: CGRect(x: 45, y: y, width: maxWidth, height: height),
                                           withAttributes: attributes)
                y += height + 5
            }
            begin()
            line("POTS & Posies • Personal Record Summary", font: .boldSystemFont(ofSize: 19))
            line("Created \(Date().formatted(date: .abbreviated, time: .shortened)) • \(records.count) entries",
                 font: .systemFont(ofSize: 11), color: .darkGray)
            line("This is a manually recorded journal, not a medical diagnosis. Unrecorded days are unknown.",
                 font: .systemFont(ofSize: 10))
            let groups = Dictionary(grouping: records, by: \.category)
            for category in LogCategory.allCases {
                let count = groups[category.rawValue]?.count ?? 0
                if count > 0 { line("\(category.title): \(count) entries", font: .systemFont(ofSize: 11)) }
            }
            line("Recorded entries", font: .boldSystemFont(ofSize: 15))
            for record in records.sorted(by: { $0.recordedAt > $1.recordedAt }) {
                let date = record.recordedAt.formatted(date: .abbreviated, time: .shortened)
                line("\(date)  •  \(record.categoryLabel)  •  \(record.title)",
                     font: .boldSystemFont(ofSize: 10.5))
                line(record.displayDetail, font: .systemFont(ofSize: 10.5))
                if includeNotes && !record.notes.isEmpty {
                    line("Note: " + record.notes, font: .systemFont(ofSize: 9.5), color: .darkGray)
                }
            }
        }
    }

    static func writeTemporary(_ data: Data, suffix: String, ext: String) throws -> URL {
        let name = "POTS-and-Posies-\(suffix)-\(UUID().uuidString.prefix(6)).\(ext)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        return url
    }
}

struct PosiesShareSheet: UIViewControllerRepresentable {
    let file: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [file], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
