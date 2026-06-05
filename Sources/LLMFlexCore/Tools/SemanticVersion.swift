import Foundation

/// A minimal semver value used to compare the running app version against the
/// latest GitHub release. Comparison is numeric per component so `0.10.0`
/// correctly sorts above `0.9.0` (plain string comparison gets this wrong).
public struct SemanticVersion: Comparable, Equatable, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parse `"1.2.3"`, `"v1.2.3"`, `"0.1.0"`, or a partial `"1.2"` / `"1"`
    /// (missing components default to 0). A leading `v`/`V` is tolerated, and
    /// any pre-release/build metadata after `-` or `+` is dropped before
    /// comparison (e.g. `"1.2.3-beta"` parses as `1.2.3`). Returns nil when no
    /// numeric major component can be found, or a present component isn't a
    /// number.
    public init?(_ string: String) {
        var s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.first == "v" || s.first == "V" { s.removeFirst() }
        if let cut = s.firstIndex(where: { $0 == "-" || $0 == "+" }) {
            s = String(s[..<cut])
        }
        let comps = s.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false)
        guard let major = Int(comps[0]) else { return nil }
        let minor: Int? = comps.count > 1 ? Int(comps[1]) : 0
        let patch: Int? = comps.count > 2 ? Int(comps[2]) : 0
        guard let minor, let patch else { return nil }
        self.init(major: major, minor: minor, patch: patch)
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
