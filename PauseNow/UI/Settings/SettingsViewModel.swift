import Foundation

final class SettingsViewModel {
    private let store: SettingsStore

    nonisolated deinit {}

    var promptText: String
    var eyeBreakIntervalMinutes: Int
    var eyeBreakSeconds: Int
    var standupEveryEyeBreaks: Int
    var standupSeconds: Int

    init(store: SettingsStore) {
        self.store = store
        let current = store.current
        self.promptText = current.defaultPromptText
        self.eyeBreakIntervalMinutes = current.eyeBreakIntervalMinutes
        self.eyeBreakSeconds = current.eyeBreakSeconds
        self.standupEveryEyeBreaks = current.standupEveryEyeBreaks
        self.standupSeconds = current.standupSeconds
    }

    func savePromptText(_ text: String) {
        store.update { settings in
            settings.defaultPromptText = text
        }
        promptText = text
    }

    func saveDurations(eyeBreakSeconds: Int, standupSeconds: Int) {
        let settings = store.update { settings in
            settings.eyeBreakSeconds = Self.clampPositive(eyeBreakSeconds)
            settings.standupSeconds = Self.clampPositive(standupSeconds)
        }
        self.eyeBreakSeconds = settings.eyeBreakSeconds
        self.standupSeconds = settings.standupSeconds
    }

    func saveSchedule(eyeBreakIntervalMinutes: Int, standupEveryEyeBreaks: Int) {
        let settings = store.update { settings in
            settings.eyeBreakIntervalMinutes = Self.clampPositive(eyeBreakIntervalMinutes)
            settings.standupEveryEyeBreaks = Self.clampPositive(standupEveryEyeBreaks)
        }
        self.eyeBreakIntervalMinutes = settings.eyeBreakIntervalMinutes
        self.standupEveryEyeBreaks = settings.standupEveryEyeBreaks
    }

    private static func clampPositive(_ value: Int) -> Int {
        max(1, value)
    }
}
