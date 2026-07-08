import SwiftUI

@main
struct FilematorApp: App {
    @StateObject private var appState: AppState

    init() {
        let rulesStore = RulesStore()
        let rulesFileExists = FileManager.default.fileExists(atPath: RulesStore.defaultFileURL.path)
        if !rulesFileExists {
            let pdfDestination = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Filemator-PDFs")
            rulesStore.save([Rule(name: "PDFs", extensions: ["pdf"], nameContains: nil, destination: pdfDestination)])
        }

        let state = AppState(rulesStore: rulesStore)
        _appState = StateObject(wrappedValue: state)
        state.start()
    }

    var body: some Scene {
        MenuBarExtra("Filemator", systemImage: "tray.and.arrow.down") {
            MenuBarView(appState: appState)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("Filemator", id: "main") {
            MainWindowView(appState: appState)
        }
    }
}
