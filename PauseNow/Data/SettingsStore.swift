import Foundation

struct AppSettings: Codable {
    var eyeBreakIntervalMinutes: Int
    var eyeBreakSeconds: Int
    var standupEveryEyeBreaks: Int
    var standupSeconds: Int
    var defaultPromptText: String

    static let `default` = AppSettings(
        eyeBreakIntervalMinutes: 20,
        eyeBreakSeconds: 20,
        standupEveryEyeBreaks: 3,
        standupSeconds: 180,
        defaultPromptText: "现在稍息！"
    )
}

final class SettingsStore {
    private let key = "pausenow.settings.v1"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    nonisolated deinit {}

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var current: AppSettings {
        guard let data = userDefaults.data(forKey: key),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func save(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: key)
    }
}
