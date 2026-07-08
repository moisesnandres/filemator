import SwiftUI

struct RulesView: View {
    @ObservedObject var appState: AppState
    @State private var editingRule: Rule?
    @State private var isPresentingEditor = false

    var body: some View {
        VStack {
            List {
                ForEach(appState.rules) { rule in
                    Button {
                        editingRule = rule
                        isPresentingEditor = true
                    } label: {
                        VStack(alignment: .leading) {
                            Text(rule.name).font(.headline)
                            Text(ruleSummary(rule)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onMove(perform: moveRules)
                .onDelete(perform: deleteRules)
            }

            Button("Add Rule") {
                editingRule = nil
                isPresentingEditor = true
            }
            .padding(.bottom)
        }
        .sheet(isPresented: $isPresentingEditor) {
            RuleEditorView(rule: editingRule) { savedRule in
                saveRule(savedRule)
            }
        }
    }

    private func ruleSummary(_ rule: Rule) -> String {
        var parts: [String] = []
        if !rule.extensions.isEmpty { parts.append(rule.extensions.joined(separator: ", ")) }
        if let nameContains = rule.nameContains, !nameContains.isEmpty { parts.append("contains \"\(nameContains)\"") }
        parts.append("→ \(rule.destination.lastPathComponent)")
        return parts.joined(separator: " · ")
    }

    private func saveRule(_ rule: Rule) {
        var updated = appState.rules
        if let index = updated.firstIndex(where: { $0.id == rule.id }) {
            updated[index] = rule
        } else {
            updated.append(rule)
        }
        appState.setRules(updated)
    }

    private func moveRules(from source: IndexSet, to destination: Int) {
        var updated = appState.rules
        updated.move(fromOffsets: source, toOffset: destination)
        appState.setRules(updated)
    }

    private func deleteRules(at offsets: IndexSet) {
        var updated = appState.rules
        updated.remove(atOffsets: offsets)
        appState.setRules(updated)
    }
}
