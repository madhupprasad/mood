//
//  Chat.swift
//  mood
//
//  "Chat with your past" — a supportive on-device chatbot that reads recent
//  journal entries as context and converses about them in plain string mode
//  with permissive guardrails. Conversation lives in memory only.
//

import SwiftUI
import FoundationModels

// MARK: - Message

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant, system }

    let id = UUID()
    let role: Role
    let text: String
    let date: Date

    init(role: Role, text: String, date: Date = Date()) {
        self.role = role
        self.text = text
        self.date = date
    }
}

// MARK: - Service

@MainActor
@Observable
final class ChatService {
    enum State {
        case idle
        case thinking
        case unavailable(String)
    }

    var messages: [ChatMessage] = []
    var state: State = .idle

    private var session: LanguageModelSession?
    private var contextEntryIDs: Set<UUID> = []

    private static let contextWindowDays = 60

    func send(_ text: String, entries: [MoodEntry]) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if case .thinking = state { return }

        // Lazy session init
        if session == nil {
            switch ensureSession(with: entries) {
            case .success: break
            case .failure(let reason):
                state = .unavailable(reason)
                return
            }
        }

        messages.append(ChatMessage(role: .user, text: trimmed))
        state = .thinking

        do {
            let response = try await session!.respond(to: trimmed)
            let replyText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            messages.append(ChatMessage(role: .assistant, text: replyText))
            state = .idle
        } catch {
            messages.append(ChatMessage(
                role: .assistant,
                text: "I can't reply to this one — want to try a different way to ask?"
            ))
            state = .idle
        }
    }

    func reset() {
        session = nil
        messages = []
        contextEntryIDs = []
        state = .idle
    }

    // MARK: - Session setup

    private enum SessionResult {
        case success
        case failure(String)
    }

    private func ensureSession(with entries: [MoodEntry]) -> SessionResult {
        let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)

        switch model.availability {
        case .available: break
        case .unavailable(.appleIntelligenceNotEnabled):
            return .failure("Enable Apple Intelligence in System Settings to chat with your past.")
        case .unavailable(.modelNotReady):
            return .failure("The on-device model is still downloading. Try again shortly.")
        case .unavailable(.deviceNotEligible):
            return .failure("This Mac doesn't support Apple Intelligence.")
        case .unavailable:
            return .failure("Foundation Models is unavailable on this device.")
        }

        let context = buildContext(from: entries)
        contextEntryIDs = Set(context.usedEntries.map { $0.id })

        let instructions = """
            You are a warm, supportive, and curious companion. You have read the user's recent personal \
            journal entries, included below. The user is using a private journaling app to talk through \
            how they're feeling. Your job is to listen, reflect back what you notice with care, ask gentle \
            questions, and help them think — not to give clinical advice or diagnoses. \
            Be human. Speak naturally and briefly. Reference specific entries by date or content only when \
            it's clearly useful. Never lecture or moralize. Never invent details that aren't in the entries. \
            If you don't have enough to say, say so honestly and ask a small question. \
            If a topic feels heavy, acknowledge it simply ("that sounds hard") and invite them to share more.

            RECENT ENTRIES (newest first):
            \(context.formattedEntries)
            """

        session = LanguageModelSession(
            model: model,
            tools: [],
            instructions: instructions
        )
        return .success
    }

    private struct Context {
        let formattedEntries: String
        let usedEntries: [MoodEntry]
    }

    private func buildContext(from entries: [MoodEntry]) -> Context {
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.contextWindowDays, to: Date()) ?? Date()
        let recent = entries
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }
            .prefix(120) // hard cap on entries fed in

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"

        let lines = recent.map { entry -> String in
            let when = formatter.string(from: entry.date)
            let moodTag: String
            if let v = entry.moodValue,
               let level = MoodLevel.all.first(where: { $0.value == v }) {
                moodTag = " | \(level.name)"
            } else {
                moodTag = ""
            }
            let emoTag = entry.emotions.isEmpty ? "" : " · \(entry.emotions.joined(separator: ", "))"
            let body = entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)
            return "[\(when)\(moodTag)\(emoTag)] \(body.isEmpty ? "(no note)" : body)"
        }

        return Context(
            formattedEntries: lines.joined(separator: "\n"),
            usedEntries: Array(recent)
        )
    }
}

// MARK: - View

struct ChatView: View {
    @Environment(\.theme) private var theme
    let entries: [MoodEntry]
    let service: ChatService

    @State private var input: String = ""
    @FocusState private var inputFocused: Bool

    private var isThinking: Bool {
        if case .thinking = service.state { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            transcript
            inputBar
        }
        .background(theme.background)
        .onAppear {
            inputFocused = true
        }
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 11))
                .foregroundStyle(theme.accent)
            Text("CHAT WITH YOUR PAST")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.secondary)
            Spacer()
            if !service.messages.isEmpty {
                Button {
                    service.reset()
                    inputFocused = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("New conversation")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(theme.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear and start over")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .overlay(
            Rectangle().fill(theme.line).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if case .unavailable(let msg) = service.state {
                        unavailableState(msg)
                    } else if service.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(service.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }

                    if isThinking {
                        ThinkingIndicator()
                            .id("thinking")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
            }
            .onChange(of: service.messages.count) {
                if let last = service.messages.last {
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isThinking) {
                if isThinking {
                    withAnimation { proxy.scrollTo("thinking", anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hey — I've read your last \(min(Self.contextWindowDays, recentCount)) days of entries.")
                .font(.system(size: 14))
                .foregroundStyle(theme.primary)
            Text("Tell me how you're feeling, or ask me about something you've been writing about.")
                .font(.system(size: 13))
                .foregroundStyle(theme.secondary)
        }
        .padding(.vertical, 8)
    }

    private static let contextWindowDays = 60
    private var recentCount: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.contextWindowDays, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoff }.count
    }

    private func unavailableState(_ msg: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles.slash")
                Text("Chat unavailable")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(theme.primary)
            Text(msg)
                .font(.system(size: 12))
                .foregroundStyle(theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(theme.line, lineWidth: 1)
        )
    }

    // MARK: input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(theme.line).frame(height: 1)

            HStack(alignment: .bottom, spacing: 10) {
                TextField(
                    "Type a message…",
                    text: $input,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(theme.primary)
                .lineLimit(1...4)
                .focused($inputFocused)
                .onSubmit(submit)

                Button(action: submit) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.logButtonText)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle().fill(canSend ? theme.primary : theme.secondary.opacity(0.4))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(theme.card)
    }

    private var canSend: Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !isThinking
    }

    private func submit() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        input = ""
        Task {
            await service.send(text, entries: entries)
        }
    }
}

// MARK: - Message bubble

private struct MessageBubble: View {
    @Environment(\.theme) private var theme
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(message.role == .user ? theme.logButtonText : theme.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(message.role == .user ? theme.primary : theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(message.role == .user ? Color.clear : theme.line, lineWidth: 1)
                )
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

private struct ThinkingIndicator: View {
    @Environment(\.theme) private var theme
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(theme.secondary)
                    .frame(width: 5, height: 5)
                    .opacity(phase == i ? 1 : 0.35)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.line, lineWidth: 1)
        )
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(450))
                phase = (phase + 1) % 3
            }
        }
    }
}
