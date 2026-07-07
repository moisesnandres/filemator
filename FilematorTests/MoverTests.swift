import XCTest
@testable import Filemator

final class MoverTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_move_movesFileToDestinationDirectory_creatingItIfMissing() throws {
        let source = tempDir.appendingPathComponent("report.pdf")
        try "hello".write(to: source, atomically: true, encoding: .utf8)
        let destinationDir = tempDir.appendingPathComponent("PDFs")

        let result = try Mover.move(from: source, toDirectory: destinationDir)

        XCTAssertEqual(result, destinationDir.appendingPathComponent("report.pdf"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
    }

    func test_move_autoRenames_onNameCollision() throws {
        let destinationDir = tempDir.appendingPathComponent("PDFs")
        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        try "existing".write(to: destinationDir.appendingPathComponent("report.pdf"), atomically: true, encoding: .utf8)

        let source = tempDir.appendingPathComponent("report.pdf")
        try "new".write(to: source, atomically: true, encoding: .utf8)

        let result = try Mover.move(from: source, toDirectory: destinationDir)

        XCTAssertEqual(result.lastPathComponent, "report (2).pdf")
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationDir.appendingPathComponent("report.pdf").path))
    }
}
