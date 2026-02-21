import AppKit
import Foundation

struct SettingsResetPolicy {
    static func shouldReset(old: AppSettings, new: AppSettings) -> Bool {
        old.eyeBreakIntervalMinutes != new.eyeBreakIntervalMinutes
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarController = MenuBarController()
    private let overlayController = OverlayWindowController()
    private let settingsStore = SettingsStore.shared
    private let smartModeMonitor = SmartModeMonitor(replayDelay: 15)

    private lazy var coordinator = ReminderCoordinator(
        settingsStore: settingsStore,
        smartMonitor: smartModeMonitor,
        overlayPresenter: overlayController
    )

    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?
    private var statusTicker: DispatchSourceTimer?
    private var pausedRemaining: TimeInterval?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController.setup(
            onPrimaryAction: { [weak self] in
                self?.handlePrimaryAction()
            },
            onOpenAbout: { [weak self] in
                self?.openAbout()
            },
            onOpenSettings: { [weak self] in
                self?.prepareForSettingsOpen()
            },
            onQuit: {
                NSApp.terminate(nil)
            },
            onManualBreak: { [weak self] in
                self?.handleManualBreak()
            },
            onReset: { [weak self] in
                self?.handleReset()
            }
        )

        refreshStatusDisplay()
        beginStatusTicker()

        subscribeSystemNotifications()
        subscribeSettingsNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
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
        let snapshot = ReminderDisplayMapper.build(
            runtimeState: coordinator.state,
            nextDueDate: coordinator.nextDueDate,
            pausedRemaining: pausedRemaining,
            settings: settingsStore.current,
            now: Date()
        )

        menuBarController.updateDisplay(state: snapshot.menuBarState)
        menuBarController.updateHome(model: snapshot.home)
    }

    private func handlePrimaryAction() {
        if coordinator.state == .running, let due = coordinator.nextDueDate {
            pausedRemaining = max(0, due.timeIntervalSinceNow)
        }
        coordinator.togglePrimaryAction()

        if coordinator.state != .paused {
            pausedRemaining = nil
        }

        refreshStatusDisplay()
    }

    private func handleManualBreak() {
        coordinator.manualBreakByCycle()
        pausedRemaining = nil
        refreshStatusDisplay()
    }

    private func handleReset() {
        coordinator.resetSchedule()
        pausedRemaining = nil
        refreshStatusDisplay()
    }

    private func openAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    private func prepareForSettingsOpen() {
        NSApp.activate(ignoringOtherApps: true)
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

    private func subscribeSettingsNotifications() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: .settingsDidChange,
            object: settingsStore,
            queue: .main
        ) { [weak self] notification in
            self?.handleSettingsDidChange(notification)
        }
    }

    private func handleSettingsDidChange(_ notification: Notification) {
        guard let payload = SettingsStore.settingsDidChangePayload(from: notification) else {
            refreshStatusDisplay()
            return
        }

        if SettingsResetPolicy.shouldReset(old: payload.oldSettings, new: payload.newSettings) {
            coordinator.resetSchedule()
            pausedRemaining = nil
        } else {
            coordinator.applySettingsWithoutReset()
        }

        refreshStatusDisplay()
    }
}
