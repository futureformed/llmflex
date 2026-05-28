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

    /// All providers we support speak OpenAI-compatible chat completions.
    /// The OpenAI Responses API (which Codex's `[plugins.*]` features rely on)
    /// is only available from OpenAI itself.
    public var wireAPI: String { "chat" }
}
