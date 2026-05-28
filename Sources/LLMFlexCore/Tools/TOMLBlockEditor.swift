import Foundation

/// Maintains a single delimited "managed block" inside a TOML file. The block
/// is always written at the TOP of the file — critical for TOML semantics:
/// bare keys (like `model_provider = "..."`) after a `[section]` header are
/// parsed INTO that section, not as top-level keys. Putting the block at the
/// top guarantees top-level keys stay top-level.
///
/// Also optionally strips named top-level keys from the user's content to
/// prevent TOML duplicate-key errors (since TOML treats duplicate top-level
/// keys as a parse failure, not last-wins).
public struct TOMLBlockEditor: Sendable {
    public let startMarker: String
    public let endMarker: String

    public init(startMarker: String, endMarker: String) {
        self.startMarker = startMarker
        self.endMarker = endMarker
    }

    /// Replace any existing managed block in `source` with `block`, place it
    /// at the top, and strip listed top-level conflict keys.
    public func apply(
        source: String,
        block: String,
        stripTopLevelKeys: [String] = []
    ) -> String {
        let withoutBlock = strip(source: source)
        let withoutConflicts = stripTopLevel(keys: stripTopLevelKeys, from: withoutBlock)
        let trimmedRest = withoutConflicts.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedRest.isEmpty {
            return block + "\n"
        }
        return block + "\n\n" + trimmedRest + "\n"
    }

    public func strip(source: String) -> String {
        var out: [String] = []
        var inside = false
        for line in source.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == startMarker { inside = true; continue }
            if inside {
                if trimmed == endMarker { inside = false }
                continue
            }
            out.append(line)
        }
        while out.first?.trimmingCharacters(in: .whitespaces).isEmpty == true { out.removeFirst() }
        return out.joined(separator: "\n")
    }

    /// Drop top-level `key = ...` lines that appear BEFORE the first
    /// `[section]` header. Lines inside a `[section]` are untouched.
    public func stripTopLevel(keys: [String], from source: String) -> String {
        guard !keys.isEmpty else { return source }
        var out: [String] = []
        var sawSection = false
        for line in source.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                sawSection = true
                out.append(line)
                continue
            }
            if !sawSection, keys.contains(where: { matchesAssignment(line: trimmed, key: $0) }) {
                continue
            }
            out.append(line)
        }
        return out.joined(separator: "\n")
    }

    private func matchesAssignment(line: String, key: String) -> Bool {
        // Match `key = ...` or `key=...` exactly. Don't match `keysuffix = ...`.
        guard line.hasPrefix(key) else { return false }
        let after = line.dropFirst(key.count)
        let first = after.first
        return first == " " || first == "="
    }
}
