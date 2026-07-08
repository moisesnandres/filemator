import SwiftUI

struct MainWindowView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        TabView {
            RulesView(appState: appState)
                .tabItem { Label("Rules", systemImage: "list.bullet") }
        }
        .frame(minWidth: 480, minHeight: 360)
    }
}
