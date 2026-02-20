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
}

private final class TestOverlayPresenter: ReminderOverlayPresenting {
    private(set) var presentedCount = 0

    func present(
        event: ReminderType,
        durationSeconds: Int,
        onSkip: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        presentedCount += 1
        onComplete()
    }
}
