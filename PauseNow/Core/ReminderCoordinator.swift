import Foundation

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

final class ReminderCoordinator {
    private let settingsStore: SettingsStore
    private let smartMonitor: SmartModeMonitor
    private let overlayPresenter: ReminderOverlayPresenting
    private var engine: RuleEngine
    private var timerEngine: TimerEngine
    private var heartbeat: DispatchSourceTimer?
    private var overlayInFlight = false

    private(set) var state: ReminderRuntimeState = .stopped

    init(
        settingsStore: SettingsStore,
        smartMonitor: SmartModeMonitor,
        overlayPresenter: ReminderOverlayPresenting
    ) {
        self.settingsStore = settingsStore
        self.smartMonitor = smartMonitor
        self.overlayPresenter = overlayPresenter
        self.engine = RuleEngine(config: .default)
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
            timerEngine.start()
            beginHeartbeatIfNeeded()
        case .paused:
            timerEngine.resume()
        case .running:
            return
        }
        state = .running
    }

    func pause() {
        guard state == .running else { return }
        timerEngine.pause()
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        timerEngine.resume()
        state = .running
    }

    func processTick(currentDate: Date) {
        guard state == .running, !overlayInFlight else { return }
        guard !smartMonitor.isPausedBySystemState else { return }
        guard !smartMonitor.shouldDeferReminder else { return }
        guard let due = timerEngine.nextDueDate, currentDate >= due else { return }

        let event = engine.nextEvent(at: currentDate)
        let settings = settingsStore.current
        let duration = event.type == .eyeBreak ? settings.eyeBreakSeconds : settings.standupSeconds

        overlayInFlight = true
        overlayPresenter.present(
            event: event.type,
            durationSeconds: duration,
            onSkip: { [weak self] in
                self?.overlayInFlight = false
                self?.timerEngine.start()
            },
            onComplete: { [weak self] in
                guard let self else { return }
                self.engine.markCompleted(event.type)
                self.overlayInFlight = false
                self.timerEngine.start()
            }
        )
    }

    private func beginHeartbeatIfNeeded() {
        guard heartbeat == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.processTick(currentDate: Date())
        }
        timer.resume()
        heartbeat = timer
    }
}
