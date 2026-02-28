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

    nonisolated deinit {}

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    static func settingsDidChangePayload(from notification: Notification) -> SettingsDidChangePayload? {
        notification.userInfo?[UserInfoKey.payload] as? SettingsDidChangePayload
    }

    var current: AppSettings {
        guard let data = userDefaults.data(forKey: key),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func save(_ settings: AppSettings) {
        let oldSettings = current
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: key)

        NotificationCenter.default.post(
            name: .settingsDidChange,
            object: self,
            userInfo: [
                UserInfoKey.payload: SettingsDidChangePayload(oldSettings: oldSettings, newSettings: settings)
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
