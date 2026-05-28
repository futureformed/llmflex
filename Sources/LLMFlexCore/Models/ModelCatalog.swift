import Foundation

/// A curated model in the catalog.
public struct CatalogEntry: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String        // exact model ID used in API calls
    public let label: String     // short human-friendly name
    public let notes: String?    // optional one-line description

    public init(id: String, label: String, notes: String? = nil) {
        self.id = id
        self.label = label
        self.notes = notes
    }
}

/// Per-provider "quick pick" model lists shown in the editor. To refresh
/// when new models ship:
///
/// 1. Update the relevant array below.
/// 2. `swift test` and `./build.sh`.
/// 3. Commit.
///
/// Provider doc sources used for the current data (May 2026):
///   - Anthropic:   https://docs.anthropic.com/en/docs/about-claude/models/overview
///   - OpenAI:      https://platform.openai.com/docs/models
///   - OpenRouter:  https://openrouter.ai/models
///   - Opencode Go: https://opencode.ai/zen/go (user-supplied screenshot)
public enum ModelCatalog {

    public static func entries(for provider: Provider) -> [CatalogEntry] {
        switch provider {
        case .openai:      return openai
        case .anthropic:   return anthropic
        case .openrouter:  return openrouter
        case .opencodeGo:  return opencodeGo
        case .openaiCompatible, .custom, .lmStudio, .ollama, .gemini:
            return []
        }
    }

    // MARK: - OpenAI

    public static let openai: [CatalogEntry] = [
        .init(id: "gpt-5.5",         label: "GPT-5.5",         notes: "Frontier model — strongest reasoning and coding."),
        .init(id: "gpt-5.5-pro",     label: "GPT-5.5 Pro",     notes: "More compute for the hardest problems (Responses API only)."),
        .init(id: "gpt-5.4",         label: "GPT-5.4",         notes: "Solid general-purpose workhorse."),
        .init(id: "gpt-5.4-mini",    label: "GPT-5.4 mini",    notes: "Lower latency and cost."),
        .init(id: "gpt-5.4-nano",    label: "GPT-5.4 nano",    notes: "Cheapest tier — light tasks."),
        .init(id: "gpt-5.3",         label: "GPT-5.3",         notes: "Previous flagship."),
        .init(id: "gpt-5",           label: "GPT-5",           notes: "Original GPT-5 baseline."),
    ]

    // MARK: - Anthropic

    public static let anthropic: [CatalogEntry] = [
        .init(id: "claude-opus-4-8",            label: "Claude Opus 4.8",    notes: "Anthropic's most capable — complex reasoning, long-horizon agentic coding."),
        .init(id: "claude-sonnet-4-6",          label: "Claude Sonnet 4.6",  notes: "Best speed-intelligence balance. 1M context."),
        .init(id: "claude-haiku-4-5",           label: "Claude Haiku 4.5",   notes: "Fastest model with near-frontier intelligence."),
        .init(id: "claude-opus-4-7",            label: "Claude Opus 4.7",    notes: "Previous flagship — long-horizon agents."),
        .init(id: "claude-opus-4-6",            label: "Claude Opus 4.6",    notes: "Legacy. 1M context, extended thinking."),
        .init(id: "claude-sonnet-4-5",          label: "Claude Sonnet 4.5",  notes: "Legacy Sonnet generation."),
        .init(id: "claude-sonnet-4-20250514",   label: "Claude Sonnet 4",    notes: "Deprecated — retires 2026-06-15."),
    ]

    // MARK: - OpenRouter

    public static let openrouter: [CatalogEntry] = [
        .init(id: "openai/gpt-5.5",                 label: "GPT-5.5",                 notes: "OpenAI frontier via OpenRouter."),
        .init(id: "openai/gpt-5.4-pro",             label: "GPT-5.4 Pro",             notes: "Advanced reasoning, high-stakes coding."),
        .init(id: "openai/gpt-5.4",                 label: "GPT-5.4",                 notes: "1M+ context, strong coding."),
        .init(id: "anthropic/claude-opus-4.8",      label: "Claude Opus 4.8",         notes: "Anthropic's top, with reasoning + file inputs."),
        .init(id: "anthropic/claude-opus-4.8-fast", label: "Claude Opus 4.8 Fast",    notes: "Same as Opus 4.8 with higher output speed."),
        .init(id: "anthropic/claude-opus-4.7",      label: "Claude Opus 4.7",         notes: "Long-running agents, enhanced coding."),
        .init(id: "deepseek/deepseek-v4-pro",       label: "DeepSeek V4 Pro",         notes: "1.6T MoE for advanced reasoning + coding."),
        .init(id: "google/gemini-3.5-flash",        label: "Gemini 3.5 Flash",        notes: "Near-Pro coding at Flash speed and cost."),
        .init(id: "qwen/qwen3.7-max",               label: "Qwen3.7 Max",             notes: "Flagship Qwen — coding strengths."),
        .init(id: "qwen/qwen3.6-max-preview",      label: "Qwen3.6 Max Preview",     notes: "Sparse MoE optimized for agentic coding."),
        .init(id: "x-ai/grok-4.20",                 label: "Grok 4.20",               notes: "Industry-leading speed, low hallucination."),
        .init(id: "mistralai/mistral-medium-3.5",   label: "Mistral Medium 3.5",      notes: "Dense 128B — agentic workflows."),
        .init(id: "z-ai/glm-5.1",                   label: "GLM-5.1",                 notes: "Long-horizon autonomous coding."),
        .init(id: "xiaomi/mimo-v2.5-pro",            label: "MiMo-V2.5 Pro",           notes: "1T params, optimized for agentic coding."),
        .init(id: "tencent/hy3-preview",            label: "Hy3 Preview",             notes: "Efficient MoE with configurable reasoning."),
    ]

    // MARK: - Opencode Go

    public static let opencodeGo: [CatalogEntry] = [
        // /v1/chat/completions endpoint
        .init(id: "opencode-go/glm-5.1",             label: "GLM-5.1"),
        .init(id: "opencode-go/glm-5",               label: "GLM-5"),
        .init(id: "opencode-go/kimi-k2.6",           label: "Kimi K2.6"),
        .init(id: "opencode-go/kimi-k2.5",           label: "Kimi K2.5"),
        .init(id: "opencode-go/deepseek-v4-pro",     label: "DeepSeek V4 Pro"),
        .init(id: "opencode-go/deepseek-v4-flash",   label: "DeepSeek V4 Flash"),
        .init(id: "opencode-go/mimo-v2.5",           label: "MiMo-V2.5"),
        .init(id: "opencode-go/mimo-v2.5-pro",       label: "MiMo-V2.5 Pro"),
        // /v1/messages endpoint (Anthropic format)
        .init(id: "opencode-go/minimax-m2.7",        label: "MiniMax M2.7",   notes: "Anthropic-messages endpoint."),
        .init(id: "opencode-go/minimax-m2.5",        label: "MiniMax M2.5",   notes: "Anthropic-messages endpoint."),
        .init(id: "opencode-go/qwen3.7-max",         label: "Qwen3.7 Max",    notes: "Anthropic-messages endpoint."),
        .init(id: "opencode-go/qwen3.6-plus",        label: "Qwen3.6 Plus",   notes: "Anthropic-messages endpoint."),
        .init(id: "opencode-go/qwen3.5-plus",        label: "Qwen3.5 Plus",   notes: "Anthropic-messages endpoint."),
    ]
}
