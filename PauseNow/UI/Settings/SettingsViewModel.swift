import Foundation

final class SettingsViewModel {
    private let store: SettingsStore

    nonisolated deinit {}

    var promptText: String

    init(store: SettingsStore) {
        self.store = store
        self.promptText = store.current.defaultPromptText
    }

    func savePromptText(_ text: String) {
        var settings = store.current
        settings.defaultPromptText = text
        store.save(settings)
        promptText = text
    }
}
