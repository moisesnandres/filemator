import XCTest
@testable import Filemator

final class AppStateUndoTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    @MainActor
    func test_undo_movesFileBackToSourcePath_andMarksEntryUndone() throws {
        let sourcePath = tempDir.appendingPathComponent("report.pdf")
        let destinationDir = tempDir.appendingPathComponent("PDFs")
        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        let destinationPath = destinationDir.appendingPathComponent("report.pdf")
        try "hello".write(to: destinationPath, atomically: true, encoding: .utf8)

        let historyStore = HistoryStore(fileURL: tempDir.appendingPathComponent("history.json"))
        let entry = HistoryEntry(sourcePath: sourcePath, destinationPath: destinationPath, ruleName: "PDFs", timestamp: Date(), status: .success)
        historyStore.add(entry)

        let appState = AppState(
            rulesStore: RulesStore(fileURL: tempDir.appendingPathComponent("rules.json")),
            watchedFoldersStore: WatchedFoldersStore(fileURL: tempDir.appendingPathComponent("folders.json")),
            historyStore: historyStore
        )

        try appState.undo(entry)

        XCTAssertTrue(FileManager.default.fileExists(atPath: sourcePath.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destinationPath.path))
        XCTAssertEqual(historyStore.entries.first?.status, .undone)
    }

    @MainActor
    func test_undo_throws_whenSourcePathAlreadyOccupied() throws {
        let sourcePath = tempDir.appendingPathComponent("report.pdf")
        try "already here".write(to: sourcePath, atomically: true, encoding: .utf8)
        let destinationPath = tempDir.appendingPathComponent("PDFs/report.pdf")
        try FileManager.default.createDirectory(at: destinationPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "moved".write(to: destinationPath, atomically: true, encoding: .utf8)

        let historyStore = HistoryStore(fileURL: tempDir.appendingPathComponent("history.json"))
        let entry = HistoryEntry(sourcePath: sourcePath, destinationPath: destinationPath, ruleName: "PDFs", timestamp: Date(), status: .success)
        historyStore.add(entry)

        let appState = AppState(
            rulesStore: RulesStore(fileURL: tempDir.appendingPathComponent("rules.json")),
            watchedFoldersStore: WatchedFoldersStore(fileURL: tempDir.appendingPathComponent("folders.json")),
            historyStore: historyStore
        )

        XCTAssertThrowsError(try appState.undo(entry))
    }
}
