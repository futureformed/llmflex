import Foundation

public enum TargetID: String, Codable, CaseIterable, Sendable {
    case codex
    // case claudeCode — future
}

/// Ground-truth view of what a target currently has configured. Built by
/// reading the real config files on disk, not the app's own state.
public struct TargetStatus: Equatable, Sendable {
    public let target: TargetID
    public let activeProviderKey: String?   // e.g. "llmflex" if managed; nil if no provider override
    public let activeProviderLabel: String? // e.g. "OpenRouter" (best-effort, derived from base_url)
    public let activeModel: String?
    public let activeBaseURL: String?
    public let authMode: CodexAuthState
    public let applicationRunning: Bool

    public init(
        target: TargetID,
        activeProviderKey: String?,
        activeProviderLabel: String?,
        activeModel: String?,
        activeBaseURL: String?,
        authMode: CodexAuthState,
        applicationRunning: Bool
    ) {
        self.target = target
        self.activeProviderKey = activeProviderKey
        self.activeProviderLabel = activeProviderLabel
        self.activeModel = activeModel
        self.activeBaseURL = activeBaseURL
        self.authMode = authMode
        self.applicationRunning = applicationRunning
    }
}

public enum CodexAuthState: String, Equatable, Sendable {
    case chatgptLogin   // tokens + last_refresh present → auth.json will be wiped on Codex.app launch
    case apiKey         // auth_mode == "api_key" and OPENAI_API_KEY non-null
    case unauthed       // file missing, or all relevant fields null/empty
    case unknown        // file present but couldn't be parsed
}

public enum ApplyPolicy: Equatable, Sendable {
    case allowed
    case blocked(BlockReason)
}

public enum BlockReason: String, Equatable, Sendable {
    /// Codex.app is signed in via ChatGPT. Launching the app will rewrite
    /// auth.json and clobber any API key we set. User must sign out of
    /// ChatGPT inside Codex Settings first.
    case chatgptLoginActive
}
