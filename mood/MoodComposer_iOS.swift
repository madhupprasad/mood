//
//  MoodComposer_iOS.swift
//  mood
//
//  iOS-only Daylio-style composer: mood is the hero (required), note is
//  optional. Logging keeps you on the Write tab and clears in place.
//

#if os(iOS)

import SwiftUI

struct MoodComposer_iOS: View {
    @Environment(\.theme) private var theme
    @Binding var draft: String
    @Binding var selectedMood: Int?
    let onLog: () -> Void

    @State private var now: Date = Date()
    @State private var transcriber = SpeechTranscriber()
    @State private var draftBeforeRecording: String = ""
    @State private var showVent: Bool = false
    @FocusState private var noteFocused: Bool

    private var canLog: Bool { selectedMood != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                moodPicker
                noteField
                logRow
                ventLink
            }
            .padding(20)
        }
        .background(theme.background)
        .scrollDismissesKeyboard(.interactively)
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(theme.secondary)
            Text("how are you, right now?")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(theme.primary)
        }
        .padding(.top, 8)
    }

    // MARK: - Mood picker (the hero)

    private var moodPicker: some View {
        HStack(spacing: 0) {
            ForEach(MoodLevel.all.sorted { $0.value > $1.value }, id: \.value) { level in
                let active = selectedMood == level.value
                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        selectedMood = active ? nil : level.value
                    }
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(active ? level.color.opacity(0.22) : theme.line.opacity(0.4))
                                .frame(width: 52, height: 52)
                            Circle()
                                .stroke(active ? level.color : Color.clear, lineWidth: 2)
                                .frame(width: 52, height: 52)
                            moodShape(for: level, active: active)
                                .frame(width: 22, height: 22)
                        }
                        Text(level.name)
                            .font(.system(size: 11, weight: active ? .semibold : .regular))
                            .foregroundStyle(active ? level.color : theme.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Note field

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .topLeading) {
                if draft.isEmpty {
                    Text("a few words, if you want…")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.secondary.opacity(0.7))
                        .padding(.top, 14)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }
                HStack(alignment: .bottom, spacing: 10) {
                    TextField("", text: $draft, axis: .vertical)
                        .focused($noteFocused)
                        .font(.system(size: 16))
                        .foregroundStyle(theme.primary)
                        .lineLimit(1...8)
                        .padding(14)

                    Button(action: toggleRecording) {
                        Image(systemName: micIcon)
                            .font(.system(size: 17))
                            .foregroundStyle(micColor)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(transcriber.state == .recording ? Color.red.opacity(0.12) : theme.line.opacity(0.4))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14).fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(theme.line, lineWidth: 0.5)
            )

            Text(noteHint)
                .font(.system(size: 11))
                .foregroundStyle(theme.secondary.opacity(0.85))
                .padding(.leading, 2)
        }
    }

    private var noteHint: String {
        switch transcriber.state {
        case .recording: "Listening…"
        case .denied: "Mic permission needed — enable it in Settings"
        case .unavailable: "Speech recognition unavailable"
        case .idle: "a note is optional — pick a mood and tap Log to keep just that"
        }
    }

    // MARK: - Log row

    private var logRow: some View {
        HStack(spacing: 12) {
            Button(action: { noteFocused = false; onLog() }) {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.up").font(.system(size: 15, weight: .semibold))
                    Text("Log").font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canLog ? theme.primary : theme.line)
                .foregroundStyle(canLog ? theme.logButtonText : theme.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!canLog)

            Button { showVent = true } label: {
                Image(systemName: "flame")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.84, green: 0.36, blue: 0.36))
                    .frame(width: 50, height: 50)
                    .background(theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.line, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var ventLink: some View {
        EmptyView()
    }

    // MARK: - Mic

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

    private func toggleRecording() {
        if transcriber.state == .recording {
            transcriber.stop()
        } else {
            draftBeforeRecording = draft
            Task { await transcriber.start() }
        }
    }

    // MARK: - Mood shapes (sized up from the Mac composer's vocabulary)

    @ViewBuilder
    private func moodShape(for level: MoodLevel, active: Bool) -> some View {
        let color: Color = active ? level.color : theme.primary.opacity(0.7)
        let size: CGFloat = 18
        Group {
            switch level.value {
            case 5: TriangleShape().fill(color).frame(width: size + 2, height: size)
            case 4: Circle().fill(color).frame(width: size, height: size)
            case 3: RoundedRectangle(cornerRadius: 2).fill(color).frame(width: size, height: size)
            case 2: TriangleShape().fill(color).frame(width: size + 2, height: size).rotationEffect(.degrees(180))
            case 1: Circle().stroke(color, lineWidth: 2).frame(width: size, height: size)
            default: EmptyView()
            }
        }
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#endif
