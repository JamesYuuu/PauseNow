# PauseNow

[中文说明 (README.zh-CN.md)](README.zh-CN.md)

PauseNow is a macOS menu bar break reminder app focused on the 20-20-20 workflow.

## Highlights

- Unified menu bar countdown (`mm:ss`) with hourglass popover controls
- Primary action toggle flow: start -> pause -> resume
- Manual break and reset actions from the popover
- Official macOS Settings scene integration
- Real-time settings updates (interval change resets schedule immediately)
- Full-screen overlay reminder with countdown and skip support

## Current Feature Status

### Implemented

- Eye-break reminder cadence (default: every 20 minutes for 20 seconds)
- Stand-up reminder every N eye breaks (default: every 3 eye breaks for 180 seconds)
- Runtime state mapping for menu bar + popover display (`stopped/running/paused` -> unified countdown)
- Menu bar icon/text scaling and custom font fallback (`font-maple-mono-nf-cn` -> `Monaco` -> system fallback)
- Settings persistence for prompt text, interval, durations, and stand-up frequency
- Sleep/wake pause-resume hooks via `SmartModeMonitor`

### Partially Wired / Not Wired Yet

- Fullscreen defer path exists in `SmartModeMonitor` but fullscreen signal wiring is not completed
- Custom prompt text is persisted, but overlay title still uses fixed copy
- `RecordStore` and daily stats APIs exist, but are not fully connected to runtime reminder outcomes

See [docs/feature-status.md](docs/feature-status.md) for a detailed matrix.

## Quick Start

### Requirements

- macOS
- Xcode 26.x or newer

### Open in Xcode

1. Open `PauseNow.xcodeproj`
2. Select scheme `PauseNow`
3. Run on `My Mac`

## Build

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -configuration Debug build
```

## Test

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' test
```

If local signing causes test failures, use:

```bash
xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test
```

## Documentation Map

- [README.zh-CN.md](README.zh-CN.md): Chinese README
- [docs/release-checklist.md](docs/release-checklist.md): release and publishing checks
- [docs/repository-structure.md](docs/repository-structure.md): codebase structure and flow guide
- [docs/development.md](docs/development.md): local development workflow and troubleshooting
- [docs/feature-status.md](docs/feature-status.md): implemented vs partial vs planned features

## Repository Hygiene

- Keep `PauseNow.xcodeproj` tracked for reproducible builds.
- Do not track user-private Xcode artifacts (`xcuserdata`, `*.xcuserstate`, etc.).
- Keep local planning files under `docs/plans/` (ignored by `.gitignore`).
