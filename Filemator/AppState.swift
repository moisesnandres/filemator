import Combine
import Foundation

enum UndoError: Error, LocalizedError {
    case sourceAlreadyOccupied
    case fileMissingAtDestination

    var errorDescription: String? {
        switch self {
        case .sourceAlreadyOccupied:
            return "A file already exists at the original location."
        case .fileMissingAtDestination:
            return "The moved file could not be found — it may have been renamed or deleted."
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var rules: [Rule]
    @Published private(set) var watchedFolders: [WatchedFolder]
    @Published private(set) var unavailableFolderIDs: Set<UUID> = []

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
        unavailableFolderIDs.remove(folder.id)
        watchedFoldersStore.save(watchedFolders)
    }

    func undo(_ entry: HistoryEntry) throws {
        guard case .success = entry.status else { return }

        if FileManager.default.fileExists(atPath: entry.sourcePath.path) {
            throw UndoError.sourceAlreadyOccupied
        }
        guard FileManager.default.fileExists(atPath: entry.destinationPath.path) else {
            throw UndoError.fileMissingAtDestination
        }

        try FileManager.default.moveItem(at: entry.destinationPath, to: entry.sourcePath)
        var updated = entry
        updated.status = .undone
        historyStore.update(updated)
    }

    private func startWatching(_ folder: WatchedFolder) {
        let watcher = FolderWatcher(
            folderURL: folder.path,
            onNewFile: { [weak self] fileURL in
                self?.handleNewFile(fileURL)
            },
            onUnavailable: { [weak self] in
                Task { @MainActor in
                    self?.unavailableFolderIDs.insert(folder.id)
                }
            }
        )
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
