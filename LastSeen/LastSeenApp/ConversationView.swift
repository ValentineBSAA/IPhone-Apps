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
                        TimelineView(.periodic(from: .now, by: 20)) { clock in
                            Text(clock.date, format: .dateTime.weekday(.wide).month(.abbreviated).day().hour().minute())
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .tracking(1.2)
                                .foregroundColor(Night.muted)
                        }
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

                        if game.state.endingID != nil && game.state.activeThread == contact.id {
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
                    game.selectStory(contact)
                    game.markThreadRead(contact.id)
                    if let pending = game.notificationDraft { draft = pending }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            Divider().overlay(.white.opacity(0.07))

            if game.state.endingID != nil {
                footerNote("Story complete. Return to your inbox to replay.")
            } else if game.state.choiceReady {
                choiceComposer
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
                NavigationLink(value: AppPage.profile(contact, true)) {
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
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $photoToShow) { photo in
            PhotoDetailView(message: photo)
                .environmentObject(game)
        }
        .onChange(of: game.notificationDraft) { text in
            if let text { draft = text }
        }
        .onDisappear {
            game.closeConversation(contact)
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
                        game.clearDraft()
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
                                Text("Inspect the photo and voice-note transcript first")
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
            game.clearDraft()
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
                    StoryPhotograph(assetName: message.photoAssetName)
                        .frame(width: 240, height: 268)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Label("View photo · tap to examine", systemImage: "viewfinder")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open story photograph")
        case .voiceNote:
            VStack(alignment: .leading, spacing: 9) {
                Label("Voice note · transcript", systemImage: "text.quote")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Button {
                    showTranscript.toggle()
                    game.inspect(message)
                } label: {
                    Label(showTranscript ? "Hide transcript" : "Read transcript", systemImage: "doc.text")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                if showTranscript {
                    Text(message.body.replacingOccurrences(of: "Voice message: ", with: ""))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Recorded dialogue is not available yet.")
                        .font(.system(size: 11))
                        .foregroundColor(Night.muted)
                }
            }
        case .call:
            Label("Call record · audio unavailable", systemImage: "phone.down")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.82))

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
                    StoryPhotograph(assetName: message.photoAssetName, fit: true)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(zoom)
                        .gesture(MagnificationGesture().onChanged { zoom = min(3, max(1, $0)) }
                            .onEnded { _ in withAnimation { zoom = 1 } })
                        .padding(.vertical, 18)
                    SectionEyebrow(text: "Photograph inspected")
                    Text(message.body)
                        .font(.system(size: 22, weight: .semibold))
                    Text(StoryPhotoCatalog.labels[message.photoAssetName ?? ""] ?? "Inspect this photograph for details that might matter later.")
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

