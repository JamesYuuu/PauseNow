import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PauseNow")
                .font(.title)
                .fontWeight(.semibold)

            Text("专注于护眼与起身提醒的 macOS 菜单栏应用。")
                .foregroundStyle(.secondary)

            Divider()

            Text("当前包含：20-20-20 护眼提醒、周期性大休息、全屏提醒与状态栏倒计时。")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
    }
}
