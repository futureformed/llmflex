import Foundation

public enum Provider: String, Codable, CaseIterable, Identifiable, Sendable {
    case openrouter
    case openaiCompatible = "openai_compatible"
    case ollama
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .openrouter: "OpenRouter"
        case .openaiCompatible: "OpenAI-compatible"
        case .ollama: "Ollama"
        case .custom: "Custom"
        }
    }

    public var defaultBaseURL: String {
        switch self {
        case .openrouter: "https://openrouter.ai/api/v1"
        case .openaiCompatible: ""
        case .ollama: "http://localhost:11434/v1"
        case .custom: ""
        }
    }

    public var requiresAPIKey: Bool {
        switch self {
        case .ollama: false
        default: true
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
