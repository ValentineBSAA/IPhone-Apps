import SwiftUI

struct ConversationView: View {
    let contact: Contact
    @EnvironmentObject private var game: GameStore
    @State private var photoToShow: GameMessage?
    @State private var draft = ""
    @State private var showTypedHelp = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 11) {
                        Text("TODAY  ·  1:42 AM")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(Night.muted)
                            .padding(.vertical, 17)

                        ForEach(game.messages(in: contact.id)) { message in
                            MessageRow(message: message, photoToShow: $photoToShow)
                                .id(message.id)
                        }

                        if game.typingThread == contact.id {
                            HStack {
                                TypingDots()
                                Spacer()
                            }
                            .id("typing")
                            .padding(.top, 4)
                        }

                        if game.state.endingID != nil && contact == .nora {
                            Text(game.endingTitle ?? "THE END")
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(Night.gold)
                                .padding(.top, 30)
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 17)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: game.state.messages.count) { _ in
                    game.markThreadRead(contact.id)
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: game.typingThread) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: game.state.choiceReady) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    game.markThreadRead(contact.id)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            Divider().overlay(.white.opacity(0.07))

            if game.state.endingID != nil {
                footerNote("Story complete. Return to your inbox to replay.")
            } else if game.state.choiceReady {
                if contact == .nora {
                    choiceComposer
                } else {
                    VStack(spacing: 8) {
                        footerNote("Nora is waiting for your response.")
                        NavigationLink(value: Contact.nora) {
                            Label("Reply in Nora's conversation", systemImage: "bubble.left.and.bubble.right")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(13)
                                .background(Night.raised, in: RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 15)
                    }
                    .padding(.bottom, 10)
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Night.muted)
                        .font(.system(size: 22))
                    Text(game.typingThread == contact.id ? "\(contact.name) is typing…" : "Waiting for a reply…")
                        .font(.system(size: 14))
                        .foregroundColor(Night.muted)
                    Spacer()
                    Button {
                        game.revealNextNow()
                    } label: {
                        Label("Reveal", systemImage: "forward.end.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .accessibilityHint("Skip the current fictional message delay")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
            }
        }
        .background(Night.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 9) {
                    ContactAvatar(contact: contact, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(.system(size: 14, weight: .semibold))
                        Text(game.typingThread == contact.id ? "typing…" : contact.subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(game.typingThread == contact.id ? Night.accent : Night.muted)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .sheet(item: $photoToShow) { photo in
            PhotoDetailView(message: photo)
                .environmentObject(game)
        }
    }

    private func footerNote(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(Night.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
    }

    private var choiceComposer: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionEyebrow(text: "Your response changes what happens next")
                .padding(.horizontal, 3)

            ForEach(game.availableChoices) { choice in
                let unlocked = game.hasClues(choice.requiredClues)
                Button {
                    if unlocked {
                        draft = ""
                        _ = game.choose(choice.id)
                    }
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: unlocked ? "arrow.up.message.fill" : "lock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(unlocked ? Night.accent : Night.muted)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(choice.title)
                                .font(.system(size: 13, weight: .medium))
                                .multilineTextAlignment(.leading)
                            if !unlocked {
                                Text("Inspect the photo and voice message first")
                                    .font(.system(size: 10))
                                    .foregroundColor(Night.muted)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(unlocked ? .white : Night.muted)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Night.raised.opacity(unlocked ? 1 : 0.45), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!unlocked)
                .accessibilityHint(unlocked ? "Sends this reply and continues the story" : "Locked until you inspect both media clues")
            }

            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .foregroundColor(Night.muted)
                TextField("Type a listed reply…", text: $draft, axis: .vertical)
                    .lineLimit(1...3)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.send)
                    .onSubmit { sendTypedReply() }
                Button {
                    sendTypedReply()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 27))
                        .foregroundColor(Night.accent)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Send typed listed reply")
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Night.surface, in: RoundedRectangle(cornerRadius: 23))
        }
        .padding(.horizontal, 13)
        .padding(.top, 13)
        .padding(.bottom, 10)
        .background(Night.background)
        .alert("Choose one of the available replies", isPresented: $showTypedHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The first chapter uses carefully authored choices. Type one of the displayed replies or tap it to continue.")
        }
    }

    private func sendTypedReply() {
        let input = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        let normalized = input.lowercased().filter { $0.isLetter || $0.isNumber }
        if let choice = game.availableChoices.first(where: {
            $0.title.lowercased().filter { $0.isLetter || $0.isNumber } == normalized
        }), game.choose(choice.id) {
            draft = ""
        } else {
            showTypedHelp = true
        }
    }
}

private struct MessageRow: View {
    let message: GameMessage
    @Binding var photoToShow: GameMessage?
    @EnvironmentObject private var game: GameStore
    @State private var showTranscript = false

    var body: some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 45) }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                bubbleContent
                    .padding(message.kind == .text ? 13 : 10)
                    .background(message.isOutgoing ? Night.outgoing : Night.incoming)
                    .clipShape(BubbleShape(outgoing: message.isOutgoing))

                HStack(spacing: 5) {
                    Text(message.createdAt, style: .time)
                    if message.isOutgoing {
                        Text(message.isRead ? "· Read" : "· Delivered")
                    }
                }
                .font(.system(size: 10))
                .foregroundColor(Night.muted)
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: 282, alignment: message.isOutgoing ? .trailing : .leading)

            if !message.isOutgoing { Spacer(minLength: 45) }
        }
        .frame(maxWidth: .infinity)
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.kind {
        case .text:
            Text(message.body)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        case .photograph:
            Button {
                game.inspect(message)
                photoToShow = message
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    EvidencePhoto()
                        .frame(width: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Label("View photo · tap to examine", systemImage: "viewfinder")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Examine hallway photograph")
        case .voiceNote:
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    game.toggleVoice(message)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: game.playingVoiceID == message.id ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 31))
                        VStack(alignment: .leading, spacing: 5) {
                            Image(systemName: "waveform")
                                .font(.system(size: 18))
                            Text("Play voice recording")
                                .font(.system(size: 11))
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(.white)
                    .frame(width: 228)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play or stop fictional voice recording")

                Button {
                    showTranscript.toggle()
                    game.inspect(message)
                } label: {
                    Label(showTranscript ? "Hide transcript" : "Read transcript", systemImage: "text.quote")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.84))
                }
                .buttonStyle(.plain)

                if showTranscript {
                    Text(message.body.replacingOccurrences(of: "Voice message: ", with: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isStaticText)
                }
            }
        case .call:
            Button {
                game.presentedCall = message
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "phone.arrow.down.left.fill")
                        .font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unknown caller")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Answer fictional in-app call")
                            .font(.system(size: 11))
                    }
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(width: 230)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PhotoDetailView: View {
    let message: GameMessage
    @EnvironmentObject private var game: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    EvidencePhoto()
                        .scaleEffect(zoom)
                        .gesture(MagnificationGesture().onChanged { zoom = min(3, max(1, $0)) }
                            .onEnded { _ in withAnimation { zoom = 1 } })
                        .padding(.vertical, 30)
                    SectionEyebrow(text: "Photograph inspected")
                    Text("Look carefully at the reflection.")
                        .font(.system(size: 22, weight: .semibold))
                    Text("The hallway is dark, but a reflection shows a red 07 and a clock frozen at 01:43. The building only has four registered floors.")
                        .font(.system(size: 15))
                        .foregroundColor(Night.muted)
                    Label("Evidence collected", systemImage: "checkmark.seal.fill")
                        .foregroundColor(Night.accent)
                }
                .padding(20)
            }
            .background(Night.background.ignoresSafeArea())
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { game.inspect(message) }
        }
        .preferredColorScheme(.dark)
    }
}

struct FictionalCallView: View {
    let message: GameMessage
    @EnvironmentObject private var game: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var connected = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.18, green: 0.18, blue: 0.24), Night.background],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 17) {
                Spacer()
                SectionEyebrow(text: "Fictional call · Last Seen")
                Text("Unknown Number")
                    .font(.system(size: 31, weight: .semibold))
                Text(connected ? "Connected" : "Incoming call…")
                    .font(.system(size: 15))
                    .foregroundColor(Night.muted)
                Spacer()
                Circle()
                    .fill(Night.danger.opacity(0.18))
                    .frame(width: 160, height: 160)
                    .overlay {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 72))
                            .foregroundColor(.white.opacity(0.8))
                    }
                Spacer()

                if connected {
                    Text("“There is no seventh floor. Stop counting the doors.”")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 25)
                    Button {
                        game.endCall()
                        dismiss()
                    } label: {
                        Label("End call", systemImage: "phone.down.fill")
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Night.danger, in: Capsule())
                    }
                } else {
                    HStack(spacing: 30) {
                        Button {
                            game.declineCall()
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 25))
                                    .frame(width: 74, height: 74)
                                    .background(Night.danger, in: Circle())
                                Text("Decline").font(.system(size: 13))
                            }
                        }
                        Spacer()
                        Button {
                            game.answerCall()
                            connected = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 25))
                                    .frame(width: 74, height: 74)
                                    .background(Color.green.opacity(0.76), in: Circle())
                                Text("Answer").font(.system(size: 13))
                            }
                        }
                    }
                }
                Spacer()
            }
            .foregroundColor(.white)
            .padding(28)
        }
        .interactiveDismissDisabled(connected)
    }
}
