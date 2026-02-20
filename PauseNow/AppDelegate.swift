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
                self?.handleStart()
            },
            onPause: { [weak self] in
                self?.handlePause()
            },
            onResume: { [weak self] in
                self?.handleResume()
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
        menuBarController.updateDisplay(state: currentDisplayState())
    }

    private func handleStart() {
        coordinator.start()
        menuBarController.setRunningState(true)
        pausedRemaining = nil
        refreshStatusDisplay()
    }

    private func handlePause() {
        coordinator.pause()
        menuBarController.setPausedState(true)
        if let due = coordinator.nextDueDate {
            pausedRemaining = max(0, due.timeIntervalSinceNow)
        }
        refreshStatusDisplay()
    }

    private func handleResume() {
        coordinator.resume()
        menuBarController.setRunningState(true)
        pausedRemaining = nil
        refreshStatusDisplay()
    }

    private func currentDisplayState() -> MenuBarDisplayState {
        switch coordinator.state {
        case .stopped:
            return .idle
        case .running:
            guard let due = coordinator.nextDueDate else { return .idle }
            return .running(remaining: max(0, due.timeIntervalSinceNow))
        case .paused:
            return .paused(remaining: pausedRemaining ?? 0)
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
