# Feature Status

This file tracks the current product scope so contributors can quickly see what is implemented versus partially wired.

## Done

- Menu bar countdown display unified to `mm:ss`
- Primary action state flow: start -> pause -> resume
- Manual break and reset actions in home popover
- Overlay reminders with countdown and skip behavior
- Eye-break / stand-up cycle engine
- Settings persistence for interval, durations, cycle count, and prompt text
- Settings window activation flow from menu bar
- Runtime settings reaction:
  - interval changes reset schedule immediately
  - non-interval changes apply without resetting schedule

## Partial / Not Fully Wired

- Fullscreen defer mode
  - `SmartModeMonitor` supports deferral flag
  - fullscreen event signal wiring is not complete
- Custom prompt text rendering
  - prompt is saved in settings
  - overlay title still uses fixed copy
- Stats integration
  - `RecordStore` and `DailyStats` exist
  - reminder completion/skip events are not fully persisted in runtime flow

## Planned (Suggested Next Steps)

- Wire fullscreen enter/exit events into smart defer flow
- Connect saved prompt text to overlay presentation text
- Persist runtime reminder outcomes through `RecordStore`
- Add lightweight UI or settings surface for daily stats visibility

## Reference

- Runtime composition: `PauseNow/AppDelegate.swift`
- Scheduling logic: `PauseNow/Core/ReminderCoordinator.swift`
- Display mapping: `PauseNow/UI/MenuBar/MenuBarDisplayModels.swift`
- Settings persistence: `PauseNow/Data/SettingsStore.swift`
