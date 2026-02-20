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
        var settings = store.current
        settings.defaultPromptText = text
        store.save(settings)
        promptText = text
    }

    func saveDurations(eyeBreakSeconds: Int, standupSeconds: Int) {
        var settings = store.current
        settings.eyeBreakSeconds = max(1, eyeBreakSeconds)
        settings.standupSeconds = max(1, standupSeconds)
        store.save(settings)
        self.eyeBreakSeconds = settings.eyeBreakSeconds
        self.standupSeconds = settings.standupSeconds
    }

    func saveSchedule(eyeBreakIntervalMinutes: Int, standupEveryEyeBreaks: Int) {
        var settings = store.current
        settings.eyeBreakIntervalMinutes = max(1, eyeBreakIntervalMinutes)
        settings.standupEveryEyeBreaks = max(1, standupEveryEyeBreaks)
        store.save(settings)
        self.eyeBreakIntervalMinutes = settings.eyeBreakIntervalMinutes
        self.standupEveryEyeBreaks = settings.standupEveryEyeBreaks
    }
}
