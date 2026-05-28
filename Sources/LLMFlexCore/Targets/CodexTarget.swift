import Foundation

/// Reads `~/.codex/auth.json` and classifies how Codex.app/CLI is currently
/// authenticated. The state determines whether LLM Flex can safely write a
/// new API key: Codex.app refreshes its ChatGPT tokens on every launch and
/// overwrites OPENAI_API_KEY, so chatgptLogin → switching blocked.
public struct CodexAuthStateDetector: Sendable {
    public let authURL: URL

    public init(authURL: URL = CodexTarget.defaultAuthURL) {
        self.authURL = authURL
    }

    public func detect() -> CodexAuthState {
        guard FileManager.default.fileExists(atPath: authURL.path) else {
            return .unauthed
        }
        guard let data = try? Data(contentsOf: authURL),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .unknown
        }
        return classify(obj)
    }

    /// Public for unit testing.
    public func classify(_ obj: [String: Any]) -> CodexAuthState {
        let hasTokens = (obj["tokens"] as? [String: Any])?.isEmpty == false
        let hasLastRefresh = (obj["last_refresh"] as? String).map { !$0.isEmpty } ?? false
        if hasTokens || hasLastRefresh {
            return .chatgptLogin
        }
        let keyPresent = (obj["OPENAI_API_KEY"] as? String).map { !$0.isEmpty } ?? false
        let modeIsAPIKey = (obj["auth_mode"] as? String) == "api_key"
        if keyPresent && modeIsAPIKey {
            return .apiKey
        }
        return .unauthed
    }
}

/// Sets / unsets a launchd user environment variable. Codex (and other GUI
/// apps) resolve `env_key` from the launchd env, not from the app's process
/// env or from auth.json. Injected so tests can verify the apply path calls
/// us without actually shelling out to `launchctl`.
public protocol LaunchdEnvironment: Sendable {
    func setenv(_ name: String, _ value: String)
    func unsetenv(_ name: String)
}

public struct SystemLaunchdEnvironment: LaunchdEnvironment {
    public init() {}
    public func setenv(_ name: String, _ value: String) {
        run(args: ["setenv", name, value])
    }
    public func unsetenv(_ name: String) {
        run(args: ["unsetenv", name])
    }
    private func run(args: [String]) {
        let proc = Process()
        proc.launchPath = "/bin/launchctl"
        proc.arguments = args
        try? proc.run()
        proc.waitUntilExit()
    }
}

/// Codex CLI + Codex.app target. Edits two files:
///   - `~/.codex/config.toml`        — managed TOML block at top
///   - `~/.codex/auth.json`          — OPENAI_API_KEY + auth_mode swap
/// And sets `OPENAI_API_KEY` in the user's launchd environment so GUI apps
/// inherit it on next launch.
public final class CodexTarget: Target, @unchecked Sendable {
    public let id: TargetID = .codex
    public let displayName: String = "Codex"

    public static let blockStartMarker = "# === LLM Flex managed block START — do not edit by hand ==="
    public static let blockEndMarker   = "# === LLM Flex managed block END ==="
    public static let providerKey = "llmflex"
    public static let envKey = "OPENAI_API_KEY"
    public static let snapshotTag = "codex"

    public static var defaultConfigURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex/config.toml")
    }
    public static var defaultAuthURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex/auth.json")
    }

    public let configURL: URL
    public let authURL: URL
    public let snapshots: SnapshotStore
    public let detector: CodexAuthStateDetector
    public let appController: CodexAppController
    public let launchdEnv: LaunchdEnvironment
    private let editor: TOMLBlockEditor

    public init(
        configURL: URL = CodexTarget.defaultConfigURL,
        authURL: URL = CodexTarget.defaultAuthURL,
        snapshots: SnapshotStore = SnapshotStore(root: SnapshotStore.defaultRoot),
        detector: CodexAuthStateDetector? = nil,
        appController: CodexAppController = CodexAppController(),
        launchdEnv: LaunchdEnvironment = SystemLaunchdEnvironment()
    ) {
        self.configURL = configURL
        self.authURL = authURL
        self.snapshots = snapshots
        self.detector = detector ?? CodexAuthStateDetector(authURL: authURL)
        self.appController = appController
        self.launchdEnv = launchdEnv
        self.editor = TOMLBlockEditor(
            startMarker: Self.blockStartMarker,
            endMarker: Self.blockEndMarker
        )
    }

    // MARK: - Inspect

    public func inspect() throws -> TargetStatus {
        let content = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
        let parsed = parseManagedBlock(in: content)
        return TargetStatus(
            target: .codex,
            activeProviderKey: parsed.providerKey,
            activeProviderLabel: parsed.providerLabel,
            activeModel: parsed.model,
            activeBaseURL: parsed.baseURL,
            authMode: detector.detect(),
            applicationRunning: appController.isRunning()
        )
    }

    // MARK: - Policy

    public func policy() throws -> ApplyPolicy {
        switch detector.detect() {
        case .chatgptLogin:
            return .blocked(.chatgptLoginActive)
        case .apiKey, .unauthed, .unknown:
            return .allowed
        }
    }

    // MARK: - Apply

    public func apply(profile: Profile, apiKey: String) throws {
        if case .blocked(let reason) = try policy() {
            throw TargetError.blocked(reason)
        }
        if profile.provider.requiresAPIKey && apiKey.isEmpty {
            throw TargetError.noAPIKey
        }

        // Snapshot originals BEFORE first touch (idempotent).
        try snapshots.captureIfAbsent(file: configURL, tag: Self.snapshotTag)
        try snapshots.captureIfAbsent(file: authURL, tag: Self.snapshotTag)

        let effectiveKey = apiKey.isEmpty ? "ollama-local" : apiKey
        try writeConfig(for: profile)
        try writeAuth(apiKey: effectiveKey)
        // Codex resolves `env_key` from the LAUNCHD environment, not auth.json.
        // Without this, the desktop app errors with "Missing environment variable".
        launchdEnv.setenv(Self.envKey, effectiveKey)
    }

    private func writeConfig(for profile: Profile) throws {
        let dir = configURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let existing = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
        let block = renderBlock(for: profile)
        let updated = editor.apply(
            source: existing,
            block: block,
            stripTopLevelKeys: ["model", "model_provider"]
        )
        do {
            try updated.write(to: configURL, atomically: true, encoding: .utf8)
        } catch {
            throw TargetError.ioFailure("Writing \(configURL.lastPathComponent)", underlying: error)
        }
    }

    private func writeAuth(apiKey: String) throws {
        let dir = authURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        var dict: [String: Any] = [:]
        if let data = try? Data(contentsOf: authURL),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict = parsed
        }
        dict["OPENAI_API_KEY"] = apiKey
        dict["auth_mode"] = "api_key"
        dict.removeValue(forKey: "tokens")
        dict.removeValue(forKey: "last_refresh")

        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: authURL, options: .atomic)
        } catch {
            throw TargetError.ioFailure("Writing \(authURL.lastPathComponent)", underlying: error)
        }
    }

    // MARK: - Restore

    @discardableResult
    public func restore() throws -> Bool {
        let configRestored = try snapshots.restore(file: configURL, tag: Self.snapshotTag)
        let authRestored = try snapshots.restore(file: authURL, tag: Self.snapshotTag)
        launchdEnv.unsetenv(Self.envKey)

        // If we never snapshotted (target untouched), at least scrub our block
        // from config.toml as a best-effort cleanup.
        if !configRestored, FileManager.default.fileExists(atPath: configURL.path) {
            let existing = try String(contentsOf: configURL, encoding: .utf8)
            try editor.strip(source: existing).write(to: configURL, atomically: true, encoding: .utf8)
        }
        return configRestored || authRestored
    }

    // MARK: - Block rendering / parsing

    private func renderBlock(for profile: Profile) -> String {
        var lines = [
            Self.blockStartMarker,
            "model_provider = \"\(Self.providerKey)\"",
        ]
        if !profile.modelName.isEmpty {
            lines.append("model = \"\(escape(profile.modelName))\"")
        }
        lines.append("")
        lines.append("[model_providers.\(Self.providerKey)]")
        lines.append("name = \"LLM Flex (\(escape(profile.name)))\"")
        lines.append("base_url = \"\(escape(profile.baseURL))\"")
        lines.append("env_key = \"\(Self.envKey)\"")
        lines.append("wire_api = \"\(profile.provider.wireAPI)\"")
        lines.append(Self.blockEndMarker)
        return lines.joined(separator: "\n")
    }

    struct ParsedBlock {
        var providerKey: String?
        var providerLabel: String?
        var model: String?
        var baseURL: String?
    }

    private func parseManagedBlock(in content: String) -> ParsedBlock {
        var inside = false
        var inProviderSection = false
        var parsed = ParsedBlock()
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == Self.blockStartMarker { inside = true; continue }
            if trimmed == Self.blockEndMarker { break }
            guard inside else { continue }
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                inProviderSection = trimmed == "[model_providers.\(Self.providerKey)]"
                continue
            }
            if let value = stringValue(in: trimmed, key: "model_provider") {
                parsed.providerKey = value
            } else if let value = stringValue(in: trimmed, key: "model") {
                parsed.model = value
            } else if inProviderSection,
                      let value = stringValue(in: trimmed, key: "base_url") {
                parsed.baseURL = value
                parsed.providerLabel = deriveProviderLabel(from: value)
            } else if inProviderSection,
                      let value = stringValue(in: trimmed, key: "name") {
                if parsed.providerLabel == nil { parsed.providerLabel = value }
            }
        }
        return parsed
    }

    private func stringValue(in line: String, key: String) -> String? {
        guard line.hasPrefix(key) else { return nil }
        let after = line.dropFirst(key.count)
        guard let eq = after.firstIndex(of: "=") else { return nil }
        let rhs = after[after.index(after: eq)...].trimmingCharacters(in: .whitespaces)
        guard rhs.hasPrefix("\""), rhs.hasSuffix("\""), rhs.count >= 2 else { return nil }
        return String(rhs.dropFirst().dropLast())
    }

    private func deriveProviderLabel(from baseURL: String) -> String? {
        if baseURL.contains("openrouter.ai") { return "OpenRouter" }
        if baseURL.contains("localhost") || baseURL.contains("127.0.0.1") { return "Ollama" }
        return nil
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
