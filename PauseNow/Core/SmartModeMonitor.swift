import Foundation

final class SmartModeMonitor {
    private let replayDelay: TimeInterval

    nonisolated deinit {}

    private(set) var shouldDeferReminder = false
    private(set) var isPausedBySystemState = false

    init(replayDelay: TimeInterval) {
        self.replayDelay = max(0, replayDelay)
    }

    func setFullscreen(_ enabled: Bool) {
        shouldDeferReminder = enabled
    }

    func setSystemSleeping(_ sleeping: Bool) {
        isPausedBySystemState = sleeping
    }

    func scheduledReplayDelay() -> TimeInterval {
        replayDelay
    }
}
