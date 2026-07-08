import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var rules: [Rule]
    @Published private(set) var watchedFolders: [WatchedFolder]

    let historyStore: HistoryStore

    private let rulesStore: RulesStore
    private let watchedFoldersStore: WatchedFoldersStore
    private var watchers: [UUID: FolderWatcher] = [:]

    init(
        rulesStore: RulesStore = RulesStore(),
        watchedFoldersStore: WatchedFoldersStore = WatchedFoldersStore(),
        historyStore: HistoryStore = HistoryStore()
    ) {
        self.rulesStore = rulesStore
        self.watchedFoldersStore = watchedFoldersStore
        self.historyStore = historyStore
        self.rules = rulesStore.load()
        self.watchedFolders = watchedFoldersStore.load()
    }

    func start() {
        for folder in watchedFolders {
            startWatching(folder)
        }
        isRunning = true
    }

    func stop() {
        watchers.values.forEach { $0.stop() }
        watchers.removeAll()
        isRunning = false
    }

    func setRules(_ newRules: [Rule]) {
        rules = newRules
        rulesStore.save(newRules)
    }

    func addWatchedFolder(_ path: URL) {
        let folder = WatchedFolder(path: path)
        watchedFolders.append(folder)
        watchedFoldersStore.save(watchedFolders)
        if isRunning {
            startWatching(folder)
        }
    }

    func removeWatchedFolder(_ folder: WatchedFolder) {
        watchers[folder.id]?.stop()
        watchers.removeValue(forKey: folder.id)
        watchedFolders.removeAll { $0.id == folder.id }
        watchedFoldersStore.save(watchedFolders)
    }

    private func startWatching(_ folder: WatchedFolder) {
        let watcher = FolderWatcher(folderURL: folder.path) { [weak self] fileURL in
            self?.handleNewFile(fileURL)
        }
        watcher.start()
        watchers[folder.id] = watcher
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
            historyStore.add(HistoryEntry(sourcePath: fileURL, destinationPath: destination, ruleName: rule.name, timestamp: Date(), status: .success))
        } catch {
            historyStore.add(HistoryEntry(sourcePath: fileURL, destinationPath: rule.destination, ruleName: rule.name, timestamp: Date(), status: .failed(reason: error.localizedDescription)))
        }
    }
}
