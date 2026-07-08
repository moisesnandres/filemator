import Foundation

final class WatchedFoldersStore {
    private let fileURL: URL

    init(fileURL: URL = WatchedFoldersStore.defaultFileURL) {
        self.fileURL = fileURL
    }

    static var defaultFileURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Filemator")
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        return supportDir.appendingPathComponent("watchedFolders.json")
    }

    func load() -> [WatchedFolder] {
        guard let data = try? Data(contentsOf: fileURL) else {
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            return [WatchedFolder(path: downloadsURL)]
        }
        return (try? JSONDecoder().decode([WatchedFolder].self, from: data)) ?? []
    }

    func save(_ folders: [WatchedFolder]) {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        try? data.write(to: fileURL)
    }
}
