import SwiftUI

struct HomePopoverView: View {
    @Environment(\.openSettings) private var openSettings
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Menu {
                    Button("关于 PauseNow") {
                        viewModel.triggerOpenAbout()
                    }
                    Button("设置") {
                        viewModel.triggerOpenSettings(openSystemSettings: { openSettings() })
                    }
                    Divider()
                    Button("退出") {
                        viewModel.triggerQuit()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
                .help("菜单")
            }

            HourglassButtonView(
                progress: viewModel.sandProgress,
                isFlowing: viewModel.isFlowing,
                remainingText: viewModel.remainingText,
                onTap: {
                    viewModel.triggerPrimaryAction()
                }
            )

            HStack(spacing: 10) {
                Button("休息") {
                    viewModel.triggerManualBreak()
                }
                .buttonStyle(.bordered)

                Button("重置") {
                    viewModel.triggerReset()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 320, height: 340)
        .background(
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.98, blue: 0.96), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
