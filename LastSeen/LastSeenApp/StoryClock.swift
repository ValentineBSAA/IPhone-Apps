import Foundation

/// Story dialogue takes its cues from the user's actual iPhone clock.
/// Never fake the device time; old messages retain their real delivery dates.
/// Time-of-day changes only the *wording* of authored dialogue, not availability
/// of the story. The player can finish the game at noon or at midnight.
enum StoryClock {
    static func timeOfDay(_ date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }

    static func contextualize(_ beat: StoryBeat,
                              sceneID: String,
                              index: Int,
                              now: Date = Date(),
                              calendar: Calendar = .current) -> StoryBeat {
        guard index == 0 else { return beat }
        let period = timeOfDay(now, calendar: calendar)

        let adjusted: String
        switch (sceneID, period) {
        case ("opening", "morning"):
            adjusted = "Morning! Quick question. Did maintenance mention an elevator inspection?"
        case ("opening", "afternoon"):
            adjusted = "Hey, quick question. Did maintenance mention an elevator inspection?"
        case ("opening", "evening"):
            adjusted = "Hey. Sorry to interrupt your evening. Did maintenance mention an elevator inspection?"
        case ("opening", "night"):
            adjusted = "Sorry to message so late. Did maintenance mention an elevator inspection?"
        case ("eli_opening", "morning"):
            adjusted = "Morning, it's Eli from maintenance. Can I ask you something?"
        case ("eli_opening", "afternoon"):
            adjusted = "Hi, it's Eli from the maintenance office. Hope I'm not interrupting."
        case ("eli_opening", "evening"):
            adjusted = "Evening, it's Eli from maintenance. Sorry to bother you."
        case ("eli_opening", "night"):
            adjusted = "Sorry for the late message. It's Eli, the night caretaker."
        default:
            return beat
        }

        return StoryBeat(beat.thread, beat.sender, adjusted,
                         kind: beat.kind, delay: beat.delay, asset: beat.asset)
    }
}
