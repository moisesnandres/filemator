import Combine
import XCTest
@testable import Filemator

final class AppStateApplyRulesTests: XCTestCase {
    var tempDir: URL!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        cancellables = []
    }

    override func tearDownWithError() throws {
        cancellables = []
        try? FileManager.default.removeItem(at: tempDir)
    }

    @MainActor
    func test_applyRules_movesMatchingFile_andRecordsSuccessEntry() throws {
        let watchedDir = tempDir.appendingPathComponent("Watched")
        try FileManager.default.createDirectory(at: watchedDir, withIntermediateDirectories: true)
        let destinationDir = tempDir.appendingPathComponent("Destination")

        let foldersStore = WatchedFoldersStore(fileURL: tempDir.appendingPathComponent("folders.json"))
        foldersStore.save([WatchedFolder(path: watchedDir)])

        let rulesStore = RulesStore(fileURL: tempDir.appendingPathComponent("rules.json"))
        let rule = Rule(name: "TXT", extensions: ["txt"], nameContains: nil, destination: destinationDir)
        rulesStore.save([rule])

        let historyStore = HistoryStore(fileURL: tempDir.appendingPathComponent("history.json"))

        let appState = AppState(rulesStore: rulesStore, watchedFoldersStore: foldersStore, historyStore: historyStore)
        appState.start()
        defer { appState.stop() }

        let expectation = expectation(description: "history entry recorded")
        historyStore.$entries
            .sink { entries in
                if !entries.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let sourceFile = watchedDir.appendingPathComponent("report.txt")
        try "hello".write(to: sourceFile, atomically: true, encoding: .utf8)

        wait(for: [expectation], timeout: 3.0)

        XCTAssertEqual(historyStore.entries.count, 1)
        let entry = try XCTUnwrap(historyStore.entries.first)
        XCTAssertEqual(entry.status, .success)
        XCTAssertEqual(entry.sourcePath.path, sourceFile.path)
        XCTAssertEqual(entry.destinationPath.path, destinationDir.appendingPathComponent("report.txt").path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: entry.destinationPath.path))
    }

    @MainActor
    func test_applyRules_recordsFailedEntry_whenDestinationCannotBeCreated() throws {
        let watchedDir = tempDir.appendingPathComponent("Watched")
        try FileManager.default.createDirectory(at: watchedDir, withIntermediateDirectories: true)

        // Pre-create the rule's "destination directory" as a regular file, so Mover's
        // attempt to move a file into it fails (its parent is not actually a directory).
        let destinationDir = tempDir.appendingPathComponent("Destination")
        try "not a directory".write(to: destinationDir, atomically: true, encoding: .utf8)

        let foldersStore = WatchedFoldersStore(fileURL: tempDir.appendingPathComponent("folders.json"))
        foldersStore.save([WatchedFolder(path: watchedDir)])

        let rulesStore = RulesStore(fileURL: tempDir.appendingPathComponent("rules.json"))
        let rule = Rule(name: "TXT", extensions: ["txt"], nameContains: nil, destination: destinationDir)
        rulesStore.save([rule])

        let historyStore = HistoryStore(fileURL: tempDir.appendingPathComponent("history.json"))

        let appState = AppState(rulesStore: rulesStore, watchedFoldersStore: foldersStore, historyStore: historyStore)
        appState.start()
        defer { appState.stop() }

        let expectation = expectation(description: "failed history entry recorded")
        historyStore.$entries
            .sink { entries in
                if !entries.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let sourceFile = watchedDir.appendingPathComponent("report.txt")
        try "hello".write(to: sourceFile, atomically: true, encoding: .utf8)

        wait(for: [expectation], timeout: 3.0)

        XCTAssertEqual(historyStore.entries.count, 1)
        let entry = try XCTUnwrap(historyStore.entries.first)
        guard case .failed = entry.status else {
            XCTFail("Expected a .failed status, got \(entry.status)")
            return
        }
        XCTAssertEqual(entry.sourcePath.path, sourceFile.path)
        // The source file should still exist at its original location since the move failed.
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceFile.path))
    }
}
