import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarController = MenuBarController()
    private let overlayController = OverlayWindowController()
    private let settingsStore = SettingsStore()
    private let smartModeMonitor = SmartModeMonitor(replayDelay: 15)

    private lazy var coordinator = ReminderCoordinator(
        settingsStore: settingsStore,
        smartMonitor: smartModeMonitor,
        overlayPresenter: overlayController
    )

    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var statusTicker: DispatchSourceTimer?
    private var pausedRemaining: TimeInterval?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController.setup(
            onStart: { [weak self] in
                self?.coordinator.start()
                self?.menuBarController.setRunningState(true)
                self?.pausedRemaining = nil
                self?.refreshStatusDisplay()
            },
            onPause: { [weak self] in
                guard let self else { return }
                self.coordinator.pause()
                self.menuBarController.setPausedState(true)
                if let due = self.coordinator.nextDueDate {
                    self.pausedRemaining = max(0, due.timeIntervalSinceNow)
                }
                self.refreshStatusDisplay()
            },
            onResume: { [weak self] in
                self?.coordinator.resume()
                self?.menuBarController.setRunningState(true)
                self?.pausedRemaining = nil
                self?.refreshStatusDisplay()
            }
        )

        menuBarController.updateDisplayIdle()
        beginStatusTicker()

        subscribeSystemNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        if let statusTicker {
            statusTicker.setEventHandler {}
            statusTicker.cancel()
            self.statusTicker = nil
        }
    }

    private func beginStatusTicker() {
        guard statusTicker == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            self?.refreshStatusDisplay()
        }
        timer.resume()
        statusTicker = timer
    }

    private func refreshStatusDisplay() {
        switch coordinator.state {
        case .stopped:
            menuBarController.updateDisplayIdle()
        case .running:
            if let due = coordinator.nextDueDate {
                menuBarController.updateDisplayRunning(remaining: max(0, due.timeIntervalSinceNow))
            } else {
                menuBarController.updateDisplayIdle()
            }
        case .paused:
            menuBarController.updateDisplayPaused(remaining: pausedRemaining ?? 0)
        }
    }

    private func subscribeSystemNotifications() {
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.smartModeMonitor.setSystemSleeping(true)
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.smartModeMonitor.setSystemSleeping(false)
        }
    }
}
