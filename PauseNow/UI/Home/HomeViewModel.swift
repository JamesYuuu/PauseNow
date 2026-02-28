import Foundation
import Combine

struct HomeViewActions {
    let onPrimaryAction: (() -> Void)?
    let onOpenAbout: (() -> Void)?
    let onOpenSettings: (() -> Void)?
    let onQuit: (() -> Void)?
    let onManualBreak: (() -> Void)?
    let onReset: (() -> Void)?

    static let empty = HomeViewActions(
        onPrimaryAction: nil,
        onOpenAbout: nil,
        onOpenSettings: nil,
        onQuit: nil,
        onManualBreak: nil,
        onReset: nil
    )
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var remainingText: String = "00:00"
    @Published var sandProgress: Double = 1
    @Published var isFlowing: Bool = false

    private var actions: HomeViewActions = .empty

    nonisolated deinit {}

    func configure(actions: HomeViewActions) {
        self.actions = actions
    }

    func apply(model: HomeDisplayModel) {
        remainingText = model.remainingText
        sandProgress = model.sandProgress
        isFlowing = model.isFlowing
    }

    func triggerPrimaryAction() {
        actions.onPrimaryAction?()
    }

    func triggerOpenAbout() {
        actions.onOpenAbout?()
    }

    func triggerOpenSettings(openSystemSettings: () -> Void) {
        actions.onOpenSettings?()
        openSystemSettings()
    }

    func triggerQuit() {
        actions.onQuit?()
    }

    func triggerManualBreak() {
        actions.onManualBreak?()
    }

    func triggerReset() {
        actions.onReset?()
    }
}
