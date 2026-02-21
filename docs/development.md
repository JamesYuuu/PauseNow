# Development Guide

This guide covers the local development workflow for PauseNow.

## Prerequisites

- macOS
- Xcode 26.x or newer
- Command line tools (`xcodebuild`)

## Open and Run

1. Open `PauseNow.xcodeproj`
2. Select scheme `PauseNow`
3. Run on `My Mac`

## Build Commands

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -configuration Debug build
```

## Test Commands

Standard test command:

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' test
```

If signing causes local test failures, run the no-sign fallback:

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test
```

## Daily Workflow

1. Pull latest `main`
2. Implement scoped change
3. Run focused tests first, then full suite
4. Update docs if behavior changed
5. Verify `git status` is clean before release operations

## Troubleshooting

### Tests fail in codesign phase

- Symptom: test bundle signing error on local machine
- Action: rerun with no-sign flags (command above)
- Note: this is acceptable for local logic regression checks

### Menu bar countdown looks incorrect

- Check `ReminderDisplayMapper` in `PauseNow/UI/MenuBar/MenuBarDisplayModels.swift`
- Verify runtime state in `AppDelegate.refreshStatusDisplay()`
- Confirm interval values in `SettingsStore.current`

### Settings changed but runtime behavior did not

- Check `SettingsStore.save` notification posting
- Check `AppDelegate.handleSettingsDidChange(_:)`
- Verify expected policy:
  - interval changed => reset schedule
  - non-interval change => apply without reset

## Related Docs

- `README.md`
- `README.zh-CN.md`
- `docs/release-checklist.md`
- `docs/repository-structure.md`
- `docs/feature-status.md`
