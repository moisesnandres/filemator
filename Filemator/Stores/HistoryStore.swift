import Combine
import Foundation

final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []

    private let fileURL: URL

    init(fileURL: URL = HistoryStore.defaultFileURL) {
        self.fileURL = fileURL
        entries = Self.load(from: fileURL)
    }

    static var defaultFileURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Filemator")
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        return supportDir.appendingPathComponent("history.json")
    }

    private static func load(from fileURL: URL) -> [HistoryEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([HistoryEntry].self, from: data)) ?? []
    }

    func add(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        persist()
    }

    func update(_ entry: HistoryEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL)
    }
}
