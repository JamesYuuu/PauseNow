import Foundation

struct RuleEngine {
    private var config: RuleConfig
    private var completedEyeBreaksInCurrentCycle: Int

    init(config: RuleConfig) {
        self.config = config
        self.completedEyeBreaksInCurrentCycle = 0
    }

    mutating func markEyeBreakCompleted(times: Int = 1) {
        guard times > 0 else { return }
        completedEyeBreaksInCurrentCycle += times
    }

    mutating func applyConfigWithoutReset(_ config: RuleConfig) {
        self.config = config
    }

    func nextEvent(at now: Date) -> ReminderEvent {
        let willHitStandupBoundary = (completedEyeBreaksInCurrentCycle + 1) % config.standupEveryEyeBreaks == 0
        let type: ReminderType = willHitStandupBoundary ? .standup : .eyeBreak
        return ReminderEvent(type: type, dueAt: now)
    }

    mutating func markCompleted(_ type: ReminderType) {
        switch type {
        case .eyeBreak:
            completedEyeBreaksInCurrentCycle += 1
        case .standup:
            completedEyeBreaksInCurrentCycle = 0
        }
    }
}
