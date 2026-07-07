import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var recentHistory: [HistoryEntry] = []
    @Published private(set) var isRunning = false

    private let rules: [Rule]
    private let watchedFolderURL: URL
    private var watcher: FolderWatcher?

    init(watchedFolderURL: URL, rules: [Rule]) {
        self.watchedFolderURL = watchedFolderURL
        self.rules = rules
    }

    func start() {
        let watcher = FolderWatcher(folderURL: watchedFolderURL) { [weak self] fileURL in
            self?.handleNewFile(fileURL)
        }
        watcher.start()
        self.watcher = watcher
        isRunning = true
    }

    func stop() {
        watcher?.stop()
        watcher = nil
        isRunning = false
    }

    private func handleNewFile(_ fileURL: URL) {
        Task { @MainActor in
            self.applyRules(to: fileURL)
        }
    }

    private func applyRules(to fileURL: URL) {
        guard let rule = RuleEngine.firstMatch(for: fileURL, in: rules) else { return }

        do {
            let destination = try Mover.move(from: fileURL, toDirectory: rule.destination)
            record(HistoryEntry(sourcePath: fileURL, destinationPath: destination, ruleName: rule.name, timestamp: Date(), status: .success))
        } catch {
            record(HistoryEntry(sourcePath: fileURL, destinationPath: rule.destination, ruleName: rule.name, timestamp: Date(), status: .failed(reason: error.localizedDescription)))
        }
    }

    private func record(_ entry: HistoryEntry) {
        recentHistory.insert(entry, at: 0)
        if recentHistory.count > 3 {
            recentHistory.removeLast()
        }
    }
}
