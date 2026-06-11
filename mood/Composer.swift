//
//  Composer.swift
//  mood
//

import SwiftUI

struct Composer: View {
    @Environment(\.theme) private var theme
    @Binding var draft: String
    @Binding var selectedMood: Int?
    let onLog: () -> Void

    @State private var now: Date = Date()
    @State private var transcriber = SpeechTranscriber()
    @State private var draftBeforeRecording: String = ""
    @State private var pttHolding: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(now, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute().second())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.secondary)
                    Text(now, format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.secondary)
                }
                .frame(width: 60, alignment: .leading)

                TextField("What's on your mind right now…", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.primary)
                    .lineLimit(1...5)
                    .onSubmit(onLog)
                    .onKeyPress(.space, phases: .all) { press in
                        handlePushToTalk(press)
                    }

                Button(action: toggleRecording) {
                    Image(systemName: micIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(micColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(transcriber.state == .recording ? Color.red.opacity(0.12) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help(micHelp)
            }

            HStack(spacing: 8) {
                Text("MOOD")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(theme.secondary)
                HStack(spacing: 6) {
                    ForEach(MoodLevel.all, id: \.value) { level in
                        Button {
                            selectedMood = (selectedMood == level.value) ? nil : level.value
                        } label: {
                            HStack(spacing: 5) {
                                moodShape(for: level)
                                    .frame(width: 12, height: 12)
                                Text(level.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(selectedMood == level.value ? level.color : theme.secondary)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(selectedMood == level.value ? level.color.opacity(0.15) : theme.line.opacity(0.4))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedMood == level.value ? level.color.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .help(level.name)
                    }
                }
                Spacer()
                Text(statusText)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondary)
                Button(action: onLog) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up").font(.system(size: 10, weight: .medium))
                        Text("Log").font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.primary)
                    .foregroundStyle(theme.logButtonText)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.leading, 76)
        }
        .padding(24)
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .onChange(of: transcriber.transcript) { _, newValue in
            guard transcriber.state == .recording else { return }
            let separator = draftBeforeRecording.isEmpty ? "" : " "
            draft = draftBeforeRecording + separator + newValue
        }
    }

    private var statusText: String {
        if transcriber.state == .recording { return "Listening…" }
        if transcriber.state == .denied { return "Mic permission needed" }
        if transcriber.state == .unavailable { return "Speech unavailable" }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Nothing to save" }
        let words = trimmed.split { $0.isWhitespace }.count
        return "\(words) word\(words == 1 ? "" : "s") to save"
    }

    private var micIcon: String {
        transcriber.state == .recording ? "stop.circle.fill" : "mic"
    }

    private var micColor: Color {
        switch transcriber.state {
        case .recording: .red
        case .denied, .unavailable: theme.secondary.opacity(0.5)
        case .idle: theme.secondary
        }
    }

    private var micHelp: String {
        switch transcriber.state {
        case .recording: "Stop recording"
        case .denied: "Allow microphone access in System Settings"
        case .unavailable: "Speech recognition unavailable"
        case .idle: "Dictate your entry  (or hold ⌥Space)"
        }
    }

    private func toggleRecording() {
        if transcriber.state == .recording {
            transcriber.stop()
        } else {
            draftBeforeRecording = draft
            Task { await transcriber.start() }
        }
    }

    private func handlePushToTalk(_ press: KeyPress) -> KeyPress.Result {
        if pttHolding {
            if press.phase == .up {
                pttHolding = false
                transcriber.stop()
            }
            return .handled
        }
        if press.phase == .down && press.modifiers.contains(.option) {
            pttHolding = true
            draftBeforeRecording = draft
            Task { await transcriber.start() }
            return .handled
        }
        return .ignored
    }

    @ViewBuilder
    private func moodShape(for level: MoodLevel) -> some View {
        let active = selectedMood == level.value
        let color: Color = active ? level.color : theme.primary
        let size: CGFloat = 8
        Group {
            switch level.value {
            case 5: Triangle().fill(color).frame(width: size + 1, height: size)
            case 4: Circle().fill(color).frame(width: size, height: size)
            case 3: Rectangle().fill(color).frame(width: size, height: size)
            case 2: Triangle().fill(color).frame(width: size + 1, height: size).rotationEffect(.degrees(180))
            case 1: Circle().stroke(color, lineWidth: 1.2).frame(width: size, height: size)
            default: EmptyView()
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
