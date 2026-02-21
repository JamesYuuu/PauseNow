import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    static let statusTextPointSize: CGFloat = 13
    static let statusIconPointSize: CGFloat = 15

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let homeViewModel = HomeViewModel()

    var hasStatusItem: Bool { statusItem != nil }

    override init() {}

    func setup(
        onPrimaryAction: (() -> Void)? = nil,
        onOpenAbout: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onQuit: (() -> Void)? = nil,
        onManualBreak: (() -> Void)? = nil,
        onReset: (() -> Void)? = nil
    ) {
        homeViewModel.onPrimaryAction = onPrimaryAction
        homeViewModel.onOpenAbout = onOpenAbout
        homeViewModel.onOpenSettings = onOpenSettings
        homeViewModel.onQuit = onQuit
        homeViewModel.onManualBreak = onManualBreak
        homeViewModel.onReset = onReset

        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }

        if let button = statusItem?.button {
            configureStatusButtonAppearance(button)
            button.imagePosition = .imageLeading
            button.title = MenuBarTextFormatter.countdownText(remaining: 0)
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 360)
        popover.contentViewController = NSHostingController(rootView: HomePopoverView(viewModel: homeViewModel))
    }

    func updateDisplay(state: MenuBarDisplayState) {
        let title: String
        switch state {
        case let .countdown(remaining):
            title = MenuBarTextFormatter.countdownText(remaining: remaining)
        }

        statusItem?.button?.title = title
    }

    func updateHome(model: HomeDisplayModel) {
        homeViewModel.apply(model: model)
    }

    private func statusBarIcon() -> NSImage? {
        let symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: Self.statusIconPointSize,
            weight: .semibold
        )
        let fallbackNames = ["desktopcomputer", "display", "laptopcomputer"]
        for name in fallbackNames {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: "PauseNow") {
                let configuredImage = image.withSymbolConfiguration(symbolConfiguration) ?? image
                configuredImage.isTemplate = true
                return configuredImage
            }
        }

        return nil
    }

    private func configureStatusButtonAppearance(_ button: NSStatusBarButton) {
        button.font = .systemFont(ofSize: Self.statusTextPointSize, weight: .semibold)
        button.image = statusBarIcon()
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
