import SwiftUI

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.titleText)
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text("\(viewModel.remainingSeconds)s")
                .font(.system(size: 76, weight: .heavy, design: .rounded))
            Button("跳过") {
                onSkip()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
        }
        .foregroundStyle(.white)
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.82), Color.black.opacity(0.68)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
