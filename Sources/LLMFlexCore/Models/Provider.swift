import Foundation

/// Binary "does this provider talk to this target's native API?" status.
/// Same enum is reused for every target (Codex, Claude Code, future targets).
public enum TargetCompatibility: String, Codable, Sendable {
    case native       // Speaks the target's wire format directly
    case incompatible // Won't work without a translating proxy
}

/// Back-compat alias — UI code still references `CodexCompatibility`.
public typealias CodexCompatibility = TargetCompatibility

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

    /// Compatibility for a given target. Codex requires `wire_api = "responses"`
    /// (OpenAI Responses API). Claude Code requires Anthropic Messages format.
    public func compatibility(for target: TargetID) -> TargetCompatibility {
        switch target {
        case .codex:
            switch self {
            case .openai, .openrouter, .lmStudio, .openaiCompatible, .custom: return .native
            case .ollama, .anthropic, .gemini, .opencodeGo: return .incompatible
            }
        case .claudeCode:
            switch self {
            case .anthropic, .opencodeGo, .custom: return .native
            case .openai, .openrouter, .lmStudio, .openaiCompatible, .ollama, .gemini: return .incompatible
            }
        }
    }

    /// Human-readable reason this provider can't reach the given target
    /// directly. `nil` when native.
    public func incompatibilityReason(for target: TargetID) -> String? {
        guard compatibility(for: target) == .incompatible else { return nil }
        switch target {
        case .codex:
            switch self {
            case .ollama:     return "Ollama only speaks chat-completions. Codex now requires the Responses API."
            case .anthropic:  return "Anthropic uses its own Messages API. Codex needs OpenAI Responses."
            case .gemini:     return "Gemini uses Google's own format. Codex needs OpenAI Responses."
            case .opencodeGo: return "Opencode Go uses chat-completions or Anthropic-messages — not the Responses API."
            default: return nil
            }
        case .claudeCode:
            switch self {
            case .openai:           return "OpenAI uses its Responses API, not Anthropic Messages."
            case .openrouter:       return "OpenRouter is OpenAI-compatible by default — not Anthropic Messages."
            case .lmStudio:         return "LM Studio is OpenAI-compatible — not Anthropic Messages."
            case .openaiCompatible: return "OpenAI-compatible providers don't speak the Anthropic Messages API."
            case .ollama:           return "Ollama is OpenAI-compatible — not Anthropic Messages."
            case .gemini:           return "Gemini uses Google's format — not Anthropic Messages."
            default: return nil
            }
        }
    }

    // MARK: - Back-compat shims (still used by older call sites)
    public var codexCompatibility: TargetCompatibility { compatibility(for: .codex) }
    public var codexIncompatibilityReason: String? { incompatibilityReason(for: .codex) }

    /// Codex (as of mid-2026) requires `wire_api = "responses"` — chat
    /// completions are no longer accepted. OpenRouter has a Responses-API-
    /// compatible endpoint at the same base URL. For Ollama / pure
    /// OpenAI-chat providers this may not work end-to-end — that's a
    /// provider-coverage limitation, not an LLM Flex bug.
    /// See: https://github.com/openai/codex/discussions/7782
    public var wireAPI: String { "responses" }

    /// How this provider expects API-key auth in HTTP requests. Used by
    /// ConnectivityTester so Test Connection picks the right header per
    /// provider.
    public var authScheme: AuthScheme {
        switch self {
        case .anthropic:        return .anthropicHeaders
        case .gemini:           return .googleQueryParam
        case .openai, .openrouter, .lmStudio, .openaiCompatible,
             .custom, .ollama, .opencodeGo:
            return .bearer
        }
    }
}
