import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var remainingText: String = "00:00"
    @Published var sandProgress: Double = 1
    @Published var isFlowing: Bool = false

    var onPrimaryAction: (() -> Void)?
    var onOpenAbout: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    var onManualBreak: (() -> Void)?
    var onReset: (() -> Void)?

    nonisolated deinit {}

    func apply(model: HomeDisplayModel) {
        remainingText = model.remainingText
        sandProgress = model.sandProgress
        isFlowing = model.isFlowing
    }

    func triggerPrimaryAction() {
        onPrimaryAction?()
    }

    func openAbout() {
        onOpenAbout?()
    }

    func openSettings() {
        onOpenSettings?()
    }

    func openSettings(using openSettingsAction: () -> Void) {
        onOpenSettings?()
        openSettingsAction()
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

}
