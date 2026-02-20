import AppKit
import SwiftUI

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let homeViewModel = HomeViewModel()

    var hasStatusItem: Bool { statusItem != nil }

    override init() {}

    func setup(
        onPrimaryAction: (() -> Void)? = nil,
        onOpenAbout: (() -> Void)? = nil,
        onQuit: (() -> Void)? = nil,
        onManualBreak: (() -> Void)? = nil,
        onReset: (() -> Void)? = nil
    ) {
        homeViewModel.onPrimaryAction = onPrimaryAction
        homeViewModel.onOpenAbout = onOpenAbout
        homeViewModel.onQuit = onQuit
        homeViewModel.onManualBreak = onManualBreak
        homeViewModel.onReset = onReset

        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }

        if let button = statusItem?.button, button.target == nil {
            button.image = statusBarIcon()
            button.imagePosition = .imageLeading
            button.title = MenuBarTextFormatter.idleText
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 360)
        popover.contentViewController = NSHostingController(rootView: HomePopoverView(viewModel: homeViewModel))
    }

    func setRunningState(_ isRunning: Bool) {
        _ = isRunning
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

    func updateHome(model: HomeDisplayModel) {
        homeViewModel.apply(model: model)
    }

    func setPausedState(_ isPaused: Bool) {
        _ = isPaused
    }

    private func statusBarIcon() -> NSImage? {
        let fallbackNames = ["desktopcomputer", "display", "laptopcomputer"]
        for name in fallbackNames {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: "PauseNow") {
                image.isTemplate = true
                return image
            }
        }

        return nil
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
