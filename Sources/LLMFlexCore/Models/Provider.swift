import Foundation

public enum CodexCompatibility: String, Codable, Sendable {
    case native       // Speaks OpenAI Responses API
    case incompatible // Won't work with Codex directly — needs a proxy
}

public enum Provider: String, Codable, CaseIterable, Identifiable, Sendable {
    // Codex-native (speak the OpenAI Responses API)
    case openai
    case openrouter
    case lmStudio = "lm_studio"
    case openaiCompatible = "openai_compatible"
    case custom

    // Codex-incompatible (chat-completions, Anthropic messages, or other format).
    // Profiles for these still save and will be useful for Claude Code or
    // proxy-routed setups; Codex.app will error on direct use.
    case ollama
    case anthropic
    case gemini
    case opencodeGo = "opencode_go"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .openai: "OpenAI"
        case .openrouter: "OpenRouter"
        case .lmStudio: "LM Studio"
        case .openaiCompatible: "OpenAI-compatible"
        case .custom: "Custom"
        case .ollama: "Ollama"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        case .opencodeGo: "Opencode Go"
        }
    }

    public var defaultBaseURL: String {
        switch self {
        case .openai: "https://api.openai.com/v1"
        case .openrouter: "https://openrouter.ai/api/v1"
        case .lmStudio: "http://localhost:1234/v1"
        case .openaiCompatible: ""
        case .custom: ""
        case .ollama: "http://localhost:11434/v1"
        case .anthropic: "https://api.anthropic.com/v1"
        case .gemini: "https://generativelanguage.googleapis.com/v1beta"
        case .opencodeGo: "https://opencode.ai/zen/go/v1"
        }
    }

    public var requiresAPIKey: Bool {
        switch self {
        case .ollama, .lmStudio: false
        default: true
        }
    }

    /// Whether Codex (which now requires `wire_api = "responses"`) can talk
    /// to this provider directly.
    public var codexCompatibility: CodexCompatibility {
        switch self {
        case .openai, .openrouter, .lmStudio, .openaiCompatible, .custom:
            return .native
        case .ollama, .anthropic, .gemini, .opencodeGo:
            return .incompatible
        }
    }

    /// One-line explanation when Codex can't reach this provider directly.
    /// `nil` when the provider is Codex-native.
    public var codexIncompatibilityReason: String? {
        switch self {
        case .openai, .openrouter, .lmStudio, .openaiCompatible, .custom:
            return nil
        case .ollama:
            return "Ollama only speaks chat-completions. Codex now requires the Responses API."
        case .anthropic:
            return "Anthropic uses its own Messages API. Not compatible with Codex's Responses requirement."
        case .gemini:
            return "Gemini uses Google's own format. Not compatible with Codex's Responses requirement."
        case .opencodeGo:
            return "Opencode Go uses chat-completions or Anthropic-messages endpoints, neither of which is the Responses API."
        }
    }

    /// Codex (as of mid-2026) requires `wire_api = "responses"` — chat
    /// completions are no longer accepted. OpenRouter has a Responses-API-
    /// compatible endpoint at the same base URL. For Ollama / pure
    /// OpenAI-chat providers this may not work end-to-end — that's a
    /// provider-coverage limitation, not an LLM Flex bug.
    /// See: https://github.com/openai/codex/discussions/7782
    public var wireAPI: String { "responses" }
}
