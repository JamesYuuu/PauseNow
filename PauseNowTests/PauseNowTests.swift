import XCTest
@testable import PauseNow

final class PauseNowTests: XCTestCase {
    func testMenuBarTextIdleIsResting() {
        XCTAssertEqual(MenuBarTextFormatter.idleText, "休息中")
    }

    func testMenuBarTextRunningFormatsMMSS() {
        XCTAssertEqual(MenuBarTextFormatter.runningText(remaining: 65), "01:05")
    }

    func testMenuBarTextPausedFormatsPrefixAndMMSS() {
        XCTAssertEqual(MenuBarTextFormatter.pausedText(remaining: 125), "已暂停 02:05")
    }

    func testDisplayMapperIdleUsesInitialInterval() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = ReminderDisplayMapper.build(
            runtimeState: .stopped,
            nextDueDate: nil,
            pausedRemaining: nil,
            settings: .default,
            now: now
        )

        XCTAssertEqual(snapshot.home.remainingText, "20:00")
        XCTAssertEqual(snapshot.home.sandProgress, 1)
        XCTAssertFalse(snapshot.home.isFlowing)
    }

    func testDisplayMapperRunningUsesDueDateRemaining() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let due = now.addingTimeInterval(90)
        let snapshot = ReminderDisplayMapper.build(
            runtimeState: .running,
            nextDueDate: due,
            pausedRemaining: nil,
            settings: .default,
            now: now
        )

        XCTAssertEqual(snapshot.home.remainingText, "01:30")
        XCTAssertEqual(snapshot.home.sandProgress, 0.075, accuracy: 0.0001)
        XCTAssertTrue(snapshot.home.isFlowing)
    }

    func testDisplayMapperPausedUsesPausedRemaining() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = ReminderDisplayMapper.build(
            runtimeState: .paused,
            nextDueDate: nil,
            pausedRemaining: 75,
            settings: .default,
            now: now
        )

        XCTAssertEqual(snapshot.home.remainingText, "01:15")
        XCTAssertEqual(snapshot.home.sandProgress, 0.0625, accuracy: 0.0001)
        XCTAssertFalse(snapshot.home.isFlowing)
    }

    @MainActor
    func testRuleEnginePrefersStandupOnBoundary() {
        var engine = RuleEngine(config: .default)
        engine.markEyeBreakCompleted(times: 2)

        let event = engine.nextEvent(at: Date())
        XCTAssertEqual(event.type, .standup)
    }

    @MainActor
    func testRuleEngineUsesEyeBreakWhenNotBoundary() {
        var engine = RuleEngine(config: .default)
        engine.markEyeBreakCompleted(times: 1)

        let event = engine.nextEvent(at: Date())
        XCTAssertEqual(event.type, .eyeBreak)
    }

    @MainActor
    func testRuleEngineStandupCompletionResetsCycle() {
        var engine = RuleEngine(config: .default)
        engine.markEyeBreakCompleted(times: 2)
        let standup = engine.nextEvent(at: Date())
        engine.markCompleted(standup.type)

        let next = engine.nextEvent(at: Date())
        XCTAssertEqual(next.type, .eyeBreak)
    }

    func testTimerPauseAndResumePreservesDueDate() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let engine = TimerEngine(config: .default)
        engine.start(currentDate: now)
        engine.pause(currentDate: now)
        let pausedDue = engine.nextDueDate
        engine.resume(currentDate: now)

        XCTAssertEqual(engine.nextDueDate, pausedDue)
    }

    @MainActor
    func testOverlayAutoCompletesAfterCountdownAdvance() {
        let viewModel = OverlayViewModel(type: .eyeBreak, seconds: 20)
        viewModel.start()
        viewModel.advance(by: 20)

        XCTAssertTrue(viewModel.isCompleted)
    }

    @MainActor
    func testOverlayMarksSkipped() {
        let viewModel = OverlayViewModel(type: .standup, seconds: 180)
        viewModel.start()
        viewModel.skip()

        XCTAssertTrue(viewModel.isSkipped)
    }

    @MainActor
    func testSmartModeDefersInFullscreen() {
        let monitor = SmartModeMonitor(replayDelay: 15)
        monitor.setFullscreen(true)

        XCTAssertTrue(monitor.shouldDeferReminder)
    }

    @MainActor
    func testSmartModePauseAndResumeBySleep() {
        let monitor = SmartModeMonitor(replayDelay: 15)
        monitor.setSystemSleeping(true)
        XCTAssertTrue(monitor.isPausedBySystemState)

        monitor.setSystemSleeping(false)
        XCTAssertFalse(monitor.isPausedBySystemState)
    }

    @MainActor
    func testSettingsDefaultStandupDurationIs180Seconds() {
        let defaults = UserDefaults(suiteName: "PauseNowTests.Settings")!
        defaults.removePersistentDomain(forName: "PauseNowTests.Settings")
        let store = SettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.current.standupSeconds, 180)
    }

    @MainActor
    func testSettingsPromptCanBeCustomized() {
        let defaults = UserDefaults(suiteName: "PauseNowTests.Prompt")!
        defaults.removePersistentDomain(forName: "PauseNowTests.Prompt")
        let store = SettingsStore(userDefaults: defaults)
        var settings = store.current
        settings.defaultPromptText = "Take a break now!"
        store.save(settings)

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.current.defaultPromptText, "Take a break now!")
    }

    @MainActor
    func testSettingsViewModelUsesDefaultPrompt() {
        let defaults = UserDefaults(suiteName: "PauseNowTests.ViewModel")!
        defaults.removePersistentDomain(forName: "PauseNowTests.ViewModel")
        let store = SettingsStore(userDefaults: defaults)
        let viewModel = SettingsViewModel(store: store)

        XCTAssertEqual(viewModel.promptText, "现在稍息！")
    }

    @MainActor
    func testSettingsCanSaveEyeBreakAndStandupSeconds() {
        let suite = "PauseNowTests.Durations"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = SettingsStore(userDefaults: defaults)
        let viewModel = SettingsViewModel(store: store)

        viewModel.saveDurations(eyeBreakSeconds: 30, standupSeconds: 240)

        XCTAssertEqual(store.current.eyeBreakSeconds, 30)
        XCTAssertEqual(store.current.standupSeconds, 240)
    }

    @MainActor
    func testSettingsCanSaveIntervalAndStandupEvery() {
        let suite = "PauseNowTests.IntervalAndCycle"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = SettingsStore(userDefaults: defaults)
        let viewModel = SettingsViewModel(store: store)

        viewModel.saveSchedule(eyeBreakIntervalMinutes: 25, standupEveryEyeBreaks: 4)

        XCTAssertEqual(store.current.eyeBreakIntervalMinutes, 25)
        XCTAssertEqual(store.current.standupEveryEyeBreaks, 4)
    }

    @MainActor
    func testRecordStoreAggregatesTodayStats() {
        let store = RecordStore()
        store.append(type: .eyeBreak, outcome: .completed, at: Date())
        store.append(type: .standup, outcome: .skipped, at: Date())

        let stats = store.todayStats(now: Date())
        XCTAssertEqual(stats.completedCount, 1)
        XCTAssertEqual(stats.skippedCount, 1)
    }

    @MainActor
    func testCoordinatorStartPauseResumeAndTriggerOverlay() {
        let defaults = UserDefaults(suiteName: "PauseNowTests.Coordinator")!
        defaults.removePersistentDomain(forName: "PauseNowTests.Coordinator")
        let settings = SettingsStore(userDefaults: defaults)
        let smart = SmartModeMonitor(replayDelay: 15)
        let overlay = TestOverlayPresenter()

        var currentTime = Date(timeIntervalSince1970: 1_700_000_000)
        let coordinator = ReminderCoordinator(
            settingsStore: settings,
            smartMonitor: smart,
            overlayPresenter: overlay
        )

        coordinator.start()
        XCTAssertEqual(coordinator.state, .running)
        XCTAssertNotNil(coordinator.nextDueDate)

        coordinator.pause()
        XCTAssertEqual(coordinator.state, .paused)

        coordinator.resume()
        XCTAssertEqual(coordinator.state, .running)

        currentTime = coordinator.nextDueDate ?? currentTime
        coordinator.processTick(currentDate: currentTime)
        XCTAssertEqual(overlay.presentedCount, 1)
    }

    @MainActor
    func testCoordinatorToggleCyclesStartPauseResume() {
        let defaults = UserDefaults(suiteName: "PauseNowTests.Toggle")!
        defaults.removePersistentDomain(forName: "PauseNowTests.Toggle")
        let settings = SettingsStore(userDefaults: defaults)
        let coordinator = ReminderCoordinator(
            settingsStore: settings,
            smartMonitor: SmartModeMonitor(replayDelay: 15),
            overlayPresenter: TestOverlayPresenter()
        )

        coordinator.togglePrimaryAction()
        XCTAssertEqual(coordinator.state, .running)

        coordinator.togglePrimaryAction()
        XCTAssertEqual(coordinator.state, .paused)

        coordinator.togglePrimaryAction()
        XCTAssertEqual(coordinator.state, .running)
    }

    @MainActor
    func testCoordinatorManualBreakUsesCycleRule() {
        let defaults = UserDefaults(suiteName: "PauseNowTests.ManualBreak")!
        defaults.removePersistentDomain(forName: "PauseNowTests.ManualBreak")
        let settings = SettingsStore(userDefaults: defaults)
        let overlay = TestOverlayPresenter()
        let coordinator = ReminderCoordinator(
            settingsStore: settings,
            smartMonitor: SmartModeMonitor(replayDelay: 15),
            overlayPresenter: overlay
        )

        coordinator.manualBreakByCycle()

        XCTAssertEqual(overlay.presentedCount, 1)
        XCTAssertEqual(overlay.lastEvent, .eyeBreak)
    }

    @MainActor
    func testCoordinatorManualBreakUsesConfiguredStandupCycle() {
        let suite = "PauseNowTests.ManualBreakCycle"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let settingsStore = SettingsStore(userDefaults: defaults)
        var settings = settingsStore.current
        settings.standupEveryEyeBreaks = 2
        settingsStore.save(settings)

        let overlay = TestOverlayPresenter()
        let coordinator = ReminderCoordinator(
            settingsStore: settingsStore,
            smartMonitor: SmartModeMonitor(replayDelay: 15),
            overlayPresenter: overlay
        )

        coordinator.manualBreakByCycle()
        coordinator.manualBreakByCycle()

        XCTAssertEqual(overlay.presentedEvents, [.eyeBreak, .standup])
    }

    @MainActor
    func testCoordinatorResetReturnsToStoppedBaseline() {
        let defaults = UserDefaults(suiteName: "PauseNowTests.Reset")!
        defaults.removePersistentDomain(forName: "PauseNowTests.Reset")
        let settings = SettingsStore(userDefaults: defaults)
        let coordinator = ReminderCoordinator(
            settingsStore: settings,
            smartMonitor: SmartModeMonitor(replayDelay: 15),
            overlayPresenter: TestOverlayPresenter()
        )

        coordinator.start()
        XCTAssertNotNil(coordinator.nextDueDate)

        coordinator.resetSchedule()

        XCTAssertEqual(coordinator.state, .stopped)
        XCTAssertNil(coordinator.nextDueDate)
    }

    @MainActor
    func testCoordinatorStartUsesConfiguredIntervalMinutes() {
        let suite = "PauseNowTests.IntervalApplied"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let settingsStore = SettingsStore(userDefaults: defaults)
        var settings = settingsStore.current
        settings.eyeBreakIntervalMinutes = 1
        settingsStore.save(settings)

        let coordinator = ReminderCoordinator(
            settingsStore: settingsStore,
            smartMonitor: SmartModeMonitor(replayDelay: 15),
            overlayPresenter: TestOverlayPresenter()
        )

        coordinator.start()

        guard let remaining = coordinator.nextDueDate?.timeIntervalSinceNow else {
            return XCTFail("nextDueDate should not be nil")
        }
        XCTAssertGreaterThan(remaining, 50)
        XCTAssertLessThan(remaining, 61)
    }

    @MainActor
    func testHomeViewModelCanTriggerMenuActions() {
        let viewModel = HomeViewModel()
        var aboutCount = 0
        var quitCount = 0

        viewModel.onOpenAbout = { aboutCount += 1 }
        viewModel.onQuit = { quitCount += 1 }

        viewModel.openAbout()
        viewModel.quitApp()

        XCTAssertEqual(aboutCount, 1)
        XCTAssertEqual(quitCount, 1)
    }
}

private final class TestOverlayPresenter: ReminderOverlayPresenting {
    private(set) var presentedCount = 0
    private(set) var lastEvent: ReminderType?
    private(set) var presentedEvents: [ReminderType] = []

    func present(
        event: ReminderType,
        durationSeconds: Int,
        onSkip: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        presentedCount += 1
        lastEvent = event
        presentedEvents.append(event)
        onComplete()
    }
}
