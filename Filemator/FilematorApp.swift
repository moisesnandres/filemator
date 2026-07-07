import SwiftUI

@main
struct FilematorApp: App {
    @StateObject private var appState: AppState

    init() {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let pdfDestination = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/Filemator-PDFs")
        let hardcodedRule = Rule(name: "PDFs", extensions: ["pdf"], nameContains: nil, destination: pdfDestination)

        let state = AppState(watchedFolderURL: downloadsURL, rules: [hardcodedRule])
        _appState = StateObject(wrappedValue: state)
        state.start()
    }

    var body: some Scene {
        MenuBarExtra("Filemator", systemImage: "tray.and.arrow.down") {
            MenuBarView(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}
