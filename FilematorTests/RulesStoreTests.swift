import XCTest
@testable import Filemator

final class RulesStoreTests: XCTestCase {
    var tempFileURL: URL!

    override func setUpWithError() throws {
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    func test_save_thenLoad_roundTripsRules() {
        let store = RulesStore(fileURL: tempFileURL)
        let rule = Rule(name: "PDFs", extensions: ["pdf"], nameContains: nil, destination: URL(fileURLWithPath: "/tmp/pdfs"))

        store.save([rule])
        let loaded = store.load()

        XCTAssertEqual(loaded, [rule])
    }

    func test_load_returnsEmptyArray_whenFileDoesNotExist() {
        let store = RulesStore(fileURL: tempFileURL)

        XCTAssertEqual(store.load(), [])
    }
}
