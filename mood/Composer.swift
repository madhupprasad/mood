//
//  Composer.swift
//  mood
//

import SwiftUI

struct Composer: View {
    @Environment(\.theme) private var theme
    @Binding var draft: String
    @Binding var selectedMood: Int?
    @Binding var selectedEmotions: Set<String>
    let onLog: () -> Void

    @State private var now: Date = Date()
    @State private var transcriber = SpeechTranscriber()
    @State private var draftBeforeRecording: String = ""
    @State private var pttHolding: Bool = false
    @State private var showVent: Bool = false

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
                            let newValue = (selectedMood == level.value) ? nil : level.value
                            // Feelings are specific to a mood level, so switching
                            // (or clearing) the mood clears any chosen feelings.
                            if newValue != selectedMood { selectedEmotions = [] }
                            selectedMood = newValue
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

            // Optional feeling chips — only appear once a mood is chosen, and
            // are scoped to that mood level. Name it if you want; skip it freely.
            if let mv = selectedMood, let level = MoodLevel.all.first(where: { $0.value == mv }) {
                HStack(spacing: 6) {
                    Text("FEELING")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(theme.secondary)
                    ForEach(MoodLevel.emotions(for: mv), id: \.self) { emotion in
                        let on = selectedEmotions.contains(emotion)
                        Button {
                            if on { selectedEmotions.remove(emotion) } else { selectedEmotions.insert(emotion) }
                        } label: {
                            Text(emotion)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(on ? level.color : theme.secondary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule().fill(on ? level.color.opacity(0.15) : theme.line.opacity(0.4))
                                )
                                .overlay(
                                    Capsule().stroke(on ? level.color.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.leading, 76)
            }

            Button { showVent = true } label: {
                Text("or vent something you don't want to keep")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.secondary.opacity(0.85))
                    .underline(true, color: theme.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
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
        .sheet(isPresented: $showVent) {
            VentSheet { showVent = false }
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

// MARK: - Vent sheet
//
// A small private space to write something out you don't want to save.
// Nothing is persisted to disk. "Burn it" clears and closes; closing the
// sheet via Esc or × also drops the text.

struct VentSheet: View {
    @Environment(\.theme) private var theme
    let onClose: () -> Void

    @State private var text: String = ""
    @State private var burning: Bool = false
    @FocusState private var focused: Bool

    private static let ember = Color(red: 0.93, green: 0.45, blue: 0.18)
    private static let deepRed = Color(red: 0.62, green: 0.18, blue: 0.10)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(burning ? "let it go." : "Write it out. Nothing here is saved.")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.secondary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .opacity(burning ? 0 : 1)
            }

            editor

            HStack {
                Spacer()
                Button(action: burnIt) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                        Text("Burn it")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(red: 0.84, green: 0.36, blue: 0.36))
                    )
                }
                .buttonStyle(.plain)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || burning)
                .opacity(canBurn ? 1 : 0.5)
            }
            .opacity(burning ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: burning)
        }
        .padding(22)
        #if os(macOS)
        .frame(width: 520, height: 380)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
        .background(theme.card)
        .onAppear {
            DispatchQueue.main.async { focused = true }
        }
    }

    private var canBurn: Bool {
        !burning && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var editor: some View {
        ZStack(alignment: .bottom) {
            TextEditor(text: $text)
                .focused($focused)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .padding(10)
                .foregroundStyle(burning ? Self.ember : theme.primary)
                .opacity(burning ? 0 : 1)
                .offset(y: burning ? -28 : 0)
                .blur(radius: burning ? 1.5 : 0)
                .animation(.easeOut(duration: 0.9), value: burning)
                .disabled(burning)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(theme.background.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(burning ? Self.deepRed.opacity(0.6) : theme.line, lineWidth: 1)
                )
                .frame(minHeight: 240)

            if burning { flames }
        }
        .frame(minHeight: 240)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var flames: some View {
        ZStack {
            // Fire glow climbing from the bottom
            LinearGradient(
                colors: [
                    Self.deepRed.opacity(0.0),
                    Self.deepRed.opacity(0.35),
                    Self.ember.opacity(0.55),
                    Color.yellow.opacity(0.20),
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .opacity(burning ? 1 : 0)
            .mask(
                Rectangle()
                    .frame(height: burning ? 240 : 0)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            )
            .animation(.easeOut(duration: 0.9), value: burning)

            // Rising flame symbols at the base
            HStack(spacing: 28) {
                ForEach(0..<6, id: \.self) { i in
                    FlamePuff(index: i)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 10)
            .allowsHitTesting(false)
        }
    }

    private func burnIt() {
        guard canBurn else { return }
        focused = false
        #if os(macOS)
        BurnSoundPlayer.shared.play()
        #endif
        withAnimation(.easeOut(duration: 0.6)) { burning = true }

        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            text = ""
            onClose()
        }
    }
}

private struct FlamePuff: View {
    let index: Int
    @State private var fired: Bool = false

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 28, weight: .bold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                Color(red: 0.96, green: 0.78, blue: 0.30),
                Color(red: 0.84, green: 0.32, blue: 0.18)
            )
            .scaleEffect(fired ? CGFloat.random(in: 1.05...1.35) : 0.3, anchor: .bottom)
            .offset(y: fired ? -CGFloat.random(in: 60...180) : 12)
            .opacity(fired ? 0 : 1)
            .blur(radius: fired ? 1.2 : 0)
            .animation(
                .easeOut(duration: Double.random(in: 0.95...1.4))
                    .delay(Double(index) * 0.06),
                value: fired
            )
            .onAppear {
                // Kick the animation in on next runloop tick so SwiftUI captures the from-state.
                DispatchQueue.main.async { fired = true }
            }
    }
}
