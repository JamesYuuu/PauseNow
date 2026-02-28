import Foundation

struct AppSettings: Codable {
    static let defaultPromptText = "现在稍息！"

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
        defaultPromptText: AppSettings.defaultPromptText
    )
}

final class SettingsStore {
    struct SettingsDidChangePayload {
        let oldSettings: AppSettings
        let newSettings: AppSettings
    }

    enum UserInfoKey {
        static let payload = "payload"
    }

    static let shared = SettingsStore()

    private let key = "pausenow.settings.v1"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger: AppLogging

    nonisolated deinit {}

    init(userDefaults: UserDefaults = .standard, logger: AppLogging = ConsoleLogger()) {
        self.userDefaults = userDefaults
        self.logger = logger
    }

    static func settingsDidChangePayload(from notification: Notification) -> SettingsDidChangePayload? {
        notification.userInfo?[UserInfoKey.payload] as? SettingsDidChangePayload
    }

    var current: AppSettings {
        guard let data = userDefaults.data(forKey: key),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return SettingsValidator.sanitized(settings)
    }

    func save(_ settings: AppSettings) {
        let oldSettings = current
        let newSettings = SettingsValidator.sanitized(settings)
        guard let data = try? encoder.encode(newSettings) else { return }
        userDefaults.set(data, forKey: key)
        logger.debug(
            "settings: saved interval=\(newSettings.eyeBreakIntervalMinutes)m eye=\(newSettings.eyeBreakSeconds)s standupEvery=\(newSettings.standupEveryEyeBreaks) standup=\(newSettings.standupSeconds)s"
        )

        NotificationCenter.default.post(
            name: .settingsDidChange,
            object: self,
            userInfo: [
                UserInfoKey.payload: SettingsDidChangePayload(oldSettings: oldSettings, newSettings: newSettings)
            ]
        )
    }

    func update(_ mutate: (inout AppSettings) -> Void) -> AppSettings {
        var settings = current
        mutate(&settings)
        save(settings)
        return settings
    }
}

extension Notification.Name {
    static let settingsDidChange = Notification.Name("PauseNow.settingsDidChange")
}
