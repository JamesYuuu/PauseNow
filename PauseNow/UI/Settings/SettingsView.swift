import SwiftUI

struct SettingsView: View {
    @State private var promptText: String
    private let onSave: (String) -> Void

    init(initialPrompt: String, onSave: @escaping (String) -> Void) {
        _promptText = State(initialValue: initialPrompt)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("默认提示语")
                .font(.headline)
            TextField("现在稍息！", text: $promptText)
            Button("保存") {
                onSave(promptText)
            }
        }
        .padding(16)
        .frame(width: 360)
    }
}
