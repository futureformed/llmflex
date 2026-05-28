import Foundation

/// Detects and removes leftover artifacts written by the previous broken
/// "SwitchCode" build of this app, so a fresh LLM Flex apply lands cleanly.
/// Specifically: a `[model_providers.switchcode]` section, the SwitchCode
/// managed-block comment markers, and any orphan `SWITCHCODE_API_KEY` line
/// inside an `[env]` table.
public struct SwitchCodeCleanup: Sendable {
    public init() {}

    private static let oldStartMarker = "# === LLM Flex managed block START — do not edit by hand ===" // same — handled by current editor; included for future-proofing
    private static let switchCodeMarkers = [
        "# SwitchCode provider configuration",
    ]
    private static let switchCodeSections = [
        "[model_providers.switchcode]",
    ]
    private static let switchCodeEnvKey = "SWITCHCODE_API_KEY"

    public func needsCleanup(_ content: String) -> Bool {
        if content.contains(Self.switchCodeSections[0]) { return true }
        if content.contains(Self.switchCodeEnvKey) { return true }
        for m in Self.switchCodeMarkers where content.contains(m) { return true }
        return false
    }

    /// Remove the legacy `[model_providers.switchcode]` section, the orphan
    /// `SWITCHCODE_API_KEY = "..."` line, and the marker comments. Other
    /// sections of the file are preserved.
    public func clean(_ content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        var out: [String] = []
        var skipSection = false
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Section start: decide whether to skip until the next section.
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let name = trimmed.dropFirst().dropLast().trimmingCharacters(in: .whitespaces)
                skipSection = name.hasPrefix("model_providers.switchcode")
                if skipSection { continue }
            } else if skipSection {
                continue
            }

            if Self.switchCodeMarkers.contains(trimmed) { continue }
            if trimmed.hasPrefix(Self.switchCodeEnvKey) { continue }

            out.append(line)
        }
        // Collapse any runs of more than two consecutive blank lines.
        return collapseBlankRuns(out).joined(separator: "\n")
    }

    private func collapseBlankRuns(_ lines: [String]) -> [String] {
        var out: [String] = []
        var blanks = 0
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                blanks += 1
                if blanks <= 1 { out.append(line) }
            } else {
                blanks = 0
                out.append(line)
            }
        }
        return out
    }
}
