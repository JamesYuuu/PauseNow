import Foundation

enum ReminderType {
    case eyeBreak
    case standup
}

struct ReminderEvent {
    let type: ReminderType
    let dueAt: Date

    init(type: ReminderType, dueAt: Date) {
        self.type = type
        self.dueAt = dueAt
    }
}

struct RuleConfig {
    let standupEveryEyeBreaks: Int

    static let `default` = RuleConfig(standupEveryEyeBreaks: 3)

    init(standupEveryEyeBreaks: Int) {
        self.standupEveryEyeBreaks = max(1, standupEveryEyeBreaks)
    }
}
