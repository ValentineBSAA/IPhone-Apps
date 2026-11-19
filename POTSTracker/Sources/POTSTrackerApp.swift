import SwiftUI
import CoreData

@objc(POTSLogEntry)
final class POTSLogEntry: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var recordedAt: Date
    @NSManaged var category: String
    @NSManaged var title: String
    @NSManaged var severity: Int16
    @NSManaged var firstValue: Int32
    @NSManaged var secondValue: Int32
    @NSManaged var posture: String
    @NSManaged var notes: String
    @NSManaged var timezoneID: String
    @NSManaged var source: String
}

enum POTSData {
    static let entityName = "POTSLogEntry"

    private static func attribute(_ name: String, type: NSAttributeType, defaultValue: Any? = nil) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = false
        attribute.defaultValue = defaultValue
        return attribute
    }

    static func model() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(POTSLogEntry.self)
        entity.properties = [
            attribute("id", type: .UUIDAttributeType),
            attribute("recordedAt", type: .dateAttributeType),
            attribute("category", type: .stringAttributeType, defaultValue: ""),
            attribute("title", type: .stringAttributeType, defaultValue: ""),
            attribute("severity", type: .integer16AttributeType, defaultValue: -1),
            attribute("firstValue", type: .integer32AttributeType, defaultValue: 0),
            attribute("secondValue", type: .integer32AttributeType, defaultValue: 0),
            attribute("posture", type: .stringAttributeType, defaultValue: ""),
            attribute("notes", type: .stringAttributeType, defaultValue: ""),
            attribute("timezoneID", type: .stringAttributeType, defaultValue: ""),
            attribute("source", type: .stringAttributeType, defaultValue: "manual")
        ]
        entity.uniquenessConstraints = [["id"]]
        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }

    static func save(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    private(set) var loadError: String?

    private init() {
        container = NSPersistentContainer(name: "POTSData", managedObjectModel: POTSData.model())
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        do {
            try FileManager.default.createDirectory(
                at: support, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
        } catch {
            loadError = "Unable to prepare private storage: \(error.localizedDescription)"
        }
        let description = NSPersistentStoreDescription(url: support.appendingPathComponent("POTSData.sqlite"))
        description.type = NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(
            FileProtectionType.completeUntilFirstUserAuthentication.rawValue as NSString,
            forKey: NSPersistentStoreFileProtectionKey
        )
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { [weak self] _, error in
            if let error {
                self?.loadError = "Unable to open private health journal: \(error.localizedDescription)"
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

enum LogCategory: String, CaseIterable, Identifiable {
    case symptom
    case heartRate
    case bloodPressure
    case journal
    case checkIn

    var id: String { rawValue }
    var title: String {
        switch self {
        case .symptom: return "Symptoms"
        case .heartRate: return "Heart Rate"
        case .bloodPressure: return "Blood Pressure"
        case .journal: return "Journal"
        case .checkIn: return "Daily Check-In"
        }
    }
    var symbol: String {
        switch self {
        case .symptom: return "list.clipboard.fill"
        case .heartRate: return "heart.fill"
        case .bloodPressure: return "waveform.path.ecg"
        case .journal: return "book.closed.fill"
        case .checkIn: return "heart.text.square.fill"
        }
    }
}

enum EntryFormat {
    static func description(for entry: POTSLogEntry) -> String {
        switch entry.category {
        case LogCategory.heartRate.rawValue:
            return "\(entry.firstValue) bpm" + (entry.posture.isEmpty ? "" : " • \(entry.posture)")
        case LogCategory.bloodPressure.rawValue:
            return "\(entry.firstValue)/\(entry.secondValue) mmHg" + (entry.posture.isEmpty ? "" : " • \(entry.posture)")
        case LogCategory.symptom.rawValue:
            return entry.severity < 0 ? "Symptom logged" : "Severity \(entry.severity)/10"
        case LogCategory.checkIn.rawValue:
            return "How I felt"
        default:
            return entry.notes.isEmpty ? "Journal entry" : entry.notes
        }
    }
}

enum DateTracking {
    static func lastSevenDays(reference: Date = Date(), calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: reference)
        return (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: start) }
    }

    static func count(on day: Date, among entries: [POTSLogEntry], calendar: Calendar = .current) -> Int {
        entries.filter { calendar.isDate($0.recordedAt, inSameDayAs: day) }.count
    }
}

@main
struct POTSTrackerApp: App {
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .tint(.potsTeal)
        }
    }
}

extension Color {
    static let potsTeal = Color(red: 0.07, green: 0.52, blue: 0.57)
    static let potsInk = Color(red: 0.08, green: 0.19, blue: 0.28)
    static let potsBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 0.06, green: 0.10, blue: 0.15, alpha: 1)
        : UIColor(red: 0.95, green: 0.98, blue: 0.99, alpha: 1)
    })
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.potsTeal.opacity(0.10), lineWidth: 1))
    }
}
