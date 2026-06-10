//
//  Sidebar.swift
//  mood
//

import SwiftUI

// MARK: - Sidebar model

enum SidebarSection: Hashable, CaseIterable {
    case allEntries, today, calendar, trends

    var title: String {
        switch self {
        case .allEntries: "All Entries"
        case .today: "Today"
        case .calendar: "Calendar"
        case .trends: "Trends"
        }
    }

    var icon: String {
        switch self {
        case .allEntries: "circle.fill"
        case .today: "sun.max"
        case .calendar: "calendar"
        case .trends: "chart.line.uptrend.xyaxis"
        }
    }
}

enum SidebarFilter: Hashable {
    case section(SidebarSection)
    case tag(String)
}

// MARK: - Sidebar view

struct Sidebar: View {
    @Environment(\.theme) private var theme
    @Binding var filter: SidebarFilter
    @Binding var calendarDate: Date
    @Binding var themeID: String
    let allTags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "LIBRARY", trailing: nil)

            ForEach(SidebarSection.allCases, id: \.self) { section in
                SidebarRow(
                    title: section.title,
                    icon: section.icon,
                    selected: filter == .section(section)
                ) {
                    filter = .section(section)
                }

                if section == .calendar && filter == .section(.calendar) {
                    MiniCalendar(selected: $calendarDate)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                        .padding(.bottom, 10)
                }
            }

            SectionHeader(title: "TAGS", trailing: allTags.isEmpty ? nil : "\(allTags.count)")

            if allTags.isEmpty {
                Text("Type #tags in your entries")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            } else {
                ForEach(allTags, id: \.self) { tag in
                    Button {
                        filter = .tag(tag)
                    } label: {
                        HStack(spacing: 10) {
                            Circle().fill(colorForTag(tag)).frame(width: 7, height: 7)
                            Text(tag)
                                .font(.system(size: 12))
                                .foregroundStyle(theme.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                        .background(filter == .tag(tag) ? theme.selection : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            ThemePicker(themeID: $themeID)
        }
        .background(theme.sidebar)
    }
}

// MARK: - Section header / row

private struct SectionHeader: View {
    @Environment(\.theme) private var theme
    let title: String
    let trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.secondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

private struct SidebarRow: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.primary)
                    .frame(width: 12)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(selected ? theme.selection : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme picker

private struct ThemePicker: View {
    @Environment(\.theme) private var theme
    @Binding var themeID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("THEME")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(theme.secondary)
                Spacer()
                Text(theme.name)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondary)
            }
            HStack(spacing: 10) {
                ForEach(ThemeCatalog.all) { candidate in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            themeID = candidate.id
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(theme.primary, lineWidth: 1.5)
                                .padding(-3)
                                .opacity(themeID == candidate.id ? 1 : 0)

                            Circle()
                                .fill(candidate.background)
                                .overlay(
                                    Circle()
                                        .trim(from: 0.5, to: 1.0)
                                        .fill(candidate.accent)
                                        .rotationEffect(.degrees(-90))
                                )
                                .overlay(Circle().stroke(candidate.primary.opacity(0.3), lineWidth: 0.8))
                                .frame(width: 22, height: 22)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(candidate.name)
                }
                Spacer()
            }
        }
        .padding(16)
        .overlay(
            Rectangle().fill(theme.line).frame(height: 1),
            alignment: .top
        )
    }
}
