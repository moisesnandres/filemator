import Foundation

enum MoveStatus: Codable, Equatable {
    case success
    case failed(reason: String)
    case undone
}

struct HistoryEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var sourcePath: URL
    var destinationPath: URL
    var ruleName: String
    var timestamp: Date
    var status: MoveStatus
}
