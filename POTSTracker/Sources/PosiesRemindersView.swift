import SwiftUI
import UserNotifications

struct PosiesReminder: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var category: String
    var hour: Int
    var minute: Int
    var weekdays: [Int]
    var enabled: Bool

    static func withinQuietHours(hour: Int, start: Int, end: Int) -> Bool {
        if start == end { return false }
        if start < end { return hour >= start && hour < end }
        return hour >= start || hour < end
    }

    var displayTime: Date {
        Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: hour, minute: minute)) ?? Date()
    }
    static let supportedCategories = ["Check-in", "Hydration", "Medication", "Rest", "Personal"]
}

enum PosiesNotificationScheduler {
    private static let prefix = "posies-local-"

    static func refresh(_ rules: [PosiesReminder],
                        quietStart: Int,
                        quietEnd: Int,
                        completion: @escaping (String?) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            center.removePendingNotificationRequests(
                withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
            )
            center.getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized ||
                      settings.authorizationStatus == .provisional else {
                    DispatchQueue.main.async { completion("Notifications are off. Manual tracking still works.") }
                    return
                }
                for rule in rules where rule.enabled &&
                        !PosiesReminder.withinQuietHours(hour: rule.hour, start: quietStart, end: quietEnd) {
                    for day in rule.weekdays {
                        guard (1...7).contains(day) else { continue }
                        let content = UNMutableNotificationContent()
                        // Deliberately neutral, including medication reminders.
                        content.title = "POTS & Posies"
                        content.body = "A gentle reminder is ready whenever you are."
                        content.sound = .default
                        let components = DateComponents(hour: rule.hour, minute: rule.minute, weekday: day)
                        let request = UNNotificationRequest(
                            identifier: prefix + rule.id.uuidString + "-\(day)",
                            content: content,
                            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                        )
                        center.add(request)
                    }
                }
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    static func askPermission(_ completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { allowed, _ in
            DispatchQueue.main.async { completion(allowed) }
        }
    }
}

struct PosiesRemindersView: View {
    @AppStorage("posiesReminderRulesV1") private var storedRules = ""
    @AppStorage("posiesQuietStartHour") private var quietStartHour = 22
    @AppStorage("posiesQuietEndHour") private var quietEndHour = 8
    @State private var editing: ReminderEditRoute?
    @State private var permissionStatus = ""
    @State private var statusMessage: String?

    private var rules: [PosiesReminder] {
        guard let data = storedRules.data(using: .utf8),
              let list = try? JSONDecoder().decode([PosiesReminder].self, from: data) else { return [] }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 11) {
                        Label("Gentle reminders", systemImage: "bell.badge.fill")
                            .font(.title3.bold()).foregroundStyle(Color.potsTeal)
                        Text("Choose your own schedule. Reminders never mean a medicine was taken or a check-in was completed.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                        if !permissionStatus.isEmpty {
                            Text(permissionStatus)
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                        Button {
                            editing = ReminderEditRoute(rule: PosiesReminder(
                                name: "", category: "Check-in", hour: 9, minute: 0,
                                weekdays: [1,2,3,4,5,6,7], enabled: true
                            ))
                        } label: {
                            Label("New reminder", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.borderedProminent).tint(Color.potsButtonFill)
                        .disabled(rules.count >= 8)
                        if rules.count >= 8 {
                            Text("Eight schedules are supported to keep iOS notification limits predictable.")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quiet hours").font(.headline)
                        Text("Reminders scheduled during these hours won't be queued.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                        HStack {
                            Picker("From", selection: $quietStartHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(hourLabel(hour)).tag(hour)
                                }
                            }
                            Picker("Until", selection: $quietEndHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(hourLabel(hour)).tag(hour)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        if quietStartHour == quietEndHour {
                            Text("Quiet hours off")
                                .font(.caption).foregroundStyle(Color.potsSecondary)
                        }
                    }
                }

                if rules.isEmpty {
                    GlassCard {
                        Text("No reminders scheduled.")
                            .font(.subheadline).foregroundStyle(Color.potsSecondary)
                    }
                } else {
                    ForEach(rules) { rule in
                        GlassCard {
                            HStack(spacing: 11) {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(Color.potsTeal)
                                    .frame(width: 34)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(rule.name).font(.subheadline.weight(.semibold))
                                    Text("\(rule.category) · \(rule.displayTime.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption).foregroundStyle(Color.potsSecondary)
                                    Text(PosiesReminder.withinQuietHours(
                                        hour: rule.hour, start: quietStartHour, end: quietEndHour
                                    ) ? "Within quiet hours" : "\(rule.weekdays.count) days each week")
                                    .font(.caption2).foregroundStyle(Color.potsSecondary)
                                }
                                Spacer()
                                Toggle(rule.name, isOn: Binding(
                                    get: { rule.enabled },
                                    set: { value in changeEnabled(rule.id, enabled: value) }
                                ))
                                .labelsHidden().tint(.potsTeal)
                            }
                            HStack {
                                Button("Edit") { editing = ReminderEditRoute(rule: rule) }
                                Spacer()
                                Button("Remove", role: .destructive) {
                                    store(rules.filter { $0.id != rule.id })
                                }
                            }
                            .font(.subheadline.weight(.medium))
                        }
                    }
                }

                Text("These are device-local notifications. The iPhone may delay or suppress them. Permission is requested only when you enable a reminder; declining never prevents manual entries.")
                    .font(.caption).foregroundStyle(Color.potsSecondary)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshStatus() }
        .onChange(of: quietStartHour) { _ in sync() }
        .onChange(of: quietEndHour) { _ in sync() }
        .sheet(item: $editing) { route in
            ReminderForm(rule: route.rule) { updated in
                var list = rules
                if let index = list.firstIndex(where: { $0.id == updated.id }) {
                    list[index] = updated
                } else {
                    guard list.count < 8 else { return }
                    list.append(updated)
                }
                if updated.enabled {
                    PosiesNotificationScheduler.askPermission { _ in
                        store(list)
                        refreshStatus()
                    }
                } else {
                    store(list)
                }
            }
        }
        .alert("Reminders", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("OK") { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        Calendar.current.date(from: DateComponents(hour: hour))?.formatted(date: .omitted, time: .shortened) ?? "\(hour):00"
    }

    private func changeEnabled(_ id: UUID, enabled: Bool) {
        let list = rules.map { rule -> PosiesReminder in
            var copy = rule
            if rule.id == id { copy.enabled = enabled }
            return copy
        }
        if enabled {
            PosiesNotificationScheduler.askPermission { _ in store(list); refreshStatus() }
        } else {
            store(list)
        }
    }
    private func store(_ items: [PosiesReminder]) {
        guard let encoded = try? JSONEncoder().encode(items),
              let string = String(data: encoded, encoding: .utf8) else {
            statusMessage = "Unable to save reminder settings."
            return
        }
        storedRules = string
        sync()
    }
    private func sync() {
        PosiesNotificationScheduler.refresh(rules, quietStart: quietStartHour, quietEnd: quietEndHour) {
            error in
            if let error { permissionStatus = error }
        }
    }
    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                permissionStatus = (settings.authorizationStatus == .authorized ||
                                    settings.authorizationStatus == .provisional)
                    ? "Notifications allowed on this iPhone."
                    : "Notifications are currently disabled. Manual logging is available."
            }
        }
    }
}

private struct ReminderEditRoute: Identifiable {
    let rule: PosiesReminder
    var id: UUID { rule.id }
}

private struct ReminderForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rule: PosiesReminder
    let onSave: (PosiesReminder) -> Void

    init(rule: PosiesReminder, onSave: @escaping (PosiesReminder) -> Void) {
        _rule = State(initialValue: rule)
        self.onSave = onSave
    }
    private var time: Binding<Date> {
        Binding(get: { rule.displayTime }, set: { date in
            rule.hour = Calendar.current.component(.hour, from: date)
            rule.minute = Calendar.current.component(.minute, from: date)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Reminder name", text: $rule.name)
                    Text("Type").font(.subheadline.weight(.semibold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 115))], spacing: 8) {
                        ForEach(PosiesReminder.supportedCategories, id: \.self) { category in
                            let chosen = rule.category == category
                            Button {
                                rule.category = PosiesChoiceBehavior.toggle(rule.category, tapped: category)
                            } label: {
                                Text(category)
                                    .font(.subheadline.weight(chosen ? .semibold : .regular))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .foregroundStyle(chosen ? Color.white : Color.primary)
                                    .background(chosen ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                                in: RoundedRectangle(cornerRadius: 11))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(chosen ? [.isSelected] : [])
                            .accessibilityHint(chosen ? "Selected. Tap again to clear." : "Tap to choose reminder type.")
                        }
                    }
                    DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                    Toggle("Enabled", isOn: $rule.enabled).tint(.potsTeal)
                }
                Section("Repeat on") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(1...7, id: \.self) { weekday in
                            let chosen = rule.weekdays.contains(weekday)
                            Button(weekdayName(weekday)) {
                                if chosen {
                                    rule.weekdays.removeAll { $0 == weekday }
                                } else {
                                    rule.weekdays.append(weekday)
                                    rule.weekdays.sort()
                                }
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(chosen ? Color.white : Color.primary)
                            .padding(9)
                            .background(chosen ? Color.potsButtonFill : Color.potsSurfaceMuted,
                                        in: RoundedRectangle(cornerRadius: 11))
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(chosen ? [.isSelected] : [])
                            .accessibilityHint(chosen ? "Selected. Tap again to clear." : "Tap to add this day.")
                        }
                    }
                    if rule.weekdays.isEmpty {
                        Text("Choose at least one day before saving. You can tap any selected day again to remove it.")
                            .font(.caption).foregroundStyle(Color.potsSecondary)
                    }
                }
                Section {
                    Text("Notifications never confirm medication intake. Use Log to record what actually happened.")
                        .font(.footnote).foregroundStyle(Color.potsSecondary)
                }
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(rule)
                        dismiss()
                    }
                    .disabled(rule.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              rule.name.count > 120 || rule.weekdays.isEmpty || rule.category.isEmpty)
                }
            }
        }
    }
    private func weekdayName(_ day: Int) -> String {
        Calendar.current.shortWeekdaySymbols[day - 1]
    }
}
