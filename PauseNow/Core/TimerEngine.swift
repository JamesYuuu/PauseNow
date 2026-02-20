import Foundation

struct TimerConfig {
    let eyeBreakInterval: TimeInterval

    static let `default` = TimerConfig(eyeBreakInterval: 20 * 60)

    init(eyeBreakInterval: TimeInterval) {
        self.eyeBreakInterval = max(1, eyeBreakInterval)
    }
}

final class TimerEngine {
    private let config: TimerConfig
    private var pausedRemaining: TimeInterval?

    private(set) var nextDueDate: Date?

    nonisolated deinit {}

    init(config: TimerConfig) {
        self.config = config
    }

    func start(currentDate: Date = Date()) {
        nextDueDate = currentDate.addingTimeInterval(config.eyeBreakInterval)
        pausedRemaining = nil
    }

    func pause(currentDate: Date = Date()) {
        guard let nextDueDate else { return }
        pausedRemaining = max(0, nextDueDate.timeIntervalSince(currentDate))
    }

    func resume(currentDate: Date = Date()) {
        guard let pausedRemaining else { return }
        nextDueDate = currentDate.addingTimeInterval(pausedRemaining)
        self.pausedRemaining = nil
    }

    func reset() {
        nextDueDate = nil
        pausedRemaining = nil
    }
}
