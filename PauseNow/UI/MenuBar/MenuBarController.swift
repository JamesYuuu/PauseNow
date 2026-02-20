import AppKit

enum MenuBarTextFormatter {
    static let idleText = "休息中"

    static func runningText(remaining: TimeInterval) -> String {
        format(remaining)
    }

    static func pausedText(remaining: TimeInterval) -> String {
        "已暂停 \(format(remaining))"
    }

    private static func format(_ remaining: TimeInterval) -> String {
        let seconds = max(0, Int(remaining.rounded(.down)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

enum MenuBarDisplayState {
    case idle
    case running(remaining: TimeInterval)
    case paused(remaining: TimeInterval)
}

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var onStart: (() -> Void)?
    private var onPause: (() -> Void)?
    private var onResume: (() -> Void)?

    private weak var startItem: NSMenuItem?
    private weak var pauseItem: NSMenuItem?
    private weak var resumeItem: NSMenuItem?

    var hasStatusItem: Bool { statusItem != nil }

    override init() {}

    func setup(
        onStart: (() -> Void)? = nil,
        onPause: (() -> Void)? = nil,
        onResume: (() -> Void)? = nil
    ) {
        self.onStart = onStart
        self.onPause = onPause
        self.onResume = onResume

        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }

        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "figure.walk", accessibilityDescription: "PauseNow")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
            button.title = MenuBarTextFormatter.idleText
        }

        let menu = NSMenu()

        let startItem = NSMenuItem(title: "开始", action: #selector(startTapped), keyEquivalent: "s")
        startItem.target = self
        menu.addItem(startItem)

        let pauseItem = NSMenuItem(title: "暂停", action: #selector(pauseTapped), keyEquivalent: "p")
        pauseItem.target = self
        pauseItem.isEnabled = false
        menu.addItem(pauseItem)

        let resumeItem = NSMenuItem(title: "恢复", action: #selector(resumeTapped), keyEquivalent: "r")
        resumeItem.target = self
        resumeItem.isEnabled = false
        menu.addItem(resumeItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu

        self.startItem = startItem
        self.pauseItem = pauseItem
        self.resumeItem = resumeItem
    }

    func setRunningState(_ isRunning: Bool) {
        startItem?.isEnabled = !isRunning
        pauseItem?.isEnabled = isRunning
        resumeItem?.isEnabled = false
    }

    func updateDisplayIdle() {
        updateDisplay(state: .idle)
    }

    func updateDisplayRunning(remaining: TimeInterval) {
        updateDisplay(state: .running(remaining: remaining))
    }

    func updateDisplayPaused(remaining: TimeInterval) {
        updateDisplay(state: .paused(remaining: remaining))
    }

    func updateDisplay(state: MenuBarDisplayState) {
        let title: String
        switch state {
        case .idle:
            title = MenuBarTextFormatter.idleText
        case let .running(remaining):
            title = MenuBarTextFormatter.runningText(remaining: remaining)
        case let .paused(remaining):
            title = MenuBarTextFormatter.pausedText(remaining: remaining)
        }

        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.button?.title = title
        }
    }

    func setPausedState(_ isPaused: Bool) {
        startItem?.isEnabled = !isPaused
        pauseItem?.isEnabled = false
        resumeItem?.isEnabled = isPaused
    }

    @objc private func startTapped() {
        onStart?()
    }

    @objc private func pauseTapped() {
        onPause?()
    }

    @objc private func resumeTapped() {
        onResume?()
    }
}
