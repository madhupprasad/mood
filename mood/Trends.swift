//
//  Trends.swift
//  mood
//

import SwiftUI
import FoundationModels

// MARK: - Generable schema

@Generable
struct WeeklySummary {
    @Guide(description: "One short sentence capturing the overall emotional tone of the week.")
    let mood: String

    @Guide(description: "Three to four short phrases (2-4 words each) describing recurring themes from the entries.")
    let themes: [String]

    @Guide(description: "A single notable moment, shift, or pattern from the week, described in one sentence.")
    let highlight: String

    @Guide(description: "A gentle, supportive observation or suggestion for the coming week. One to two sentences.")
    let suggestion: String
}

// MARK: - Summarizer service

@MainActor
@Observable
final class WeeklySummarizer {
    enum State {
        case idle
        case loading
        case ready(WeeklySummary)
        case empty
        case unavailable(String)
        case failed(String)
    }

    var state: State = .idle

    func generateIfNeeded(from entries: [MoodEntry]) async {
        if case .idle = state {
            await generate(from: entries)
        }
    }

    func generate(from entries: [MoodEntry]) async {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = entries.filter { $0.date >= weekAgo }

        guard !recent.isEmpty else {
            state = .empty
            return
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(.appleIntelligenceNotEnabled):
            state = .unavailable("Enable Apple Intelligence in System Settings to see weekly summaries.")
            return
        case .unavailable(.modelNotReady):
            state = .unavailable("The on-device model is still downloading. Try again shortly.")
            return
        case .unavailable(.deviceNotEligible):
            state = .unavailable("This Mac doesn't support Apple Intelligence.")
            return
        case .unavailable:
            state = .unavailable("Foundation Models is unavailable on this device.")
            return
        }

        state = .loading

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d 'at' h:mm a"
        let entriesText = recent
            .sorted { $0.date < $1.date }
            .map { entry in "• [\(formatter.string(from: entry.date))] \(entry.mood)" }
            .joined(separator: "\n")

        let instructions = """
            You are a thoughtful journaling companion who helps someone reflect on their week. \
            You read their short mood-tracker entries and produce a brief, warm, perceptive weekly summary. \
            Be specific and grounded in what they actually wrote — don't invent details or feelings they did not express. \
            Be encouraging but not saccharine. Keep responses concise.
            """

        let session = LanguageModelSession(instructions: instructions)

        let prompt = """
            Here are this week's mood entries, in chronological order:

            \(entriesText)

            Reflect on this week.
            """

        do {
            let response = try await session.respond(to: prompt, generating: WeeklySummary.self)
            state = .ready(response.content)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

// MARK: - Trends view

struct TrendsView: View {
    @Environment(\.theme) private var theme
    let entries: [MoodEntry]
    let summarizer: WeeklySummarizer

    private var entriesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.date >= weekAgo }.count
    }

    private var isLoading: Bool {
        if case .loading = summarizer.state { return true }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                content
                Spacer(minLength: 24)
            }
        }
        .task {
            await summarizer.generateIfNeeded(from: entries)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("WEEKLY SUMMARY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.secondary)
            Text("·").foregroundStyle(theme.secondary)
            Text("\(entriesThisWeek) \(entriesThisWeek == 1 ? "entry" : "entries") this week")
                .font(.system(size: 10))
                .foregroundStyle(theme.secondary)
            Spacer()
            Button {
                Task { await summarizer.generate(from: entries) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.secondary)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .help("Regenerate summary")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .overlay(
            Rectangle().fill(theme.line).frame(height: 1),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private var content: some View {
        switch summarizer.state {
        case .idle:
            placeholder("Generating a reflection on your week…")
        case .loading:
            loadingState
        case .ready(let summary):
            summaryCard(summary)
        case .empty:
            placeholder("Log some entries this week to see a summary here.")
        case .unavailable(let msg):
            placeholder(msg)
        case .failed(let msg):
            placeholder("Couldn't generate a summary. \(msg)")
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Reflecting on your week…")
                .font(.system(size: 12))
                .foregroundStyle(theme.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(theme.secondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
    }

    private func summaryCard(_ summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            summarySection(label: "MOOD") {
                Text(summary.mood)
                    .font(.system(size: 16))
                    .lineSpacing(4)
            }

            if !summary.themes.isEmpty {
                summarySection(label: "THEMES") {
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(summary.themes, id: \.self) { themeName in
                            Text(themeName)
                                .font(.system(size: 12))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(theme.selection)
                                )
                                .foregroundStyle(theme.primary)
                        }
                    }
                }
            }

            summarySection(label: "HIGHLIGHT") {
                Text(summary.highlight)
                    .font(.system(size: 13))
                    .lineSpacing(3)
            }

            summarySection(label: "FOR NEXT WEEK") {
                Text(summary.suggestion)
                    .font(.system(size: 13))
                    .italic()
                    .lineSpacing(3)
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private func summarySection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.secondary)
            content()
                .foregroundStyle(theme.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Flow layout for theme chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
