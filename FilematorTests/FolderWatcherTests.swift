import XCTest
@testable import Filemator

final class FolderWatcherTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_start_firesCallback_whenNewFileAppears() throws {
        let expectation = expectation(description: "new file detected")
        var detectedURL: URL?

        let watcher = FolderWatcher(folderURL: tempDir, debounceInterval: 0.1) { url in
            detectedURL = url
            expectation.fulfill()
        }
        watcher.start()
        defer { watcher.stop() }

        let fileURL = tempDir.appendingPathComponent("report.pdf")
        try "hello".write(to: fileURL, atomically: true, encoding: .utf8)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(detectedURL?.lastPathComponent, "report.pdf")
    }

    func test_start_ignoresPartialDownloadExtensions_untilRenamedToFinalName() throws {
        let expectation = expectation(description: "final file detected")
        var callbackCount = 0
        var detectedURL: URL?

        let watcher = FolderWatcher(folderURL: tempDir, debounceInterval: 0.1) { url in
            callbackCount += 1
            detectedURL = url
            expectation.fulfill()
        }
        watcher.start()
        defer { watcher.stop() }

        let partialURL = tempDir.appendingPathComponent("report.pdf.crdownload")
        try "partial".write(to: partialURL, atomically: true, encoding: .utf8)

        let finalURL = tempDir.appendingPathComponent("report.pdf")
        try FileManager.default.moveItem(at: partialURL, to: finalURL)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(callbackCount, 1)
        XCTAssertEqual(detectedURL?.lastPathComponent, "report.pdf")
    }
}
