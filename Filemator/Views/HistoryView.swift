import SwiftUI

struct HistoryView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var historyStore: HistoryStore
    @State private var undoError: String?

    init(appState: AppState) {
        self.appState = appState
        self.historyStore = appState.historyStore
    }

    var body: some View {
        List(historyStore.entries) { entry in
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.sourcePath.lastPathComponent).font(.headline)
                    Text(statusDescription(entry)).font(.caption).foregroundStyle(statusColor(entry))
                }
                Spacer()
                if case .success = entry.status {
                    Button("Undo") {
                        do {
                            try appState.undo(entry)
                        } catch {
                            undoError = error.localizedDescription
                        }
                    }
                }
            }
        }
        .alert("Couldn't Undo", isPresented: .constant(undoError != nil), presenting: undoError) { _ in
            Button("OK") { undoError = nil }
        } message: { message in
            Text(message)
        }
    }

    private func statusDescription(_ entry: HistoryEntry) -> String {
        switch entry.status {
        case .success:
            return "Moved via \"\(entry.ruleName)\" to \(entry.destinationPath.deletingLastPathComponent().lastPathComponent)"
        case .failed(let reason):
            return "Failed: \(reason)"
        case .undone:
            return "Undone"
        }
    }

    private func statusColor(_ entry: HistoryEntry) -> Color {
        switch entry.status {
        case .success: return .secondary
        case .failed: return .red
        case .undone: return .secondary
        }
    }
}
