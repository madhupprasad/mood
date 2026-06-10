//
//  MiniCalendar.swift
//  mood
//

import SwiftUI

struct MiniCalendar: View {
    @Environment(\.theme) private var theme
    @Binding var selected: Date
    @State private var month: Date = Date()

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Spacer()
                navButton(systemImage: "chevron.left") { shiftMonth(-1) }
                navButton(systemImage: "chevron.right") { shiftMonth(1) }
            }

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 2) {
                ForEach(0..<numberOfRows, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { col in
                            let index = row * 7 + col
                            cell(at: index)
                        }
                    }
                }
            }
        }
    }

    private func navButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(theme.secondary)
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
    }

    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols.map { String($0.prefix(2)) }
    }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
    }

    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return weekday - calendar.firstWeekday
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    private var numberOfRows: Int {
        Int(ceil(Double(leadingBlanks + daysInMonth) / 7.0))
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        let dayIndex = index - leadingBlanks
        if dayIndex < 0 || dayIndex >= daysInMonth {
            Text("")
                .frame(maxWidth: .infinity, minHeight: 20)
        } else {
            let date = calendar.date(byAdding: .day, value: dayIndex, to: monthStart) ?? monthStart
            let isSelected = calendar.isDate(date, inSameDayAs: selected)
            let isToday = calendar.isDateInToday(date)

            Button {
                selected = date
            } label: {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(isSelected ? theme.logButtonText : theme.primary)
                    .frame(maxWidth: .infinity, minHeight: 20)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 4).fill(theme.primary)
                            } else if isToday {
                                RoundedRectangle(cornerRadius: 4).stroke(theme.primary.opacity(0.35), lineWidth: 1)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func shiftMonth(_ delta: Int) {
        month = calendar.date(byAdding: .month, value: delta, to: month) ?? month
    }
}
