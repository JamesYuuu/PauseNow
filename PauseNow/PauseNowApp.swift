import SwiftUI

@main
struct PauseNowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settingsStore = SettingsStore.shared

    var body: some Scene {
        Settings {
            let viewModel = SettingsViewModel(store: settingsStore)
            TabView {
                SettingsView(
                    initialPrompt: viewModel.promptText,
                    initialEyeBreakIntervalMinutes: viewModel.eyeBreakIntervalMinutes,
                    initialEyeBreakSeconds: viewModel.eyeBreakSeconds,
                    initialStandupEveryEyeBreaks: viewModel.standupEveryEyeBreaks,
                    initialStandupSeconds: viewModel.standupSeconds
                ) { text, interval, eyeBreak, standupEvery, standup in
                    viewModel.savePromptText(text)
                    viewModel.saveSchedule(eyeBreakIntervalMinutes: interval, standupEveryEyeBreaks: standupEvery)
                    viewModel.saveDurations(eyeBreakSeconds: eyeBreak, standupSeconds: standup)
                }
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

                AboutSettingsView()
                    .tabItem {
                        Label("关于", systemImage: "info.circle")
                    }
            }
            .frame(minWidth: 760, minHeight: 560)
        }
    }
}
