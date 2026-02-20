import Foundation

enum ReminderOutcome {
    case completed
    case skipped
}

struct ReminderRecord {
    let type: ReminderType
    let outcome: ReminderOutcome
    let timestamp: Date

    init(type: ReminderType, outcome: ReminderOutcome, timestamp: Date) {
        self.type = type
        self.outcome = outcome
        self.timestamp = timestamp
    }
}

struct DailyStats {
    let completedCount: Int
    let skippedCount: Int
}

final class RecordStore {
    private var records: [ReminderRecord] = []
    private let calendar: Calendar

    nonisolated deinit {}

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func append(type: ReminderType, outcome: ReminderOutcome, at date: Date) {
        records.append(ReminderRecord(type: type, outcome: outcome, timestamp: date))
    }

    func todayStats(now: Date) -> DailyStats {
        let today = records.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
        let completed = today.filter { $0.outcome == .completed }.count
        let skipped = today.filter { $0.outcome == .skipped }.count
        return DailyStats(completedCount: completed, skippedCount: skipped)
    }
}
