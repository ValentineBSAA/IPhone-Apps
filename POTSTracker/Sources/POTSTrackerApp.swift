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
    @AppStorage("posiesAppearance") private var posiesAppearance = "system"
    private let persistence = PersistenceController.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("journalLockEnabled") private var journalLockEnabled = false
    @AppStorage("posiesWelcomeAcknowledgedV021") private var welcomeAccepted = false

    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.749, green: 0.667, blue: 0.780, alpha: 1)
                : UIColor.systemGray.resolvedColor(with: traits)
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if welcomeAccepted {
                    DashboardView()
                } else {
                    WelcomeAndPrivacyView(acknowledged: $welcomeAccepted)
                }
                // Protect app-switcher snapshots while a private Journal is enabled.
                if scenePhase != .active && journalLockEnabled && welcomeAccepted {
                    Color.potsBackground.ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.largeTitle)
                                Text("POTS & Posies")
                                    .font(.headline)
                            }
                            .foregroundStyle(Color.potsTeal)
                        )
                        .accessibilityHidden(true)
                }
            }
            .environment(\.managedObjectContext, persistence.container.viewContext)
                .tint(.potsTeal)
                .preferredColorScheme(posiesAppearance == "light" ? .light : (posiesAppearance == "dark" ? .dark : nil))
                .onChange(of: scenePhase) { phase in
                    if phase == .background { JournalAccess.shared.lock() }
                }
        }
    }
}

extension Color {
    // Strawberry Blossom preserved; Midnight Posies has higher-contrast layers.
    static let potsTeal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 1.0, green: 0.710, blue: 0.843, alpha: 1)
        : UIColor(red: 0.59, green: 0.20, blue: 0.36, alpha: 1)
    })
    static let potsInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 1.0, green: 0.961, blue: 0.988, alpha: 1)
        : UIColor(red: 0.24, green: 0.14, blue: 0.21, alpha: 1)
    })
    static let potsBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 0.129, green: 0.102, blue: 0.153, alpha: 1)
        : UIColor(red: 1.00, green: 0.970, blue: 0.980, alpha: 1)
    })
    static let potsSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 0.227, green: 0.169, blue: 0.259, alpha: 1)
        : UIColor(red: 1.00, green: 0.995, blue: 0.996, alpha: 1)
    })
    static let potsSurfaceMuted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 0.314, green: 0.231, blue: 0.349, alpha: 1)
        : UIColor(red: 0.975, green: 0.915, blue: 0.940, alpha: 1)
    })
    static let potsSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 0.847, green: 0.776, blue: 0.855, alpha: 1)
        : UIColor.secondaryLabel.resolvedColor(with: traits)
    })
    static let potsTertiary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 0.749, green: 0.667, blue: 0.780, alpha: 1)
        : UIColor.tertiaryLabel.resolvedColor(with: traits)
    })
    // Link/icon pink and button fill must differ: white labels stay legible.
    static let potsButtonFill = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 0.596, green: 0.239, blue: 0.439, alpha: 1)
        : UIColor(red: 0.59, green: 0.20, blue: 0.36, alpha: 1)
    })
    static let potsStroke = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
        ? UIColor(red: 0.592, green: 0.447, blue: 0.620, alpha: 1)
        : UIColor(red: 0.59, green: 0.20, blue: 0.36, alpha: 0.10)
    })
}

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .padding(16)
            .background(Color.potsSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.potsStroke, lineWidth: 1))
    }
}
