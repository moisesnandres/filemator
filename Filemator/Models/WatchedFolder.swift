import Foundation

struct WatchedFolder: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var path: URL
}
