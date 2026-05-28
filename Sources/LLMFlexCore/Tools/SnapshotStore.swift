import Foundation

/// Captures the user's original config files BEFORE LLM Flex touches them.
/// One snapshot per (tag, filename) pair, taken on first touch and preserved
/// forever. Restore reads back the snapshot to undo all of our changes —
/// independent of how much we mangled things in between.
public final class SnapshotStore: @unchecked Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    /// Default root: `~/Library/Application Support/LLMFlex/snapshots`.
    public static var defaultRoot: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LLMFlex/snapshots", isDirectory: true)
    }

    /// Copy `file` into `<root>/<tag>/<filename>` if no snapshot exists for
    /// that pair yet. Idempotent — safe to call before every write.
    public func captureIfAbsent(file: URL, tag: String) throws {
        try ensureDirectory()
        let dest = location(file: file, tag: tag)
        try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        guard !FileManager.default.fileExists(atPath: dest.path) else { return }
        guard FileManager.default.fileExists(atPath: file.path) else { return }
        try FileManager.default.copyItem(at: file, to: dest)
    }

    /// Restore `file` from its snapshot. Returns true if a snapshot existed
    /// and was used; false if no snapshot was found (caller's choice what to
    /// do — typically delete the file or leave it alone).
    @discardableResult
    public func restore(file: URL, tag: String) throws -> Bool {
        let src = location(file: file, tag: tag)
        guard FileManager.default.fileExists(atPath: src.path) else { return false }
        if FileManager.default.fileExists(atPath: file.path) {
            try FileManager.default.removeItem(at: file)
        }
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: src, to: file)
        return true
    }

    public func hasSnapshot(file: URL, tag: String) -> Bool {
        FileManager.default.fileExists(atPath: location(file: file, tag: tag).path)
    }

    public func clearSnapshots(tag: String) throws {
        let dir = root.appendingPathComponent(tag, isDirectory: true)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }

    /// Where the snapshot for `(file, tag)` lives on disk. Public so callers
    /// can mutate snapshot contents in place — e.g. retroactively cleaning
    /// up legacy artifacts so Restore gives a tidier baseline.
    public func snapshotURL(for file: URL, tag: String) -> URL {
        location(file: file, tag: tag)
    }

    private func location(file: URL, tag: String) -> URL {
        root.appendingPathComponent(tag, isDirectory: true)
            .appendingPathComponent(file.lastPathComponent)
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
}
