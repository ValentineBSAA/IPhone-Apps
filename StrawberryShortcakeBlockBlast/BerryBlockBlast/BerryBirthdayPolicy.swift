import Foundation

/// Original local-only Berry Birthday behavior in one testable place.
/// A birthday stores only month/day, never a birth year.
@MainActor
enum BerryBirthdayPolicy {
    static let monthKey = "berryberryblast.birthday.month.v0511"
    static let dayKey = "berryberryblast.birthday.day.v0511"
    static let giftAmount = 100

    /// A leap-capable reference year keeps February 29 selectable even
    /// when the current year has no February 29.
    static func maximumDay(month: Int) -> Int {
        switch month {
        case 2: return 29
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    static func isValid(month: Int, day: Int) -> Bool {
        guard (1...12).contains(month), day >= 1 else { return false }
        return day <= maximumDay(month: month)
    }

    /// Match the existing device-local calendar rule. A Feb 29 birthday
    /// is celebrated only in a leap year, unless an explicit new product
    /// policy is approved later; do not silently select another day.
    static func isBirthday(month: Int,
                           day: Int,
                           on date: Date,
                           calendar: Calendar = .current) -> Bool {
        isValid(month: month, day: day) &&
        calendar.component(.month, from: date) == month &&
        calendar.component(.day, from: date) == day
    }

    /// The key is byte-identical to the original annual payout key.
    static func awardKey(on date: Date,
                         calendar: Calendar = .current) -> String {
        "berryblockblast.award.birthday-" +
        String(calendar.component(.year, from: date))
    }

    static func hasClaimed(on date: Date,
                           defaults: UserDefaults = .standard,
                           calendar: Calendar = .current) -> Bool {
        defaults.bool(forKey: awardKey(on: date, calendar: calendar))
    }

    /// Use the actual once-only BerryGameSession reward, but only for a
    /// matching store and legitimate local calendar birthday. The UI and
    /// live wallet use .standard; disposable QA suites cannot pay it.
    @discardableResult
    static func claim(month: Int,
                      day: Int,
                      on date: Date,
                      session: BerryGameSession,
                      defaults: UserDefaults = .standard,
                      calendar: Calendar = .current) -> Bool {
        guard isBirthday(month: month, day: day, on: date, calendar: calendar),
              !hasClaimed(on: date, defaults: defaults, calendar: calendar),
              session.usesCheckoutDefaults(defaults) else { return false }
        session.awardOnce("birthday-" +
                          String(calendar.component(.year, from: date)),
                          amount: giftAmount, reason: "Birthday Berry Bash")
        return hasClaimed(on: date, defaults: defaults, calendar: calendar)
    }
}
