# Repository Structure

This document explains how the PauseNow codebase is organized and where to start as a new contributor.

## Top-Level Layout

- `PauseNow/`: app source code (Core, Data, UI, app entry)
- `PauseNowTests/`: XCTest suite
- `PauseNow.xcodeproj/`: shared Xcode project configuration
- `docs/`: release and contributor documentation

## Source Layout (`PauseNow/`)

### `PauseNow/PauseNowApp.swift`

- SwiftUI app entry point (`@main`)
- Registers `AppDelegate`
- Defines the official macOS `Settings` scene

### `PauseNow/AppDelegate.swift`

- Runtime composition root
- Wires `MenuBarController`, `ReminderCoordinator`, `SettingsStore`, `SmartModeMonitor`
- Owns display refresh loop and settings change reaction

### `PauseNow/Core/`

- `ReminderCoordinator.swift`: runtime state machine (`stopped/running/paused`), tick processing, overlay triggering
- `RuleEngine.swift`: cycle logic (`eyeBreak` vs `standup`) and runtime config updates
- `TimerEngine.swift`: schedule timing state
- `SmartModeMonitor.swift`: deferral/pause flags (sleep wired, fullscreen signal pending)
- `ReminderModels.swift`: shared domain types (`ReminderType`, `RuleConfig`, events)

### `PauseNow/Data/`

- `SettingsStore.swift`: settings persistence + settings change notification payload
- `RecordStore.swift`: in-memory reminder outcome records and daily stats helper

### `PauseNow/UI/`

- `MenuBar/`
  - `MenuBarController.swift`: status item, popover, menu bar appearance
  - `MenuBarDisplayModels.swift`: display mapping and countdown formatter
- `Home/`
  - `HomePopoverView.swift`: primary popover UI and gear menu
  - `HomeViewModel.swift`: action bridge and display model binding
  - `HourglassButtonView.swift`: hourglass interaction view
- `Settings/`
  - `SettingsView.swift`: editable settings UI
  - `SettingsViewModel.swift`: settings save orchestration
  - `AboutSettingsView.swift`: About tab content
- `Overlay/`
  - `OverlayWindowController.swift`: full-screen overlay window presenter
  - `OverlayViewModel.swift`: countdown and skip/completion state
  - `OverlayView.swift`: overlay SwiftUI view

## Runtime Data Flow

### 1) App startup

1. `PauseNowApp` creates `AppDelegate`
2. `AppDelegate.applicationDidFinishLaunching` calls `menuBarController.setup(...)`
3. `AppDelegate` starts status ticker and subscribes to system/settings notifications

### 2) Reminder scheduling and execution

1. User action triggers coordinator (`start/pause/resume/manual/reset`)
2. `ReminderCoordinator` updates `TimerEngine` and `RuleEngine`
3. Tick loop calls `processTick(currentDate:)`
4. Due events are presented via `OverlayWindowController`

### 3) Display mapping

1. `AppDelegate.refreshStatusDisplay()` builds a snapshot via `ReminderDisplayMapper`
2. Snapshot feeds:
   - menu bar title (`MenuBarController.updateDisplay`)
   - home popover model (`MenuBarController.updateHome`)

### 4) Settings update flow

1. `SettingsView` saves through `SettingsViewModel`
2. `SettingsStore.save` persists and posts `.settingsDidChange`
3. `AppDelegate` receives notification and applies policy:
   - interval changed -> reset schedule
   - interval unchanged -> apply non-reset config update

## 10-Minute Onboarding Path

If this is your first time in the repo, read in this order:

1. `README.md`
2. `PauseNow/PauseNowApp.swift`
3. `PauseNow/AppDelegate.swift`
4. `PauseNow/Core/ReminderCoordinator.swift`
5. `PauseNow/UI/MenuBar/MenuBarDisplayModels.swift`
6. `PauseNow/UI/MenuBar/MenuBarController.swift`
7. `PauseNowTests/PauseNowTests.swift`

Then use:

- `docs/development.md` for local workflow
- `docs/feature-status.md` for current scope and known partials
