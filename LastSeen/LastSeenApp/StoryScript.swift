import Foundation

/// Complete authored offline story. Every route reaches one of three endings.
/// Event IDs are deterministic (sceneID + beat index) so relaunch cannot duplicate messages.
enum StoryScript {
    static let firstScene = "opening"

    static let scenes: [String: StoryScene] = {
        let scenes: [StoryScene] = [
            StoryScene(
                id: "opening",
                beats: [
                    .init("nora", "nora", "Hey, quick question. Did maintenance mention an elevator inspection?", delay: 1.0),
                    .init("nora", "nora", "It stops on four even when nobody is waiting. Denise said there was supposed to be an inspection.", delay: 2.0),
                    .init("nora", "nora", "It's Nora from 402, btw. We talked by the mailboxes last week 😅", delay: 2.1),
                    .init("nora", "nora", "I was going to ask Eli, but he hasn't been at the desk today.", delay: 2.2),
                    .init("nora", "nora", "Anyway I can take a photo of the door if that helps."),
                    .init("nora", "nora", "You still have the number for maintenance, right?")
                ],
                choices: [
                    .init(id: "opening_kind", title: "I can ask around. Are you okay?", next: "kind_response"),
                    .init(id: "opening_direct", title: "Have you checked the noticeboard?", next: "direct_response"),
                    .init(id: "opening_ignore", title: "Probably just a faulty sensor.", next: "dismiss_response")
                ]
            ),
            StoryScene(
                id: "kind_response",
                beats: [
                    .init("nora", "nora", "Thanks. It's probably nothing, but I appreciate it."),
                    .init("nora", "nora", "It's a little annoying because the doors keep opening while I'm trying to carry groceries."),
                    .init("nora", "nora", "I took a photo a minute ago. Hang on.")
                ],
                choices: [],
                next: "evidence"
            ),
            StoryScene(
                id: "direct_response",
                beats: [
                    .init("nora", "nora", "Oh, I haven't checked the noticeboard today."),
                    .init("nora", "nora", "I should really have looked before bothering everyone 😂"),
                    .init("nora", "nora", "I sent Denise a message earlier. She hasn't answered."),
                    .init("nora", "nora", "Here's what the elevator looked like when I got home.")
                ],
                choices: [],
                next: "evidence"
            ),
            StoryScene(
                id: "dismiss_response",
                beats: [
                    .init("nora", "nora", "Yeah, that's what I figured at first."),
                    .init("nora", "nora", "It still makes this awful scraping sound, though."),
                    .init("nora", "nora", "It was fine yesterday. Maybe somebody's repairing the motor."),
                    .init("nora", "nora", "Here, this is what I mean. Nothing dramatic.")
                ],
                choices: [],
                next: "evidence"
            ),
            StoryScene(
                id: "evidence",
                beats: [
                    .init("nora", "nora", "Photo from outside the elevator. Can you tell if there's a service sticker?", kind: .photograph, asset: "Story_02_Elevator_Reflection"),
                    .init("nora", "nora", "I thought I saw somebody near the door, but I might be seeing things in the metal."),
                    .init("eli", "eli", "Eli said the contractor didn't show up. The lift is still being inspected.", delay: 3.6),
                    .init("nora", "nora", "Eli's usually good about these things. I'll ask him again."),
                    .init("nora", "nora", "He's covering the evening shift this week."),
                    .init("unit7", "unit7", "Hi, sorry. Is this the building office? I found an old notice with this number.", delay: 3.5),
                    .init("unit7", "unit7", "I think I have the wrong number. Thanks anyway.")
                ],
                choices: [
                    .init(id: "photo_path", title: "Can you see anything unusual in the photo?", next: "photo_path"),
                    .init(id: "caretaker_path", title: "What did Eli say about the inspection?", next: "caretaker_path"),
                    .init(id: "unknown_path", title: "Who was that other number?", next: "unknown_path")
                ]
            ),
            StoryScene(
                id: "photo_path",
                beats: [
                    .init("nora", "nora", "There's a figure on the metal doors. I didn't see anyone there."),
                    .init("nora", "nora", "My front door is right beside the elevator. Here, I just took another photo."),
                    .init("nora", "nora", "My door looks different now. I don't remember those scratches."),
                    .init("nora", "nora", "Here is the photo of the door.", kind: .photograph, asset: "Story_03_Nora_Front_Door"),
                    .init("nora", "nora", "I can hear the doors sliding open above me."),
                    .init("eli", "eli", "Do not trust what you see in the mirrors.")
                ],
                choices: [],
                next: "voicemail"
            ),
            StoryScene(
                id: "caretaker_path",
                beats: [
                    .init("eli", "eli", "The elevator hasn't passed inspection since the blackout."),
                    .init("eli", "eli", "It sometimes displays floors that don't exist."),
                    .init("eli", "eli", "Stay inside until sunrise."),
                    .init("nora", "nora", "Eli. You told me that after the blackout, there were no survivors on the fourth floor."),
                    .init("eli", "eli", "Nora, this is not a conversation for text messages.")
                ],
                choices: [],
                next: "voicemail"
            ),
            StoryScene(
                id: "unknown_path",
                beats: [
                    .init("unit7", "unit7", "I don't know who gave me the number. Sorry."),
                    .init("unit7", "unit7", "I used to live in that building. I thought they'd changed the numbers."),
                    .init("nora", "nora", "That is a little weird. Maybe it was an old tenant?"),
                    .init("eli", "eli", "Eli said the old directory was replaced years ago."),
                    .init("unit7", "unit7", "Wait. Does the building still have that little stairwell by the elevator?")
                ],
                choices: [],
                next: "voicemail"
            ),
            StoryScene(
                id: "voicemail",
                beats: [
                    .init("eli", "eli", "Something happened here years ago. I can't explain all of it over messages."),
                    .init("nora", "nora", "I found a call in my history from MY OWN NUMBER."),
                    .init("nora", "nora", "Please listen before you do anything."),
                    .init("nora", "nora", "Voice message: Do not take the elevator. If the doors open at seven, close your eyes and count the steps to the stairs.", kind: .voiceNote),
                    .init("nora", "nora", "That's my voice. I never recorded it."),
                    .init("unit7", "unit7", "INCOMING CALL: UNKNOWN", kind: .call, delay: 3.0),
                    .init("eli", "eli", "If you got a call, don't give it your name."),
                    .init("nora", "nora", "Someone is knocking now. Three slow knocks. From the other side of my bedroom wall.")
                ],
                choices: [
                    .init(id: "stairs", title: "Take the stairwell and investigate.", next: "stairs"),
                    .init(id: "elevator", title: "Check the elevator camera.", next: "elevator"),
                    .init(id: "nora_check", title: "Ask Nora to stay on the phone.", next: "nora_check")
                ]
            ),
            StoryScene(
                id: "stairs",
                beats: [
                    .init("eli", "eli", "The stairwell lights only work every other landing."),
                    .init("eli", "eli", "Count the doors, not the steps."),
                    .init("eli", "eli", "Photo from the stairwell, taken right now.", kind: .photograph, asset: "Story_09_Stairwell"),
                    .init("nora", "nora", "I can hear you on the stairs."),
                    .init("nora", "nora", "But you're still messaging me from your apartment, right?"),
                    .init("unit7", "unit7", "YOU HAVE PASSED THE FOURTH FLOOR TWICE."),
                    .init("eli", "eli", "Whatever you do, don't stop walking when you see the green exit sign.")
                ],
                choices: [],
                next: "intersection"
            ),
            StoryScene(
                id: "elevator",
                beats: [
                    .init("eli", "eli", "I still have access to the lobby camera."),
                    .init("eli", "eli", "There's nobody standing at the elevator. But the doors keep opening."),
                    .init("eli", "eli", "I snapped the inside control panel.", kind: .photograph, asset: "Story_06_Inside_Elevator"),
                    .init("nora", "nora", "What's the display showing?"),
                    .init("eli", "eli", "Seven."),
                    .init("unit7", "unit7", "CAMERAS ONLY SEE WHAT IS ALREADY GONE."),
                    .init("eli", "eli", "The floor indicator just changed to your apartment number.")
                ],
                choices: [],
                next: "intersection"
            ),
            StoryScene(
                id: "nora_check",
                beats: [
                    .init("nora", "nora", "Okay. I'm holding my phone."),
                    .init("nora", "nora", "This is the hallway outside my apartment.", kind: .photograph, asset: "Story_01_Nora_Hallway"),
                    .init("nora", "nora", "Wait. Someone outside my apartment is talking with my voice."),
                    .init("nora", "nora", "They just said 'I am holding my phone.'"),
                    .init("eli", "eli", "Do not open for anyone who can finish your sentences."),
                    .init("unit7", "unit7", "SHE IS VERY GOOD AT PRETENDING TO BE HERSELF."),
                    .init("nora", "nora", "Stop. Please just stop.")
                ],
                choices: [],
                next: "intersection"
            ),
            StoryScene(
                id: "intersection",
                beats: [
                    .init("eli", "eli", "I found the original maintenance record."),
                    .init("eli", "eli", "There was a seventh floor. It was sealed after the fire. The fourth floor is a replacement."),
                    .init("nora", "nora", "So where have I been living?"),
                    .init("eli", "eli", "I need to know if you examined Nora's photograph. The reflection is evidence."),
                    .init("unit7", "unit7", "THE DOOR IS OPEN."),
                    .init("nora", "nora", "Someone just put a key in my lock."),
                    .init("nora", "nora", "Please. Tell me what to do.")
                ],
                choices: [
                    .init(id: "investigate", title: "Cross-check the clues before answering.", next: "threshold"),
                    .init(id: "nora_trust_early", title: "Tell Nora to open her door.", next: "loop_ending"),
                    .init(id: "eli_trust_early", title: "Follow Eli's directions immediately.", next: "taken_ending")
                ]
            ),
            StoryScene(
                id: "threshold",
                beats: [
                    .init("eli", "eli", "Look at the reflection. That figure isn't standing inside the elevator."),
                    .init("nora", "nora", "There isn't a mirror in that hallway, but you can see someone behind me."),
                    .init("eli", "eli", "Now compare that time to the voice message."),
                    .init("unit7", "unit7", "YOU ONLY GET TO ASK ONE MORE QUESTION."),
                    .init("nora", "nora", "The hallway should not be this long. Look.", kind: .photograph, asset: "Story_04_Impossible_Hallway"),
                    .init("nora", "nora", "I heard the lock turn. I'm running out of time.")
                ],
                choices: [
                    .init(id: "escape", title: "Use the photo and voicemail to find the real exit.", next: "safe_ending", requiredClues: ["photograph", "voiceNote"]),
                    .init(id: "loop", title: "Nora, open the door. It might be Eli.", next: "loop_ending"),
                    .init(id: "taken", title: "Eli, I'm following your voice.", next: "taken_ending")
                ]
            ),
            StoryScene(
                id: "safe_ending",
                beats: [
                    .init("nora", "nora", "The person in the photo... their face is turned away."),
                    .init("eli", "eli", "And the recording said not to take the elevator."),
                    .init("eli", "eli", "The figure is standing at the stairwell, not the elevator. I think it's warning us."),
                    .init("nora", "nora", "The voice message said not to take the elevator."),
                    .init("eli", "eli", "Go to the stairwell when the doors close. Don't follow the figure into the elevator."),
                    .init("nora", "nora", "I'm outside. I can smell rain. Real rain."),
                    .init("unit7", "unit7", "ONE LEFT."),
                    .init("nora", "nora", "I think we made it. Please tell me you're okay."),
                    .init("nora", "nora", "I never want to see that hallway again.")
                ],
                choices: [],
                ending: "THE EXIT",
                endingDetail: "You compared the clues, found the hidden timing, and escaped the missing floor. The number on the screen now reads six."
            ),
            StoryScene(
                id: "loop_ending",
                beats: [
                    .init("nora", "nora", "Okay. I'm opening it."),
                    .init("nora", "nora", "Oh, thank God. It's me."),
                    .init("eli", "eli", "What did you just tell her to do?"),
                    .init("unit7", "unit7", "WELCOME HOME."),
                    .init("nora", "nora", "Hey, quick question. Did maintenance mention an elevator inspection?"),
                    .init("nora", "nora", "You awake?"),
                    .init("unit7", "unit7", "THE CONVERSATION WILL BEGIN AGAIN.")
                ],
                choices: [],
                ending: "THE LOOP",
                endingDetail: "You let the wrong person in. The conversation repeats, but the contact pictures are different this time."
            ),
            StoryScene(
                id: "taken_ending",
                beats: [
                    .init("eli", "eli", "Come toward my voice."),
                    .init("eli", "eli", "Just a little farther."),
                    .init("nora", "nora", "STOP. Eli has been dead since the fire."),
                    .init("unit7", "unit7", "THAT IS CORRECT."),
                    .init("eli", "eli", "Just one more step."),
                    .init("unit7", "unit7", "NEW TENANT REGISTERED."),
                    .init("unit7", "unit7", "One last picture.", kind: .photograph, asset: "Story_10_Final_Reveal"),
                    .init("nora", "nora", "I can hear you knocking. But your number is disconnected.")
                ],
                choices: [],
                ending: "THE TAKEN",
                endingDetail: "You followed the caretaker's voice into the sealed floor. By morning the building has one more apartment."
            )
        ]
        return Dictionary(uniqueKeysWithValues: scenes.map { ($0.id, $0) })
    }()
}
