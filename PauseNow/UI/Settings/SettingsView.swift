import SwiftUI

struct SettingsView: View {
    @State private var promptText: String
    @State private var eyeBreakIntervalMinutes: Int
    @State private var eyeBreakSeconds: Int
    @State private var standupEveryEyeBreaks: Int
    @State private var standupSeconds: Int
    @State private var editingField: EditableField?
    @State private var draftValue: String = ""
    @State private var activeEditorFrame: CGRect = .zero
    @FocusState private var focusedField: EditableField?
    private let onSave: (String, Int, Int, Int, Int) -> Void

    init(
        initialPrompt: String,
        initialEyeBreakIntervalMinutes: Int,
        initialEyeBreakSeconds: Int,
        initialStandupEveryEyeBreaks: Int,
        initialStandupSeconds: Int,
        onSave: @escaping (String, Int, Int, Int, Int) -> Void
    ) {
        _promptText = State(initialValue: initialPrompt)
        _eyeBreakIntervalMinutes = State(initialValue: initialEyeBreakIntervalMinutes)
        _eyeBreakSeconds = State(initialValue: initialEyeBreakSeconds)
        _standupEveryEyeBreaks = State(initialValue: initialStandupEveryEyeBreaks)
        _standupSeconds = State(initialValue: initialStandupSeconds)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("提示内容") {
                editableRow(title: "默认提示语", value: promptText, field: .prompt)
            }

            Section("提醒节奏") {
                editableRow(
                    title: "单次休息间隔（分钟）",
                    value: "\(eyeBreakIntervalMinutes)",
                    field: .eyeBreakIntervalMinutes
                )

                editableRow(
                    title: "几次休息触发大休息",
                    value: "\(standupEveryEyeBreaks)",
                    field: .standupEveryEyeBreaks
                )
            }

            Section("提醒时长") {
                editableRow(
                    title: "单次小休息时间（秒）",
                    value: "\(eyeBreakSeconds)",
                    field: .eyeBreakSeconds
                )

                editableRow(
                    title: "大休息时间（秒）",
                    value: "\(standupSeconds)",
                    field: .standupSeconds
                )
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .coordinateSpace(name: "settingsForm")
        .simultaneousGesture(
            SpatialTapGesture().onEnded { value in
                guard let current = editingField else { return }
                let hitFrame = activeEditorFrame.insetBy(dx: -6, dy: -6)
                if !hitFrame.contains(value.location) {
                    commit(field: current)
                }
            }
        )
        .onChange(of: editingField) { _, newValue in
            guard let newValue else {
                focusedField = nil
                return
            }
            focusedField = newValue
        }
        .onChange(of: focusedField) { _, newValue in
            guard let current = editingField else { return }
            if newValue != current {
                commit(field: current)
            }
        }
    }

    @ViewBuilder
    private func editableRow(title: String, value: String, field: EditableField) -> some View {
        HStack {
            Text(title)
            Spacer()

            if editingField == field {
                TextField("", text: $draftValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .focused($focusedField, equals: field)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ActiveEditorFramePreferenceKey.self,
                                value: proxy.frame(in: .named("settingsForm"))
                            )
                        }
                    )
                    .onSubmit {
                        commit(field: field)
                    }
            } else {
                Text(value)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        draftValue = currentValue(for: field)
                        editingField = field
                    }
            }
        }
        .onPreferenceChange(ActiveEditorFramePreferenceKey.self) { frame in
            if editingField == field {
                activeEditorFrame = frame
            }
        }
    }

    private func currentValue(for field: EditableField) -> String {
        switch field {
        case .prompt:
            return promptText
        case .eyeBreakIntervalMinutes:
            return String(eyeBreakIntervalMinutes)
        case .standupEveryEyeBreaks:
            return String(standupEveryEyeBreaks)
        case .eyeBreakSeconds:
            return String(eyeBreakSeconds)
        case .standupSeconds:
            return String(standupSeconds)
        }
    }

    private func commit(field: EditableField) {
        switch field {
        case .prompt:
            promptText = draftValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if promptText.isEmpty {
                promptText = AppSettings.defaultPromptText
            }
        case .eyeBreakIntervalMinutes:
            eyeBreakIntervalMinutes = max(1, Int(draftValue) ?? eyeBreakIntervalMinutes)
        case .standupEveryEyeBreaks:
            standupEveryEyeBreaks = max(1, Int(draftValue) ?? standupEveryEyeBreaks)
        case .eyeBreakSeconds:
            eyeBreakSeconds = max(1, Int(draftValue) ?? eyeBreakSeconds)
        case .standupSeconds:
            standupSeconds = max(1, Int(draftValue) ?? standupSeconds)
        }

        onSave(
            promptText,
            eyeBreakIntervalMinutes,
            eyeBreakSeconds,
            standupEveryEyeBreaks,
            standupSeconds
        )
        focusedField = nil
        editingField = nil
    }
}

private struct ActiveEditorFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private enum EditableField: String, Identifiable {
    case prompt
    case eyeBreakIntervalMinutes
    case standupEveryEyeBreaks
    case eyeBreakSeconds
    case standupSeconds

    var id: String { rawValue }

}
