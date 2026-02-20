import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var remainingText: String = "00:00"
    @Published var sandProgress: Double = 1
    @Published var isFlowing: Bool = false

    var onPrimaryAction: (() -> Void)?
    var onOpenAbout: (() -> Void)?
    var onQuit: (() -> Void)?
    var onManualBreak: (() -> Void)?
    var onReset: (() -> Void)?

    nonisolated deinit {}

    func apply(displayState: MenuBarDisplayState, totalDuration: TimeInterval) {
        switch displayState {
        case .idle:
            remainingText = "00:00"
            sandProgress = 1
            isFlowing = false
        case let .running(remaining):
            remainingText = MenuBarTextFormatter.runningText(remaining: remaining)
            sandProgress = progress(remaining: remaining, totalDuration: totalDuration)
            isFlowing = true
        case let .paused(remaining):
            remainingText = MenuBarTextFormatter.runningText(remaining: remaining)
            sandProgress = progress(remaining: remaining, totalDuration: totalDuration)
            isFlowing = false
        }
    }

    func triggerPrimaryAction() {
        onPrimaryAction?()
    }

    func openAbout() {
        onOpenAbout?()
    }

    func quitApp() {
        onQuit?()
    }

    func takeBreakNow() {
        onManualBreak?()
    }

    func reset() {
        onReset?()
    }

    private func progress(remaining: TimeInterval, totalDuration: TimeInterval) -> Double {
        guard totalDuration > 0 else { return 0 }
        return min(1, max(0, remaining / totalDuration))
    }
}
