import SwiftUI

struct HourglassButtonView: View {
    let progress: Double
    let isFlowing: Bool
    let remainingText: String
    let onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Image(systemName: "hourglass")
                    .font(.system(size: 112, weight: .regular))
                    .foregroundStyle(Color.primary.opacity(0.66))

                Image(systemName: "hourglass.tophalf.filled")
                    .font(.system(size: 112, weight: .regular))
                    .foregroundStyle(Color.accentColor.opacity(0.85))
                    .opacity(max(0.08, progress))

                Image(systemName: "hourglass.bottomhalf.filled")
                    .font(.system(size: 112, weight: .regular))
                    .foregroundStyle(Color.accentColor.opacity(0.85))
                    .opacity(max(0.08, 1 - progress))

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 16)
                    .opacity(isFlowing ? (pulse ? 0.2 : 0.95) : 0.12)
            }
            .frame(width: 160, height: 200)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            Text(remainingText)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .onChange(of: isFlowing) { _, flowing in
            if flowing {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            } else {
                pulse = false
            }
        }
        .onAppear {
            if isFlowing {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}
