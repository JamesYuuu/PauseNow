import Foundation

struct SettingsValidator {
    static func sanitized(_ settings: AppSettings) -> AppSettings {
        var value = settings
        value.eyeBreakIntervalMinutes = max(1, value.eyeBreakIntervalMinutes)
        value.eyeBreakSeconds = max(1, value.eyeBreakSeconds)
        value.standupEveryEyeBreaks = max(1, value.standupEveryEyeBreaks)
        value.standupSeconds = max(1, value.standupSeconds)

        let prompt = value.defaultPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        value.defaultPromptText = prompt.isEmpty ? AppSettings.defaultPromptText : prompt
        return value
    }
}
