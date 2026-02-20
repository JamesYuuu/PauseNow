import Foundation

enum MenuBarTextFormatter {
    static let idleText = "休息中"

    static func runningText(remaining: TimeInterval) -> String {
        format(remaining)
    }

    static func pausedText(remaining: TimeInterval) -> String {
        "已暂停 \(format(remaining))"
    }

    private static func format(_ remaining: TimeInterval) -> String {
        let seconds = max(0, Int(remaining.rounded(.down)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

enum MenuBarDisplayState {
    case idle
    case running(remaining: TimeInterval)
    case paused(remaining: TimeInterval)
}

struct HomeDisplayModel {
    let remainingText: String
    let sandProgress: Double
    let isFlowing: Bool
}

struct DisplaySnapshot {
    let menuBarState: MenuBarDisplayState
    let home: HomeDisplayModel
}

enum ReminderDisplayMapper {
    static func build(
        runtimeState: ReminderRuntimeState,
        nextDueDate: Date?,
        pausedRemaining: TimeInterval?,
        settings: AppSettings,
        now: Date = Date()
    ) -> DisplaySnapshot {
        let totalDuration = TimeInterval(max(1, settings.eyeBreakIntervalMinutes) * 60)
        let runningRemaining = max(0, (nextDueDate ?? now).timeIntervalSince(now))

        let remaining: TimeInterval
        let menuBarState: MenuBarDisplayState
        let isFlowing: Bool

        switch runtimeState {
        case .stopped:
            remaining = totalDuration
            menuBarState = .idle
            isFlowing = false
        case .running:
            remaining = nextDueDate == nil ? totalDuration : runningRemaining
            menuBarState = .running(remaining: remaining)
            isFlowing = true
        case .paused:
            remaining = max(0, pausedRemaining ?? totalDuration)
            menuBarState = .paused(remaining: remaining)
            isFlowing = false
        }

        let progress: Double
        if totalDuration > 0 {
            progress = min(1, max(0, remaining / totalDuration))
        } else {
            progress = 0
        }

        let home = HomeDisplayModel(
            remainingText: MenuBarTextFormatter.runningText(remaining: remaining),
            sandProgress: progress,
            isFlowing: isFlowing
        )

        return DisplaySnapshot(menuBarState: menuBarState, home: home)
    }
}
