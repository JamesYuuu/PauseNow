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
