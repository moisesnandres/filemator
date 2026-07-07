import Foundation

struct Rule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var extensions: [String]
    var nameContains: String?
    var destination: URL
    var isEnabled: Bool = true

    func matches(fileURL: URL) -> Bool {
        guard isEnabled else { return false }

        if !extensions.isEmpty {
            let ext = fileURL.pathExtension.lowercased()
            guard extensions.contains(where: { $0.lowercased() == ext }) else {
                return false
            }
        }

        if let nameContains, !nameContains.isEmpty {
            let filename = fileURL.deletingPathExtension().lastPathComponent
            guard filename.localizedCaseInsensitiveContains(nameContains) else {
                return false
            }
        }

        return true
    }
}
