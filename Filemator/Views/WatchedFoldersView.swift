import SwiftUI
import AppKit

struct WatchedFoldersView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack {
            List {
                ForEach(appState.watchedFolders) { folder in
                    HStack {
                        Text(folder.path.path)
                        if appState.unavailableFolderIDs.contains(folder.id) {
                            Spacer()
                            Label("Unavailable", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }
                    .swipeActions {
                        Button("Remove", role: .destructive) {
                            appState.removeWatchedFolder(folder)
                        }
                    }
                }
            }

            Button("Add Folder…") {
                addFolder()
            }
            .padding(.bottom)
        }
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            appState.addWatchedFolder(url)
        }
    }
}
