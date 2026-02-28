import AppKit
import Foundation

struct SettingsResetPolicy {
    static func shouldReset(old: AppSettings, new: AppSettings) -> Bool {
        old.eyeBreakIntervalMinutes != new.eyeBreakIntervalMinutes
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuBarController: MenuBarController
    private let overlayController: OverlayWindowController
    private let settingsStore: SettingsStore
    private let smartModeMonitor: SmartModeMonitor
    private let timeProvider: TimeProviding
    private let logger: AppLogging
    private let injectedCoordinator: ReminderCoordinating?

    private lazy var defaultCoordinator = ReminderCoordinator(
        settingsStore: settingsStore,
        smartMonitor: smartModeMonitor,
        overlayPresenter: overlayController,
        timeProvider: timeProvider,
        logger: logger
    )
    private var coordinator: ReminderCoordinating {
        injectedCoordinator ?? defaultCoordinator
    }

    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?
    private var statusTicker: DispatchSourceTimer?
    private var pausedRemaining: TimeInterval?

    override init() {
        self.menuBarController = MenuBarController()
        self.overlayController = OverlayWindowController()
        self.settingsStore = .shared
        self.smartModeMonitor = SmartModeMonitor(replayDelay: 15)
        self.timeProvider = SystemTimeProvider()
        self.logger = ConsoleLogger()
        self.injectedCoordinator = nil
        super.init()
    }

    init(
        menuBarController: MenuBarController? = nil,
        overlayController: OverlayWindowController? = nil,
        settingsStore: SettingsStore,
        smartModeMonitor: SmartModeMonitor,
        timeProvider: TimeProviding,
        logger: AppLogging,
        coordinator: ReminderCoordinating? = nil
    ) {
        self.menuBarController = menuBarController ?? MenuBarController()
        self.overlayController = overlayController ?? OverlayWindowController()
        self.settingsStore = settingsStore
        self.smartModeMonitor = smartModeMonitor
        self.timeProvider = timeProvider
        self.logger = logger
        self.injectedCoordinator = coordinator
        super.init()
    }

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
        removeObservers()
        stopStatusTicker()
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
            now: timeProvider.now()
        )

        menuBarController.updateDisplay(state: snapshot.menuBarState)
        menuBarController.updateHome(model: snapshot.home)
    }

    private func handlePrimaryAction() {
        if coordinator.state == .running, let due = coordinator.nextDueDate {
            pausedRemaining = max(0, due.timeIntervalSince(timeProvider.now()))
        }
        coordinator.togglePrimaryAction()
        logger.debug("app delegate: primary action toggled to \(String(describing: coordinator.state))")

        if coordinator.state != .paused {
            pausedRemaining = nil
        }

        refreshStatusDisplay()
    }

    private func handleManualBreak() {
        coordinator.manualBreakByCycle(now: timeProvider.now())
        clearPausedStateAndRefresh()
        logger.debug("app delegate: manual break")
    }

    private func handleReset() {
        coordinator.resetSchedule()
        clearPausedStateAndRefresh()
        logger.debug("app delegate: reset schedule")
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
            self?.handleSystemSleepEvent()
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemWakeEvent()
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

    func handleSettingsDidChange(_ notification: Notification) {
        guard let payload = SettingsStore.settingsDidChangePayload(from: notification) else {
            refreshStatusDisplay()
            return
        }

        if SettingsResetPolicy.shouldReset(old: payload.oldSettings, new: payload.newSettings) {
            coordinator.resetSchedule()
            clearPausedState()
            logger.debug("app delegate: settings changed interval, schedule reset")
        } else {
            coordinator.applySettingsWithoutReset()
            logger.debug("app delegate: settings changed without interval reset")
        }

        refreshStatusDisplay()
    }

    private func clearPausedStateAndRefresh() {
        clearPausedState()
        refreshStatusDisplay()
    }

    private func clearPausedState() {
        pausedRemaining = nil
    }

    func handleSystemSleepEvent() {
        smartModeMonitor.setSystemSleeping(true)
        logger.debug("app delegate: system sleep observed")
    }

    func handleSystemWakeEvent() {
        smartModeMonitor.setSystemSleeping(false)
        logger.debug("app delegate: system wake observed")
    }

    private func removeObservers() {
        if let sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
        }
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }
    }

    private func stopStatusTicker() {
        guard let statusTicker else { return }
        statusTicker.setEventHandler {}
        statusTicker.cancel()
        self.statusTicker = nil
    }
}
