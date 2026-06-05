import Foundation

/// The latest release as reported by the GitHub Releases API.
public struct LatestRelease: Equatable, Sendable {
    public let tagName: String
    public let htmlURL: URL

    public init(tagName: String, htmlURL: URL) {
        self.tagName = tagName
        self.htmlURL = htmlURL
    }
}

public enum UpdateCheckResult: Equatable, Sendable {
    case upToDate
    case updateAvailable(version: String, url: URL)
}

/// Polls GitHub's releases list and compares the newest published tag to the
/// running app's version. Purely a *notifier* — it never downloads or installs
/// anything; the banner links the user to the release page.
///
/// We hit the `/releases` *list* endpoint, not `/releases/latest`: the latter
/// excludes pre-releases, and every `0.x` build is published as a pre-release,
/// so `/latest` 404s for the whole alpha. The list includes pre-releases, and
/// we pick the highest semver tag ourselves.
///
/// Parsing and version comparison are pure static functions (unit-tested); the
/// live HTTP fetch is not, mirroring `ConnectivityTester`. Any failure
/// (offline, rate limit, no releases yet) resolves to "no update" so a flaky
/// network never nags the user.
public actor UpdateChecker {
    private let session: URLSession
    private let releasesURL: URL

    public static let defaultReleasesURL =
        URL(string: "https://api.github.com/repos/futureformed/llmflex/releases")!

    public init(
        session: URLSession = .shared,
        releasesURL: URL = UpdateChecker.defaultReleasesURL
    ) {
        self.session = session
        self.releasesURL = releasesURL
    }

    public func check(currentVersion: String) async -> UpdateCheckResult {
        var req = URLRequest(url: releasesURL, timeoutInterval: 8)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let newest = Self.newest(from: Self.parseReleases(data)) else {
                return .upToDate
            }
            return Self.evaluate(currentVersion: currentVersion, latest: newest)
        } catch {
            return .upToDate
        }
    }

    /// Pure: parse GitHub's releases-list JSON into tag + page URL, skipping
    /// drafts. Pre-releases are kept (alpha builds are published that way).
    public static func parseReleases(_ data: Data) -> [LatestRelease] {
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return arr.compactMap { obj in
            guard (obj["draft"] as? Bool) != true,
                  let tag = obj["tag_name"] as? String,
                  let html = obj["html_url"] as? String,
                  let url = URL(string: html) else {
                return nil
            }
            return LatestRelease(tagName: tag, htmlURL: url)
        }
    }

    /// Pure: the release with the highest semver tag. The list endpoint sorts
    /// by creation date, not version, so we pick explicitly. Tags that don't
    /// parse as semver are ignored.
    public static func newest(from releases: [LatestRelease]) -> LatestRelease? {
        releases
            .compactMap { r in SemanticVersion(r.tagName).map { ($0, r) } }
            .max { $0.0 < $1.0 }?
            .1
    }

    /// Pure: is `latest` newer than `currentVersion`? Unparseable versions on
    /// either side resolve to "up to date" so we never show a bogus prompt.
    public static func evaluate(currentVersion: String, latest: LatestRelease) -> UpdateCheckResult {
        guard let current = SemanticVersion(currentVersion),
              let remote = SemanticVersion(latest.tagName),
              remote > current else {
            return .upToDate
        }
        return .updateAvailable(version: latest.tagName, url: latest.htmlURL)
    }
}
