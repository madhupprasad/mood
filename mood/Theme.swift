//
//  Theme.swift
//  mood
//

import SwiftUI

struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let background: Color
    let sidebar: Color
    let selection: Color
    let primary: Color
    let secondary: Color
    let line: Color
    let accent: Color
    let logButtonText: Color
    let isDark: Bool
}

enum ThemeCatalog {
    static let cream = Theme(
        id: "cream",
        name: "Cream",
        background: Color(red: 0.97, green: 0.96, blue: 0.93),
        sidebar: Color(red: 0.94, green: 0.93, blue: 0.89),
        selection: Color(red: 0.90, green: 0.88, blue: 0.83),
        primary: Color(red: 0.18, green: 0.17, blue: 0.16),
        secondary: Color(red: 0.55, green: 0.53, blue: 0.49),
        line: Color(red: 0.87, green: 0.85, blue: 0.81),
        accent: Color(red: 0.48, green: 0.66, blue: 0.45),
        logButtonText: .white,
        isDark: false
    )

    static let slate = Theme(
        id: "slate",
        name: "Slate",
        background: Color(red: 0.11, green: 0.12, blue: 0.13),
        sidebar: Color(red: 0.14, green: 0.15, blue: 0.17),
        selection: Color(red: 0.20, green: 0.22, blue: 0.25),
        primary: Color(red: 0.91, green: 0.90, blue: 0.87),
        secondary: Color(red: 0.55, green: 0.55, blue: 0.53),
        line: Color(red: 0.19, green: 0.20, blue: 0.22),
        accent: Color(red: 0.58, green: 0.78, blue: 0.55),
        logButtonText: Color(red: 0.11, green: 0.12, blue: 0.13),
        isDark: true
    )

    static let sky = Theme(
        id: "sky",
        name: "Sky",
        background: Color(red: 0.96, green: 0.97, blue: 0.99),
        sidebar: Color(red: 0.90, green: 0.93, blue: 0.96),
        selection: Color(red: 0.82, green: 0.87, blue: 0.93),
        primary: Color(red: 0.12, green: 0.17, blue: 0.23),
        secondary: Color(red: 0.42, green: 0.49, blue: 0.57),
        line: Color(red: 0.80, green: 0.85, blue: 0.90),
        accent: Color(red: 0.34, green: 0.55, blue: 0.85),
        logButtonText: .white,
        isDark: false
    )

    static let lavender = Theme(
        id: "lavender",
        name: "Lavender",
        background: Color(red: 0.96, green: 0.95, blue: 0.97),
        sidebar: Color(red: 0.92, green: 0.90, blue: 0.94),
        selection: Color(red: 0.85, green: 0.82, blue: 0.89),
        primary: Color(red: 0.20, green: 0.16, blue: 0.26),
        secondary: Color(red: 0.50, green: 0.45, blue: 0.55),
        line: Color(red: 0.84, green: 0.81, blue: 0.87),
        accent: Color(red: 0.59, green: 0.42, blue: 0.78),
        logButtonText: .white,
        isDark: false
    )

    static let solar = Theme(
        id: "solar",
        name: "Solar",
        background: Color(red: 0.98, green: 0.95, blue: 0.91),
        sidebar: Color(red: 0.95, green: 0.91, blue: 0.83),
        selection: Color(red: 0.91, green: 0.85, blue: 0.73),
        primary: Color(red: 0.18, green: 0.14, blue: 0.09),
        secondary: Color(red: 0.58, green: 0.52, blue: 0.41),
        line: Color(red: 0.86, green: 0.78, blue: 0.62),
        accent: Color(red: 0.89, green: 0.52, blue: 0.29),
        logButtonText: .white,
        isDark: false
    )

    static let all: [Theme] = [cream, slate, sky, lavender, solar]

    static func theme(forID id: String) -> Theme {
        all.first(where: { $0.id == id }) ?? cream
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = ThemeCatalog.cream
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
