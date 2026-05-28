import XCTest
@testable import LLMFlexCore

final class SnapshotStoreTests: XCTestCase {
    var tmp: URL!
    var store: SnapshotStore!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LLMFlexTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        store = SnapshotStore(root: tmp.appendingPathComponent("snapshots"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmp)
    }

    private func writeTempFile(_ contents: String) throws -> URL {
        let url = tmp.appendingPathComponent("subject-\(UUID().uuidString).txt")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testCaptureOnceThenRestore() throws {
        let file = try writeTempFile("original")
        try store.captureIfAbsent(file: file, tag: "test")
        XCTAssertTrue(store.hasSnapshot(file: file, tag: "test"))

        // Mutate the file.
        try "modified".write(to: file, atomically: true, encoding: .utf8)

        // Second capture must be a no-op (preserves original).
        try store.captureIfAbsent(file: file, tag: "test")
        let restored = try store.restore(file: file, tag: "test")
        XCTAssertTrue(restored)
        let content = try String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(content, "original")
    }

    func testRestoreWithoutSnapshotReturnsFalse() throws {
        let file = try writeTempFile("only")
        let restored = try store.restore(file: file, tag: "nope")
        XCTAssertFalse(restored)
        let content = try String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(content, "only")
    }

    func testCaptureSkipsMissingSourceFile() throws {
        let missing = tmp.appendingPathComponent("nonexistent.txt")
        XCTAssertNoThrow(try store.captureIfAbsent(file: missing, tag: "x"))
        XCTAssertFalse(store.hasSnapshot(file: missing, tag: "x"))
    }
}
