import SwiftUI

/// The approved introduction is shared by the post-install screen and the in-phone guide.
enum WelcomeBriefing {
    struct Section: Identifiable {
        let id: Int
        let title: String
        let paragraphs: [String]
        let bullets: [String]
        let ending: [String]
        init(_ id: Int, _ title: String, _ paragraphs: [String], bullets: [String] = [], ending: [String] = []) {
            self.id = id; self.title = title; self.paragraphs = paragraphs
            self.bullets = bullets; self.ending = ending
        }
    }

    static let sections: [Section] = [
        Section(1, "How it all began", [
            "It was supposed to be a routine job.",
            "Someone brought you a phone and asked you to get it working again. It seemed ordinary enough. You connected it, ran your diagnostics and prepared a new jailbroken environment.",
            "Everything went according to plan.",
            "At least, that's what the installation report says.",
            "With the jailbreak complete, the phone is ready to be configured. An existing backup is waiting to be restored, and there's no obvious reason to believe anything is wrong with it.",
            "You expect to finish setting up the phone and continue with your day.",
            "But sometimes, restoring a phone means bringing back more than its files."
        ]),
        Section(2, "Your role", [
            "In Last Seen, the phone itself is your world.",
            "You will personalize the device, restore its backup, explore its applications and gradually discover the life contained within it.",
            "The restored messages, photographs, contacts, emails and personal records may not be what you expected.",
            "Who did this information belong to? Why was it left behind? And why do certain details seem increasingly difficult to explain?",
            "Your investigation begins with curiosity, not fear.",
            "There is no predetermined order in which you must explore every application. Take your time, become familiar with the phone and allow its story to unfold naturally."
        ]),
        Section(3, "Navigating your phone", [
            "Use familiar smartphone gestures to explore your environment."
        ], bullets: [
            "Tap an application to open it.",
            "Swipe up on the in-game home indicator to return home.",
            "Swipe sideways on the home indicator to view recent applications.",
            "Swipe down from the upper-left notification control to review notifications.",
            "Swipe down from the upper-right control to access quick settings.",
            "Swipe up on the lock screen to unlock.",
            "Repeat a system-edge swipe when necessary to access your real iPhone controls."
        ], ending: [
            "You can also customize your experience through Settings, Patchline and Relay."
        ]),
        Section(4, "The world inside", [
            "Explore conversations, photographs, calendars, emails, notes, contacts and files.",
            "Get to know the people whose lives are connected to this phone. Pay attention to what they say, what they remember and what they choose not to discuss.",
            "An ordinary conversation may contain an important detail. A photograph may contradict something you previously read. A forgotten appointment may become significant later.",
            "Your real device's time and date can influence the atmosphere of the experience.",
            "You do not need to play at a particular hour to enjoy the story."
        ]),
        Section(5, "Patchline", [
            "Patchline is your jailbreak management utility.",
            "Use it to:"
        ], bullets: [
            "Review your jailbreak environment.",
            "Restart SpringBoard.",
            "Reboot userspace.",
            "Enter or exit Safe Mode.",
            "Manage restart sounds.",
            "Access Relay."
        ], ending: [
            "Safe Mode temporarily disables visual tweaks without uninstalling your packages.",
            "Restarting the environment does not erase your restored records or story progress."
        ]),
        Section(6, "Relay Package Manager", [
            "Make the phone your own.",
            "Relay provides repositories containing themes, tweaks and customization tools.",
            "Browse sources, search for packages, manage installed software, review updates and queue multiple changes.",
            "Confirm your changes and restart SpringBoard when required.",
            "All available packages are free."
        ]),
        Section(7, "Protected information", [
            "Not everything on the phone is immediately accessible.",
            "Certain records and applications require additional authentication. You may need to explore other parts of the phone to discover information that helps you gain access.",
            "Optional biometric authentication becomes available after the original owner's passcode has been verified.",
            "Pay attention. The answer may already be somewhere on your screen."
        ]),
        Section(8, "Understanding the experience", [
            "Last Seen is a slow-burn psychological horror and mystery game.",
            "Not every moment is intended to frighten you. Much of your experience will involve ordinary conversations, everyday activities and seemingly unimportant details.",
            "That familiarity is part of the story.",
            "As you explore, curiosity may become uncertainty. Uncertainty may become suspicion. Eventually, you may begin questioning things you previously accepted as normal.",
            "There is no need to rush.",
            "Sometimes the most unsettling discoveries are the ones you make yourself."
        ]),
        Section(9, "Community acknowledgments", [
            "Last Seen celebrates the creativity, dedication and history of the jailbreak community.",
            "Inspired by the generations of developers and communities behind:",
            "Installer, Cydia, redsn0w, blackra1n, Absinthe, evasi0n, Pangu, checkra1n, unc0ver, Dopamine, palera1n, Sileo, Zebra and SnowBoard.",
            "Special appreciation goes to the countless independent developers, theme designers, repository maintainers and enthusiasts who helped make smartphone customization possible.",
            "Patchline and Relay are original creations for Last Seen. This game is independent and is not affiliated with or endorsed by the acknowledged projects."
        ]),
        Section(10, "Privacy and immersion", [
            "Last Seen is an original fictional horror game.",
            "Its characters, conversations, applications, restored records and jailbreak environment exist entirely within the game.",
            "No real jailbreak, kernel exploitation, USB data transfer or device modification has occurred.",
            "Optional native iPhone features remain under your control."
        ])
    ]
    static let closing = [
        "The installation is complete.",
        "The phone is waiting.",
        "What you discover next is up to you."
    ]
    static let closingLine = "Every phone holds a story. Some are better left unseen."
}

/// Preserve established setup and records; on a Build 19 upgrade show only the new briefing.
/// Fresh installations and older opening revisions retain the original initialization path.
enum WelcomeRevision {
    static let current = 7
    static func destination(previousRevision: Int, stage: Int) -> Int {
        if previousRevision < 6 { return 0 }
        if previousRevision < current && stage >= 6 { return 5 }
        return stage
    }
}

struct WelcomeBriefingView: View {
    var revisiting = false
    let onContinue: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let accent = Color(red: 0.35, green: 0.86, blue: 0.77)
    private let background = Color(red: 0.035, green: 0.06, blue: 0.10)

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 560 || dynamicTypeSize.isAccessibilitySize
            VStack(spacing: compact ? 8 : 12) {
                HStack(spacing: 10) {
                    OpeningArt(name: "Opening_Unlock", size: compact ? 32 : 46)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(revisiting ? "Welcome to Last Seen" : "Patchline complete")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                            .fixedSize(horizontal: false, vertical: true)
                        if !compact {
                            Text("Bootstrap installed • Relay ready • SpringBoard reloaded")
                                .font(.caption).foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "checkmark.seal.fill").font(.title2).foregroundColor(accent)
                        .accessibilityLabel("Installation complete")
                }
                HStack {
                    Label("Rootless • Environment ready", systemImage: "circle.fill")
                        .font(.caption.weight(.semibold)).foregroundColor(accent)
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Welcome to Last Seen").font(.headline)
                        Spacer()
                        Image(systemName: "book.closed").foregroundColor(accent).accessibilityHidden(true)
                    }.padding(14)
                    Divider()
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 19) {
                            Text("Your device environment is ready.").font(.subheadline.weight(.semibold))
                            ForEach(WelcomeBriefing.sections) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(String(format: "%02d", section.id) + " / " + section.title.uppercased())
                                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                                        .foregroundColor(accent).accessibilityAddTraits(.isHeader)
                                        .fixedSize(horizontal: false, vertical: true)
                                    paragraphs(section.paragraphs)
                                    ForEach(Array(section.bullets.enumerated()), id: \.offset) { item in
                                        HStack(alignment: .firstTextBaseline, spacing: 9) {
                                            Text("•").foregroundColor(accent).accessibilityHidden(true)
                                            Text(item.element).fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    paragraphs(section.ending)
                                }
                                Divider()
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Text("PATCHLINE // SESSION COMPLETE").font(.system(.caption, design: .monospaced).weight(.semibold)).foregroundColor(accent)
                                Text("DEVICE STATUS: READY").font(.caption.weight(.semibold)).foregroundColor(accent)
                                paragraphs(WelcomeBriefing.closing)
                                Text(WelcomeBriefing.closingLine).italic().foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                    }
                    .accessibilityIdentifier("welcomeBriefingScroll")
                    Divider()
                    Label("Scroll to read • Continue whenever ready", systemImage: "chevron.down")
                        .font(.caption2).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity).padding(10)
                }
                .frame(maxHeight: .infinity)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .layoutPriority(1)

                Button(action: onContinue) {
                    Text(revisiting ? "Done" : "Enter phone")
                        .font(.headline)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                }.buttonStyle(.borderedProminent).tint(accent).foregroundColor(background)
                    .accessibilityIdentifier("welcomeBriefingContinue")
                if !compact {
                    Text(revisiting ? "PATCHLINE • PLAYER GUIDE" : "PATCHLINE • SESSION COMPLETE")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(1.5).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 8)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func paragraphs(_ values: [String]) -> some View {
        ForEach(Array(values.enumerated()), id: \.offset) { item in
            Text(item.element).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
