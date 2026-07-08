import XCTest
@testable import Filemator

final class HistoryStoreTests: XCTestCase {
    var tempFileURL: URL!

    override func setUpWithError() throws {
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    func test_add_insertsAtFront_andPersists() {
        let store = HistoryStore(fileURL: tempFileURL)
        let entry = HistoryEntry(sourcePath: URL(fileURLWithPath: "/tmp/a.pdf"), destinationPath: URL(fileURLWithPath: "/tmp/dest/a.pdf"), ruleName: "PDFs", timestamp: Date(timeIntervalSince1970: 0), status: .success)

        store.add(entry)

        XCTAssertEqual(store.entries, [entry])

        let reloaded = HistoryStore(fileURL: tempFileURL)
        XCTAssertEqual(reloaded.entries, [entry])
    }

    func test_update_replacesEntryWithMatchingID_andPersists() {
        let store = HistoryStore(fileURL: tempFileURL)
        var entry = HistoryEntry(sourcePath: URL(fileURLWithPath: "/tmp/a.pdf"), destinationPath: URL(fileURLWithPath: "/tmp/dest/a.pdf"), ruleName: "PDFs", timestamp: Date(timeIntervalSince1970: 0), status: .success)
        store.add(entry)

        entry.status = .undone
        store.update(entry)

        XCTAssertEqual(store.entries.first?.status, .undone)

        let reloaded = HistoryStore(fileURL: tempFileURL)
        XCTAssertEqual(reloaded.entries.first?.status, .undone)
    }
}
