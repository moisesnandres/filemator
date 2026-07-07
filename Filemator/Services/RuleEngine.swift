import Foundation

enum RuleEngine {
    static func firstMatch(for fileURL: URL, in rules: [Rule]) -> Rule? {
        rules.first { $0.matches(fileURL: fileURL) }
    }
}
