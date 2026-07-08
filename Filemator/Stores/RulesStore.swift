import Foundation

final class RulesStore {
    private let fileURL: URL

    init(fileURL: URL = RulesStore.defaultFileURL) {
        self.fileURL = fileURL
    }

    static var defaultFileURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Filemator")
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        return supportDir.appendingPathComponent("rules.json")
    }

    func load() -> [Rule] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Rule].self, from: data)) ?? []
    }

    func save(_ rules: [Rule]) {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        try? data.write(to: fileURL)
    }
}
