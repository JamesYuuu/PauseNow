# Repository Guidelines

## Project Structure & Module Organization
`PauseNow` is a macOS menu bar app built with SwiftUI + AppKit wiring.

- `PauseNow/`: app source
- `PauseNow/Core/`: scheduling and reminder runtime logic (`ReminderCoordinator`, `RuleEngine`, `TimerEngine`)
- `PauseNow/UI/`: feature UI by area (`MenuBar/`, `Home/`, `Settings/`, `Overlay/`)
- `PauseNow/Data/`: persistence and settings/record stores
- `PauseNowTests/`: XCTest suite
- `docs/`: development, feature status, release checklist, and structure docs
- `PauseNow.xcodeproj/`: shared project configuration

## Build, Test, and Development Commands
Use Xcode 26.x+ on macOS.

- `xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -configuration Debug build`
Builds the app from CLI for local verification.
- `xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' test`
Runs the full XCTest suite.
- `xcodebuild -project PauseNow.xcodeproj -scheme PauseNow -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test`
Fallback when local signing causes test failures.

## Coding Style & Naming Conventions
- Follow existing Swift style: 4-space indentation, one type per file, clear access control.
- Use `UpperCamelCase` for types and `lowerCamelCase` for properties/functions.
- Keep enums and state names descriptive (`ReminderRuntimeState.running`, `paused`, `stopped`).
- Name files after primary types (for example, `MenuBarController.swift`).
- No mandatory linter is configured; format consistently with Xcode defaults and surrounding code.

## Testing Guidelines
- Framework: `XCTest` in `PauseNowTests/`.
- Add or update tests for any logic change in `Core/`, `Data/`, or display mapping.
- Test names should describe behavior, starting with `test` (example: `testRuleEnginePrefersStandupOnBoundary`).
- Run CLI tests before opening a PR; include the command used in PR notes.

## Commit & Pull Request Guidelines
- Match current commit style: Conventional Commit prefixes like `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.
- Keep commits focused and scoped to one logical change.
- PRs should include:
  - short problem/solution summary
  - linked issue (if available)
  - test evidence (commands + results)
  - screenshots or recordings for menu bar, popover, or overlay UI changes

## Security & Configuration Tips
- Do not commit local Xcode user data (`xcuserdata`, `*.xcuserstate`) or build outputs.
- Keep local planning notes in `docs/plans/` (ignored by git).
