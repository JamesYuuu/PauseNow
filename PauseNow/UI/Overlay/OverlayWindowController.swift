import AppKit
import SwiftUI

final class OverlayWindowController: NSWindowController, ReminderOverlayPresenting {
    private var activeViewModel: OverlayViewModel?

    func present(
        event: ReminderType,
        durationSeconds: Int,
        onSkip: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.present(event: event, durationSeconds: durationSeconds, onSkip: onSkip, onComplete: onComplete)
            }
            return
        }

        dismissOverlay()

        let viewModel = OverlayViewModel(type: event, seconds: durationSeconds)
        let root = OverlayView(viewModel: viewModel) { [weak self] in
            viewModel.skip()
            self?.dismissOverlay()
            onSkip()
        }

        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 720)
        let panel = NSPanel(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.ignoresMouseEvents = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(rootView: root)
        panel.makeKeyAndOrderFront(nil)

        self.window = panel
        self.activeViewModel = viewModel

        viewModel.startRealtimeCountdown { [weak self] in
            self?.dismissOverlay()
            onComplete()
        }
    }

    private func dismissOverlay() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.dismissOverlay()
            }
            return
        }
        window?.orderOut(nil)
        activeViewModel = nil
    }
}
