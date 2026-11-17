import Foundation

/// Each contact owns a separate offline story. Selecting one never starts another.
/// Nora's original Missing Floor script is preserved as a *single* conversation:
/// other characters' messages are forwarded by her, not delivered to other inboxes.
enum SoloStories {
    static func start(for contact: String) -> String {
        switch contact {
        case Contact.eli.id: return "eli_opening"
        case Contact.unit7.id: return "unit7_opening"
        default: return StoryScript.firstScene
        }
    }

    static func title(for contact: String) -> String {
        switch contact {
        case Contact.eli.id: return "The Night Shift"
        case Contact.unit7.id: return "The Seventh Number"
        default: return "The Missing Floor"
        }
    }

    static let scenes: [String: StoryScene] = {
        var library: [String: StoryScene] = [:]
        for (key, original) in StoryScript.scenes {
            let beats = original.beats.map { beat -> StoryBeat in
                let text: String
                if beat.kind == .call {
                    // No simulated phone call without real, licensed/original recorded audio.
                    text = "That unknown number tried to call me. I didn't pick up."
                } else if beat.thread == "eli" {
                    text = "Eli just texted me: “\(beat.body)”"
                } else if beat.thread == "unit7" {
                    text = "An unknown number sent me this: “\(beat.body)”"
                } else {
                    text = beat.body
                }
                return StoryBeat("nora", "nora", text,
                    kind: beat.kind == .call ? .text : beat.kind,
                    delay: beat.delay)
            }
            library[key] = StoryScene(id: original.id, beats: beats,
                choices: original.choices, next: original.next, ending: original.ending,
                endingDetail: original.endingDetail)
        }

        let additional: [StoryScene] = [
            StoryScene(id: "eli_opening", beats: [
                .init("eli", "eli", "Hi, this is Eli. I look after the building at night."),
                .init("eli", "eli", "Someone left a key on the desk. It has your apartment number on it."),
                .init("eli", "eli", "The strange part is that I locked the desk myself an hour ago."),
                .init("eli", "eli", "Can I ask you something? Did you hear the elevator move?")
            ], choices: [
                .init(id: "eli_careful", title: "Yes. Is someone stuck in it?", next: "eli_careful_route"),
                .init(id: "eli_skeptic", title: "Why do you have a key to my apartment?", next: "eli_skeptic_route")
            ]),
            StoryScene(id: "eli_careful_route", beats: [
                .init("eli", "eli", "I don't think anyone is in there."),
                .init("eli", "eli", "The floor counter lights up when the motor isn't running."),
                .init("eli", "eli", "I'm going to check the maintenance logs."),
                .init("eli", "eli", "Just don't touch the elevator buttons yet.")
            ], choices: [], next: "eli_last"),
            StoryScene(id: "eli_skeptic_route", beats: [
                .init("eli", "eli", "I don't. I never made that key."),
                .init("eli", "eli", "I compared it to our master set. The cut pattern doesn't match."),
                .init("eli", "eli", "There is writing on the back. It says 07."),
                .init("eli", "eli", "I should have called somebody before telling you.")
            ], choices: [], next: "eli_last"),
            StoryScene(id: "eli_last", beats: [
                .init("eli", "eli", "I found a page from the old building plans."),
                .init("eli", "eli", "There used to be a seventh floor. It was sealed after a fire."),
                .init("eli", "eli", "The key opens one of two doors. One is the stairwell exit."),
                .init("eli", "eli", "The other door has your name written on it."),
                .init("eli", "eli", "Which one should I try?")
            ], choices: [
                .init(id: "eli_exit", title: "Try the stairwell exit. Leave the other door alone.", next: "eli_safe"),
                .init(id: "eli_door", title: "Open the door with my name.", next: "eli_bad")
            ]),
            StoryScene(id: "eli_safe", beats: [
                .init("eli", "eli", "The stairwell door opened."),
                .init("eli", "eli", "There's daylight outside. That can't be right. It's still dark."),
                .init("eli", "eli", "I put the key down and left."),
                .init("eli", "eli", "I don't plan to work another night here.")
            ], choices: [], ending: "THE KEY", endingDetail: "Eli walked away from a door that knew your name."),
            StoryScene(id: "eli_bad", beats: [
                .init("eli", "eli", "Okay. It's open."),
                .init("eli", "eli", "There is a desk inside. Exactly like mine."),
                .init("eli", "eli", "A phone is ringing."),
                .init("eli", "eli", "I'm reading the screen. It says Eli Mercer."),
                .init("eli", "eli", "I can't hear the elevator anymore.")
            ], choices: [], ending: "THE REPLACEMENT",
                endingDetail: "The next caretaker reports for his shift. He has Eli's face."),

            StoryScene(id: "unit7_opening", beats: [
                .init("unit7", "unit7", "wrong floor."),
                .init("unit7", "unit7", "Sorry. That wasn't meant for you."),
                .init("unit7", "unit7", "Do you live in the building at the end of Ash Street?"),
                .init("unit7", "unit7", "Someone there is using my phone number.")
            ], choices: [
                .init(id: "unit7_who", title: "Who are you?", next: "unit7_name"),
                .init(id: "unit7_where", title: "How do you know where I live?", next: "unit7_address")
            ]),
            StoryScene(id: "unit7_name", beats: [
                .init("unit7", "unit7", "I used to have an apartment there."),
                .init("unit7", "unit7", "My name doesn't matter anymore."),
                .init("unit7", "unit7", "Can you tell me if the hallway lights are on?")
            ], choices: [], next: "unit7_last"),
            StoryScene(id: "unit7_address", beats: [
                .init("unit7", "unit7", "It's the address saved under HOME in my phone."),
                .init("unit7", "unit7", "I never typed it in."),
                .init("unit7", "unit7", "Please don't tell anyone I messaged you.")
            ], choices: [], next: "unit7_last"),
            StoryScene(id: "unit7_last", beats: [
                .init("unit7", "unit7", "I just received a photograph of your door."),
                .init("unit7", "unit7", "It was taken from the inside."),
                .init("unit7", "unit7", "There's a number scratched into the frame. Seven."),
                .init("unit7", "unit7", "I think it wants me to ask you to open it."),
                .init("unit7", "unit7", "Can you promise me you won't?")
            ], choices: [
                .init(id: "unit7_no", title: "I won't open anything. Stop messaging me.", next: "unit7_safe"),
                .init(id: "unit7_yes", title: "I'll check the door.", next: "unit7_bad")
            ]),
            StoryScene(id: "unit7_safe", beats: [
                .init("unit7", "unit7", "Good."),
                .init("unit7", "unit7", "I can finally stop pretending this is my number."),
                .init("unit7", "unit7", "Delete this conversation. Please."),
                .init("unit7", "unit7", "…")
            ], choices: [], ending: "DISCONNECTED",
                endingDetail: "You never opened the door. The number stopped responding."),
            StoryScene(id: "unit7_bad", beats: [
                .init("unit7", "unit7", "Don't."),
                .init("unit7", "unit7", "Wait. That isn't what I meant."),
                .init("unit7", "unit7", "There's somebody standing on the other side."),
                .init("unit7", "unit7", "The footsteps are coming from your side now.")
            ], choices: [], ending: "THE OTHER SIDE",
                endingDetail: "You answered the wrong invitation.")
        ]
        for scene in additional { library[scene.id] = scene }
        return library
    }()
}
