import Foundation

/// Resilient resource-bundle path resolution — the app's replacement for SPM's
/// generated `Bundle.module` accessor.
///
/// Why this exists: the generated `Bundle.module` for an executable target
/// checks only two paths — `Bundle.main.bundleURL` + bundle name (the `.app`
/// ROOT, but we package resources into `Contents/Resources`), and a *hardcoded
/// absolute build-machine path* (in a CI-built DMG that's the runner's path,
/// nonexistent on any user's Mac). When both miss it calls `fatalError`, which
/// can't be caught — so a distributed app crashes the instant a provider icon
/// renders. This picks the first candidate that actually exists and returns nil
/// rather than trapping, so callers can fall back gracefully.
public enum ResourceBundleLocator {
    /// The first candidate URL that exists on disk, or nil. Pure (the
    /// filesystem check is injectable) so the precedence and the
    /// nil-instead-of-trap behaviour can be unit-tested.
    public static func firstExisting(
        _ candidates: [URL],
        fileExists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }
    ) -> URL? {
        candidates.first(where: fileExists)
    }
}
