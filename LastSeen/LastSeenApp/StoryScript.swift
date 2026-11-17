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
                    .init("nora", "nora", "It keeps stopping on my floor even when nobody calls it.", delay: 2.0),
                    .init("nora", "nora", "It's Nora from 402, by the way.", delay: 2.1),
                    .init("nora", "nora", "I was going to ask Eli, but there's something else. I keep hearing furniture dragging upstairs.", delay: 2.2),
                    .init("nora", "nora", "Except we're on the top floor."),
                    .init("nora", "nora", "Tell me you hear it too.")
                ],
                choices: [
                    .init(id: "opening_kind", title: "I hear something. Are you okay?", next: "kind_response"),
                    .init(id: "opening_direct", title: "There isn't another floor. Who is this?", next: "direct_response"),
                    .init(id: "opening_ignore", title: "You're probably hearing the pipes.", next: "dismiss_response")
                ]
            ),
            StoryScene(
                id: "kind_response",
                beats: [
                    .init("nora", "nora", "Thank you. I thought I was losing it."),
                    .init("nora", "nora", "Whatever it is, it stops whenever I move toward my door."),
                    .init("nora", "nora", "Look at this. I took it through the peephole.")
                ],
                choices: [],
                next: "evidence"
            ),
            StoryScene(
                id: "direct_response",
                beats: [
                    .init("nora", "nora", "What? It's Nora."),
                    .init("nora", "nora", "We've shared an elevator for six months."),
                    .init("nora", "nora", "Okay, you're right to be suspicious. Something's wrong here."),
                    .init("nora", "nora", "I took a picture so you'd believe me.")
                ],
                choices: [],
                next: "evidence"
            ),
            StoryScene(
                id: "dismiss_response",
                beats: [
                    .init("nora", "nora", "I know what pipes sound like."),
                    .init("nora", "nora", "Pipes don't drag chairs."),
                    .init("nora", "nora", "And pipes don't whisper your name."),
                    .init("nora", "nora", "Please look at this before you decide I'm crazy.")
                ],
                choices: [],
                next: "evidence"
            ),
            StoryScene(
                id: "evidence",
                beats: [
                    .init("nora", "nora", "This is the elevator right now. Look at its reflection.", kind: .photograph, asset: "Story_02_Elevator_Reflection"),
                    .init("nora", "nora", "I was standing alone when I took that. Does it look like someone is in the reflection?"),
                    .init("eli", "eli", "Building notice: maintenance on the north stairwell. Avoid the elevator tonight.", delay: 3.6),
                    .init("nora", "nora", "Why is Eli messaging you too?"),
                    .init("nora", "nora", "He doesn't usually work nights."),
                    .init("unit7", "unit7", "THERE IS ROOM FOR ONE MORE.", delay: 3.5),
                    .init("unit7", "unit7", "SEVENTH FLOOR. LEFT DOOR.")
                ],
                choices: [
                    .init(id: "photo_path", title: "Nora, what does the elevator say?", next: "photo_path"),
                    .init(id: "caretaker_path", title: "Eli, explain the elevator warning.", next: "caretaker_path"),
                    .init(id: "unknown_path", title: "Who gave this number to you?", next: "unknown_path")
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
                    .init("unit7", "unit7", "YOU DID."),
                    .init("unit7", "unit7", "TOMORROW."),
                    .init("nora", "nora", "You need to block that number."),
                    .init("eli", "eli", "Don't respond to unknown numbers. The building records who answers."),
                    .init("unit7", "unit7", "TOO LATE.")
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
