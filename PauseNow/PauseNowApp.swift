import SwiftUI

@main
struct PauseNowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settingsStore = SettingsStore()

    var body: some Scene {
        Settings {
            let viewModel = SettingsViewModel(store: settingsStore)
            SettingsView(initialPrompt: viewModel.promptText) { text in
                viewModel.savePromptText(text)
            }
        }
    }
}
