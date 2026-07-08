import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var historyStore: HistoryStore

    init(appState: AppState) {
        self.appState = appState
        self.historyStore = appState.historyStore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appState.isRunning ? "● Running" : "○ Stopped")
                .font(.headline)

            Divider()

            if historyStore.entries.isEmpty {
                Text("No files moved yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(historyStore.entries.prefix(3)) { entry in
                    Text("\(entry.sourcePath.lastPathComponent) → \(entry.destinationPath.deletingLastPathComponent().lastPathComponent)")
                        .font(.caption)
                }
            }

            Divider()

            Button("Quit Filemator") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
        .frame(width: 260)
    }
}
