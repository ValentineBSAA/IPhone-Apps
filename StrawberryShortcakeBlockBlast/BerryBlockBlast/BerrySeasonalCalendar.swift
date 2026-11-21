import Foundation

/// H0/H5 seasonal date policy prototype. Pure, deterministic, and read-only.
/// NOT connected to Home, Settings, purchases, rewards, saves, notifications,
/// or the live artwork resolver. Never asks for GPS/location permission.
enum BerrySeasonalEvent: String, CaseIterable, Hashable {
    case none
    case halloween
    case christmas
    case thanksgiving
    case birthday
}

enum BerrySeasonalDisplayChoice: Equatable {
    case automatic
    case off
    /// Preview is temporary only; it is not a year-round persisted override.
    case preview(BerrySeasonalEvent)
}

struct BerrySeasonalOptions {
    var choice: BerrySeasonalDisplayChoice = .automatic
    /// The feature stays dormant until players explicitly enable it in a
    /// separately reviewed Settings UI. Existing game prefs are untouched.
    var automaticHolidaysEnabled = false
    var enabledHolidays: Set<BerrySeasonalEvent> = [.halloween, .christmas, .thanksgiving]
    var birthdayArtEnabled = false
    var birthdayMonth = 0
    var birthdayDay = 0
    /// Optional explicit calendar-country setting; nil uses iOS Region.
    /// Region is not GPS and does not prove physical whereabouts.
    var countryOverride: String? = nil
}

struct BerrySeasonalResolution: Equatable {
    enum Source: String {
        case disabled
        case manualPreview
        case optedInBirthday
        case optedInHoliday
        case baseline
    }

    let event: BerrySeasonalEvent
    let source: Source
    let effectiveCountryCode: String?
}

enum BerrySeasonalCalendar {
    /// Uses the time zone and Region available on the phone, with injectable
    /// inputs for offline tests, travelers, and iOS foreground/time changes.
    /// Holiday dates use the Gregorian calendar irrespective of a user's
    /// display-calendar preference. No network, geolocation or analytics.
    static func resolve(
        at date: Date = Date(),
        timeZone: TimeZone = .autoupdatingCurrent,
        deviceRegionCode: String? = Locale.autoupdatingCurrent.regionCode,
        options: BerrySeasonalOptions
    ) -> BerrySeasonalResolution {
        let region = normalizedRegion(options.countryOverride ?? deviceRegionCode)
        func decision(_ event: BerrySeasonalEvent,
                      _ source: BerrySeasonalResolution.Source) -> BerrySeasonalResolution {
            BerrySeasonalResolution(event: event, source: source,
                                    effectiveCountryCode: region)
        }

        switch options.choice {
        case .off:
            return decision(.none, .disabled)
        case .preview(let event):
            return decision(event, .manualPreview)
        case .automatic:
            break
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.dateComponents([.month, .day, .weekday], from: date)
        guard let month = today.month, let day = today.day else {
            return decision(.none, .baseline)
        }

        // Existing birthday month/day can be read later by the UI, but a
        // separate affirmative opt-in is required for seasonal birthday art.
        if options.birthdayArtEnabled,
           validBirthday(month: options.birthdayMonth, day: options.birthdayDay),
           month == options.birthdayMonth, day == options.birthdayDay {
            return decision(.birthday, .optedInBirthday)
        }

        guard options.automaticHolidaysEnabled else {
            return decision(.none, .baseline)
        }

        if month == 10, day == 31,
           options.enabledHolidays.contains(.halloween) {
            return decision(.halloween, .optedInHoliday)
        }
        if month == 12, day == 25,
           options.enabledHolidays.contains(.christmas) {
            return decision(.christmas, .optedInHoliday)
        }
        // US Thanksgiving is the fourth Thursday in November. Do not
        // silently apply this date to Canada or all other countries.
        if region == "US", month == 11, (22...28).contains(day),
           today.weekday == 5,
           options.enabledHolidays.contains(.thanksgiving) {
            return decision(.thanksgiving, .optedInHoliday)
        }

        return decision(.none, .baseline)
    }

    static func validBirthday(month: Int, day: Int) -> Bool {
        guard (1...12).contains(month), (1...31).contains(day) else { return false }
        // 2028 is a leap year: Feb 29 is a valid stored birthday, but the
        // default visual fires on Feb 29 only. No unapproved Feb 28/Mar 1 rule.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let first = calendar.date(from: DateComponents(year: 2028, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: first) else {
            return false
        }
        return range.contains(day)
    }

    private static func normalizedRegion(_ code: String?) -> String? {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
              code.count == 2, code.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            return nil
        }
        return code
    }
}
