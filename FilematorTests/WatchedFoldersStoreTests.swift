import XCTest
@testable import Filemator

final class WatchedFoldersStoreTests: XCTestCase {
    var tempFileURL: URL!

    override func setUpWithError() throws {
        tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    func test_save_thenLoad_roundTripsFolders() {
        let store = WatchedFoldersStore(fileURL: tempFileURL)
        let folder = WatchedFolder(path: URL(fileURLWithPath: "/tmp/watched"))

        store.save([folder])
        let loaded = store.load()

        XCTAssertEqual(loaded, [folder])
    }

    func test_load_seedsDownloadsFolder_whenFileDoesNotExist() {
        let store = WatchedFoldersStore(fileURL: tempFileURL)

        let loaded = store.load()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertTrue(loaded[0].path.path.hasSuffix("Downloads"))
    }
}
