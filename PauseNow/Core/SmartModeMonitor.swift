import Foundation

final class SmartModeMonitor {
    private let replayDelay: TimeInterval
    private let logger: AppLogging

    nonisolated deinit {}

    private(set) var shouldDeferReminder = false
    private(set) var isPausedBySystemState = false

    init(replayDelay: TimeInterval, logger: AppLogging = ConsoleLogger()) {
        self.replayDelay = max(0, replayDelay)
        self.logger = logger
    }

    func setFullscreen(_ enabled: Bool) {
        shouldDeferReminder = enabled
        logger.debug("smart mode: fullscreen defer=\(enabled)")
    }

    func setSystemSleeping(_ sleeping: Bool) {
        isPausedBySystemState = sleeping
        logger.debug("smart mode: system sleeping=\(sleeping)")
    }

    func scheduledReplayDelay() -> TimeInterval {
        replayDelay
    }
}
