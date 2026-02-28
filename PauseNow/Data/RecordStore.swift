import Foundation

enum ReminderOutcome {
    case completed
    case skipped
}

struct ReminderRecord {
    let type: ReminderType
    let outcome: ReminderOutcome
    let timestamp: Date
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
        var completedCount = 0
        var skippedCount = 0

        for record in records where calendar.isDate(record.timestamp, inSameDayAs: now) {
            switch record.outcome {
            case .completed:
                completedCount += 1
            case .skipped:
                skippedCount += 1
            }
        }

        return DailyStats(completedCount: completedCount, skippedCount: skippedCount)
    }
}
