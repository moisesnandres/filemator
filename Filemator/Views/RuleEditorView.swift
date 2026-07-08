import SwiftUI
import AppKit

struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var extensionsText: String
    @State private var nameContains: String
    @State private var destination: URL?

    private let originalID: UUID?
    private let onSave: (Rule) -> Void

    init(rule: Rule?, onSave: @escaping (Rule) -> Void) {
        self.originalID = rule?.id
        self.onSave = onSave
        _name = State(initialValue: rule?.name ?? "")
        _extensionsText = State(initialValue: rule?.extensions.joined(separator: ", ") ?? "")
        _nameContains = State(initialValue: rule?.nameContains ?? "")
        _destination = State(initialValue: rule?.destination)
    }

    var body: some View {
        Form {
            TextField("Rule name", text: $name)
            TextField("Extensions (comma-separated, blank = any)", text: $extensionsText)
            TextField("Filename contains (optional)", text: $nameContains)

            HStack {
                Text(destination?.path ?? "No destination chosen")
                    .foregroundStyle(destination == nil ? .secondary : .primary)
                Spacer()
                Button("Choose…") { chooseDestination() }
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") { save() }
                    .disabled(name.isEmpty || destination == nil)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private func chooseDestination() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            destination = panel.url
        }
    }

    private func save() {
        guard let destination else { return }
        let extensions = extensionsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let rule = Rule(
            id: originalID ?? UUID(),
            name: name,
            extensions: extensions,
            nameContains: nameContains.isEmpty ? nil : nameContains,
            destination: destination
        )
        onSave(rule)
        dismiss()
    }
}
