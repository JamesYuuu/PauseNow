import Foundation

protocol ReminderCoordinating: AnyObject {
    var state: ReminderRuntimeState { get }
    var nextDueDate: Date? { get }

    func togglePrimaryAction()
    func manualBreakByCycle(now: Date?)
    func resetSchedule()
    func applySettingsWithoutReset()
}

protocol ReminderOverlayPresenting: AnyObject {
    func present(
        event: ReminderType,
        durationSeconds: Int,
        onSkip: @escaping () -> Void,
        onComplete: @escaping () -> Void
    )
}

enum ReminderRuntimeState {
    case stopped
    case running
    case paused
}

final class ReminderCoordinator: ReminderCoordinating {
    private let settingsStore: SettingsStore
    private let smartMonitor: SmartModeMonitor
    private let overlayPresenter: ReminderOverlayPresenting
    private let timeProvider: TimeProviding
    private let logger: AppLogging
    private var engine: RuleEngine
    private var timerEngine: TimerEngine
    private var heartbeat: DispatchSourceTimer?
    private var overlayInFlight = false

    private(set) var state: ReminderRuntimeState = .stopped

    init(
        settingsStore: SettingsStore,
        smartMonitor: SmartModeMonitor,
        overlayPresenter: ReminderOverlayPresenting,
        timeProvider: TimeProviding = SystemTimeProvider(),
        logger: AppLogging = ConsoleLogger()
    ) {
        self.settingsStore = settingsStore
        self.smartMonitor = smartMonitor
        self.overlayPresenter = overlayPresenter
        self.timeProvider = timeProvider
        self.logger = logger
        self.engine = RuleEngine(config: RuleConfig(standupEveryEyeBreaks: settingsStore.current.standupEveryEyeBreaks))
        let interval = TimeInterval(settingsStore.current.eyeBreakIntervalMinutes * 60)
        self.timerEngine = TimerEngine(config: TimerConfig(eyeBreakInterval: interval))
    }

    var nextDueDate: Date? {
        timerEngine.nextDueDate
    }

    deinit {
        heartbeat?.setEventHandler {}
        heartbeat?.cancel()
        heartbeat = nil
    }

    func start() {
        switch state {
        case .stopped:
            resetRuntime()
            startNewTimer()
            beginHeartbeatIfNeeded()
            logger.debug("coordinator: start from stopped")
        case .paused:
            timerEngine.resume(currentDate: timeProvider.now())
            logger.debug("coordinator: resume from paused")
        case .running:
            return
        }
        state = .running
    }

    func togglePrimaryAction() {
        switch state {
        case .stopped:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    func pause() {
        guard state == .running else { return }
        timerEngine.pause(currentDate: timeProvider.now())
        state = .paused
        logger.debug("coordinator: pause")
    }

    func resume() {
        guard state == .paused else { return }
        timerEngine.resume(currentDate: timeProvider.now())
        state = .running
        logger.debug("coordinator: resume")
    }

    func processTick(currentDate: Date) {
        guard state == .running, !overlayInFlight else { return }
        guard !smartMonitor.isPausedBySystemState else { return }
        guard !smartMonitor.shouldDeferReminder else { return }
        guard let due = timerEngine.nextDueDate, currentDate >= due else { return }

        let event = engine.nextEvent(at: currentDate)
        logger.debug("coordinator: trigger event \(event.type)")
        present(eventType: event.type)
    }

    func manualBreakByCycle(now: Date? = nil) {
        guard !overlayInFlight else { return }
        if state == .stopped {
            resetRuntime()
            beginHeartbeatIfNeeded()
            state = .running
            logger.debug("coordinator: manual break while stopped, move to running")
        }

        let eventTime = now ?? timeProvider.now()
        let event = engine.nextEvent(at: eventTime)
        present(eventType: event.type)
    }

    func resetSchedule() {
        state = .stopped
        overlayInFlight = false
        resetRuntime()
        logger.debug("coordinator: reset schedule")
    }

    func applySettingsWithoutReset() {
        engine.applyConfigWithoutReset(makeRuleConfig())
    }

    private func beginHeartbeatIfNeeded() {
        guard heartbeat == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.processTick(currentDate: self.timeProvider.now())
        }
        timer.resume()
        heartbeat = timer
    }

    private func present(eventType: ReminderType) {
        let settings = settingsStore.current
        let duration = eventType == .eyeBreak ? settings.eyeBreakSeconds : settings.standupSeconds

        overlayInFlight = true
        overlayPresenter.present(
            event: eventType,
            durationSeconds: duration,
            onSkip: { [weak self] in
                guard let self else { return }
                self.completeOverlayAndRestartTimer()
                self.logger.debug("coordinator: overlay skipped")
            },
            onComplete: { [weak self] in
                guard let self else { return }
                self.engine.markCompleted(eventType)
                self.completeOverlayAndRestartTimer()
                self.logger.debug("coordinator: overlay completed")
            }
        )
    }

    private func makeRuleEngine() -> RuleEngine {
        RuleEngine(config: makeRuleConfig())
    }

    private func makeRuleConfig() -> RuleConfig {
        RuleConfig(standupEveryEyeBreaks: settingsStore.current.standupEveryEyeBreaks)
    }

    private func makeTimerEngine() -> TimerEngine {
        let interval = TimeInterval(settingsStore.current.eyeBreakIntervalMinutes * 60)
        return TimerEngine(config: TimerConfig(eyeBreakInterval: interval))
    }

    private func resetRuntime() {
        engine = makeRuleEngine()
        timerEngine = makeTimerEngine()
    }

    private func startNewTimer() {
        timerEngine.start(currentDate: timeProvider.now())
    }

    private func completeOverlayAndRestartTimer() {
        overlayInFlight = false
        timerEngine = makeTimerEngine()
        timerEngine.start(currentDate: timeProvider.now())
    }
}
