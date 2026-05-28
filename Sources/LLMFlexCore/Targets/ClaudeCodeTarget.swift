import Foundation

/// Claude Code target — covers the `claude` CLI and every IDE extension that
/// wraps it (VS Code, JetBrains, etc.). They all read the same settings file,
/// so one target serves all surfaces.
///
/// Mechanism:
/// - Edits `~/.claude/settings.json`, deep-merging our keys into the user's
///   existing JSON (preserves `permissions`, `hooks`, `apiKeyHelper`, etc.).
/// - Writes `model`, plus an `env` block with `ANTHROPIC_BASE_URL` and
///   `ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_API_KEY`.
/// - Claude Code watches this file and live-reloads most keys, so changes
///   propagate without restarting the CLI (model changes need `/model` or
///   a fresh session).
/// - No `launchctl setenv` needed: settings.json's env block is read by the
///   CLI itself when spawning subprocesses.
public final class ClaudeCodeTarget: Target, @unchecked Sendable {
    public let id: TargetID = .claudeCode
    public let displayName: String = "Claude Code"

    public static let snapshotTag = "claudeCode"
    public static let managedKeys = ["model"]
    public static let managedEnvKeys = ["ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_API_KEY"]

    public static var defaultSettingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }

    public let settingsURL: URL
    public let snapshots: SnapshotStore

    public init(
        settingsURL: URL = ClaudeCodeTarget.defaultSettingsURL,
        snapshots: SnapshotStore = SnapshotStore(root: SnapshotStore.defaultRoot)
    ) {
        self.settingsURL = settingsURL
        self.snapshots = snapshots
    }

    // MARK: - Inspect

    public func inspect() throws -> TargetStatus {
        let dict = readSettings()
        let model = dict["model"] as? String
        let envBlock = dict["env"] as? [String: Any] ?? [:]
        let baseURL = envBlock["ANTHROPIC_BASE_URL"] as? String
        let hasKey =
            (envBlock["ANTHROPIC_AUTH_TOKEN"] as? String).map { !$0.isEmpty } ?? false
            || (envBlock["ANTHROPIC_API_KEY"] as? String).map { !$0.isEmpty } ?? false

        // We consider a provider "active" if we (or the user) set ANTHROPIC_BASE_URL,
        // since that's the override mechanism. Without it, Claude Code defaults
        // to api.anthropic.com — that's also a valid "active" state.
        let providerKey: String? = (model != nil || baseURL != nil || hasKey) ? "claudeCode" : nil
        let effectiveBase = baseURL ?? "https://api.anthropic.com"
        return TargetStatus(
            target: .claudeCode,
            activeProviderKey: providerKey,
            activeProviderLabel: deriveProviderLabel(from: effectiveBase),
            activeModel: model,
            activeBaseURL: effectiveBase,
            authMode: hasKey ? .apiKey : .unauthed,
            applicationRunning: false
        )
    }

    // MARK: - Policy

    public func policy() throws -> ApplyPolicy {
        // No ChatGPT-token-style gotchas here. Always allowed.
        return .allowed
    }

    // MARK: - Apply

    public func apply(profile: Profile, apiKey: String) throws {
        if profile.provider.requiresAPIKey && apiKey.isEmpty {
            throw TargetError.noAPIKey
        }
        try snapshots.captureIfAbsent(file: settingsURL, tag: Self.snapshotTag)

        var dict = readSettings()
        if !profile.modelName.isEmpty {
            dict["model"] = profile.modelName
        }
        var env = dict["env"] as? [String: Any] ?? [:]
        // Claude Code expects ANTHROPIC_BASE_URL to be the gateway ROOT —
        // it appends /v1/messages itself. Our profile baseURL includes /v1
        // for the models-list / Test Connection path, so strip it here.
        env["ANTHROPIC_BASE_URL"] = Self.strippedGatewayRoot(from: profile.baseURL)
        // Anthropic's CLI warns when BOTH AUTH_TOKEN and API_KEY are set
        // because they take different code paths server-side. We pick the
        // correct one based on the provider's auth scheme and explicitly
        // remove the other to clear any stale value from a previous apply.
        if !apiKey.isEmpty {
            switch profile.provider.authScheme {
            case .anthropicHeaders:
                // Direct Anthropic API → x-api-key flavor.
                env["ANTHROPIC_API_KEY"] = apiKey
                env.removeValue(forKey: "ANTHROPIC_AUTH_TOKEN")
            case .bearer, .googleQueryParam:
                // Gateways (LiteLLM, Opencode Go, custom proxies) → Bearer.
                env["ANTHROPIC_AUTH_TOKEN"] = apiKey
                env.removeValue(forKey: "ANTHROPIC_API_KEY")
            }
        }
        dict["env"] = env

        try writeSettings(dict)
    }

    // MARK: - Restore

    @discardableResult
    public func restore() throws -> Bool {
        if try snapshots.restore(file: settingsURL, tag: Self.snapshotTag) {
            return true
        }
        // No snapshot — best-effort scrub of our managed keys.
        guard FileManager.default.fileExists(atPath: settingsURL.path) else { return false }
        var dict = readSettings()
        for key in Self.managedKeys { dict.removeValue(forKey: key) }
        if var env = dict["env"] as? [String: Any] {
            for key in Self.managedEnvKeys { env.removeValue(forKey: key) }
            if env.isEmpty {
                dict.removeValue(forKey: "env")
            } else {
                dict["env"] = env
            }
        }
        try writeSettings(dict)
        return false
    }

    // MARK: - IO helpers

    private func readSettings() -> [String: Any] {
        guard let data = try? Data(contentsOf: settingsURL),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return parsed
    }

    private func writeSettings(_ dict: [String: Any]) throws {
        let dir = settingsURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        do {
            let data = try JSONSerialization.data(
                withJSONObject: dict,
                // .withoutEscapingSlashes keeps URLs readable as
                // "https://api.anthropic.com/v1" instead of "https:\/\/…\/v1".
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            try data.write(to: settingsURL, options: .atomic)
        } catch {
            throw TargetError.ioFailure("Writing \(settingsURL.lastPathComponent)", underlying: error)
        }
    }

    /// Strip a trailing `/vN` (or `/vNbeta`, etc.) so the URL ends at the
    /// gateway root. Claude Code's ANTHROPIC_BASE_URL semantics:
    ///   `https://api.anthropic.com/v1`         → `https://api.anthropic.com`
    ///   `https://opencode.ai/zen/go/v1`        → `https://opencode.ai/zen/go`
    ///   `https://litellm-proxy:4000/v1beta`    → `https://litellm-proxy:4000`
    /// Already-stripped URLs pass through unchanged.
    static func strippedGatewayRoot(from url: String) -> String {
        var s = url
        while s.hasSuffix("/") { s.removeLast() }
        let pattern = #"/v\d+[a-z]*$"#
        if let range = s.range(of: pattern, options: .regularExpression) {
            s.removeSubrange(range)
        }
        return s
    }

    private func deriveProviderLabel(from baseURL: String) -> String? {
        if baseURL.contains("api.anthropic.com") { return "Anthropic" }
        if baseURL.contains("opencode.ai") { return "Opencode Go" }
        if baseURL.contains("localhost") || baseURL.contains("127.0.0.1") { return "Local" }
        return nil
    }
}
