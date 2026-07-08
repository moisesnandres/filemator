import SwiftUI

struct MainWindowView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        TabView {
            RulesView(appState: appState)
                .tabItem { Label("Rules", systemImage: "list.bullet") }

            WatchedFoldersView(appState: appState)
                .tabItem { Label("Watched Folders", systemImage: "folder") }

            HistoryView(appState: appState)
                .tabItem { Label("History", systemImage: "clock") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .frame(minWidth: 480, minHeight: 360)
    }
}
