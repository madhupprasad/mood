//
//  Games.swift
//  mood
//
//  A small games tab. Starts with Snake. The plan is to rotate a featured
//  game weekly/monthly — for now there's just the one.
//

import SwiftUI

// MARK: - Games tab

struct GamesView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                SnakeGameCard()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)
            .padding(.bottom, 34)
        }
        .background(theme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("GAMES")
                .font(.system(size: 12, weight: .bold))
                .tracking(2.4)
                .foregroundStyle(theme.secondary)
            Text("A little breather between entries.")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(theme.secondary)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Snake

private struct SnakeGameCard: View {
    @Environment(\.theme) private var theme

    private static let gridSize = 20
    private static let initialSpeed: Double = 0.18

    @State private var snake: [Point] = [Point(x: 10, y: 10)]
    @State private var direction: Direction = .right
    @State private var queuedDirection: Direction? = nil
    @State private var food: Point = Point(x: 5, y: 5)
    @State private var score: Int = 0
    @State private var phase: Phase = .idle
    @State private var tickTask: Task<Void, Never>? = nil
    @FocusState private var focused: Bool

    @AppStorage("snakeHighScore") private var highScore: Int = 0

    private enum Phase: Equatable {
        case idle, playing, gameOver
    }

    private enum Direction: Equatable {
        case up, down, left, right
        var delta: Point {
            switch self {
            case .up:    Point(x: 0, y: -1)
            case .down:  Point(x: 0, y: 1)
            case .left:  Point(x: -1, y: 0)
            case .right: Point(x: 1, y: 0)
            }
        }
        var opposite: Direction {
            switch self {
            case .up:    .down
            case .down:  .up
            case .left:  .right
            case .right: .left
            }
        }
    }

    private struct Point: Equatable, Hashable {
        let x: Int
        let y: Int
        static func + (a: Point, b: Point) -> Point { Point(x: a.x + b.x, y: a.y + b.y) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Snake")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Spacer()
                Text("Score \(score)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.secondary)
                Text("·").foregroundStyle(theme.secondary)
                Text("Best \(highScore)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.secondary)
            }

            board

            Text("Arrow keys or WASD to move. Click the board if keys don't respond.")
                .font(.system(size: 11))
                .foregroundStyle(theme.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(theme.line, lineWidth: 1)
        )
        .onDisappear {
            tickTask?.cancel()
            tickTask = nil
        }
    }

    private var board: some View {
        ZStack {
            Canvas { ctx, size in
                let cellPx = size.width / CGFloat(Self.gridSize)

                // Food
                let foodRect = CGRect(
                    x: CGFloat(food.x) * cellPx + 1,
                    y: CGFloat(food.y) * cellPx + 1,
                    width:  cellPx - 2,
                    height: cellPx - 2
                )
                ctx.fill(Path(roundedRect: foodRect, cornerRadius: 3),
                         with: .color(theme.accent))

                // Snake (head brightest, tail faded)
                for (i, cell) in snake.enumerated() {
                    let fade = max(0.35, 1.0 - Double(i) * 0.04)
                    let rect = CGRect(
                        x: CGFloat(cell.x) * cellPx + 1,
                        y: CGFloat(cell.y) * cellPx + 1,
                        width:  cellPx - 2,
                        height: cellPx - 2
                    )
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 3),
                             with: .color(theme.primary.opacity(fade)))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 380)
            .background(
                Rectangle().fill(theme.background.opacity(0.6))
            )
            .overlay(
                Rectangle().stroke(theme.line, lineWidth: 1)
            )

            overlay
        }
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear { focused = true }
        .onTapGesture { focused = true }
        .onKeyPress(phases: .down) { press in
            handleKey(press)
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch phase {
        case .idle:
            VStack(spacing: 10) {
                Text("Snake")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Button("Start") { start() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(theme.line, lineWidth: 1)
            )

        case .gameOver:
            VStack(spacing: 8) {
                Text("Game over")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Text("You scored \(score). Best \(highScore).")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.secondary)
                Button("Play again") { start() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                    .padding(.top, 4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(theme.line, lineWidth: 1)
            )

        case .playing:
            EmptyView()
        }
    }

    // MARK: - Game loop

    private func start() {
        tickTask?.cancel()
        snake = [Point(x: 10, y: 10), Point(x: 9, y: 10), Point(x: 8, y: 10)]
        direction = .right
        queuedDirection = nil
        food = newFood()
        score = 0
        phase = .playing
        focused = true

        tickTask = Task { @MainActor in
            while !Task.isCancelled, phase == .playing {
                try? await Task.sleep(for: .seconds(currentSpeed))
                if Task.isCancelled { return }
                tick()
            }
        }
    }

    private func tick() {
        guard phase == .playing else { return }

        if let queued = queuedDirection, queued != direction.opposite {
            direction = queued
        }
        queuedDirection = nil

        let head = snake[0]
        let next = head + direction.delta

        // Walls
        if next.x < 0 || next.x >= Self.gridSize || next.y < 0 || next.y >= Self.gridSize {
            gameOver()
            return
        }

        // Self (allow moving into the current tail position, since the tail moves off)
        let movingIntoOwnTail = snake.count > 1 && next == snake.last && next != food
        if !movingIntoOwnTail, snake.contains(next) {
            gameOver()
            return
        }

        snake.insert(next, at: 0)
        if next == food {
            score += 1
            food = newFood()
        } else {
            snake.removeLast()
        }
    }

    private func gameOver() {
        phase = .gameOver
        tickTask?.cancel()
        tickTask = nil
        if score > highScore { highScore = score }
    }

    private func newFood() -> Point {
        var p: Point
        repeat {
            p = Point(x: Int.random(in: 0..<Self.gridSize),
                      y: Int.random(in: 0..<Self.gridSize))
        } while snake.contains(p)
        return p
    }

    private var currentSpeed: Double {
        max(0.06, Self.initialSpeed - Double(score) * 0.005)
    }

    // MARK: - Input

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        let dir: Direction?
        switch press.key {
        case .upArrow:    dir = .up
        case .downArrow:  dir = .down
        case .leftArrow:  dir = .left
        case .rightArrow: dir = .right
        default:
            switch press.characters.lowercased() {
            case "w": dir = .up
            case "s": dir = .down
            case "a": dir = .left
            case "d": dir = .right
            default:  dir = nil
            }
        }
        guard let dir else { return .ignored }
        if dir != direction.opposite { queuedDirection = dir }
        return .handled
    }
}
