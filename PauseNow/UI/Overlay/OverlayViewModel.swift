import Foundation
import Combine

final class OverlayViewModel: ObservableObject {
    let type: ReminderType
    let totalSeconds: Int

    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isCompleted = false
    @Published private(set) var isSkipped = false

    private var timer: Timer?

    var titleText: String {
        switch type {
        case .eyeBreak:
            return "现在稍息！看向远处"
        case .standup:
            return "现在稍息！起身活动"
        }
    }

    init(type: ReminderType, seconds: Int) {
        self.type = type
        self.totalSeconds = max(1, seconds)
        self.remainingSeconds = max(1, seconds)
    }

    func start() {
        timer?.invalidate()
        isCompleted = false
        isSkipped = false
        remainingSeconds = totalSeconds
    }

    func startRealtimeCountdown(onCompleted: @escaping () -> Void) {
        start()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else {
                t.invalidate()
                return
            }

            self.advance(by: 1)
            if self.isCompleted {
                t.invalidate()
                onCompleted()
            }
        }
    }

    func advance(by seconds: Int) {
        guard !isCompleted, !isSkipped, seconds > 0 else { return }
        remainingSeconds = max(0, remainingSeconds - seconds)
        if remainingSeconds == 0 {
            isCompleted = true
        }
    }

    func skip() {
        guard !isCompleted else { return }
        timer?.invalidate()
        isSkipped = true
    }

    deinit {
        timer?.invalidate()
    }
}
