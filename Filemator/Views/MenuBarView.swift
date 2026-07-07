import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appState.isRunning ? "● Running" : "○ Stopped")
                .font(.headline)

            Divider()

            if appState.recentHistory.isEmpty {
                Text("No files moved yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appState.recentHistory) { entry in
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
