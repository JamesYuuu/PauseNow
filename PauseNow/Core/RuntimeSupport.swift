import Foundation
import os

protocol TimeProviding {
    func now() -> Date
}

struct SystemTimeProvider: TimeProviding {
    func now() -> Date {
        Date()
    }
}

protocol AppLogging {
    func debug(_ message: String)
}

struct ConsoleLogger: AppLogging {
    private let logger = Logger(subsystem: "PauseNow", category: "runtime")

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
}
