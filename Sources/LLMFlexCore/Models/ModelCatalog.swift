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
        // OpenAI
        .init(id: "openai/gpt-5.5",                  label: "GPT-5.5",                  notes: "OpenAI frontier — deep reasoning for complex pro work."),
        .init(id: "openai/gpt-5.5-pro",              label: "GPT-5.5 Pro",              notes: "Highest-accuracy GPT for high-stakes work."),
        .init(id: "openai/gpt-5.4",                  label: "GPT-5.4",                  notes: "Strong coding across 1M+ context."),
        .init(id: "openai/gpt-5.4-mini",             label: "GPT-5.4 Mini",             notes: "Faster, cheaper GPT-5.4 variant."),
        // Anthropic
        .init(id: "anthropic/claude-opus-4.8",       label: "Claude Opus 4.8",          notes: "Anthropic's top — reasoning + file inputs."),
        .init(id: "anthropic/claude-opus-4.8-fast",  label: "Claude Opus 4.8 Fast",     notes: "Opus 4.8 with higher output speed."),
        .init(id: "anthropic/claude-opus-4.7",       label: "Claude Opus 4.7",          notes: "Long-running agents, stronger coding."),
        // Google
        .init(id: "google/gemini-3.5-flash",         label: "Gemini 3.5 Flash",         notes: "Near-Pro coding at Flash speed and cost."),
        .init(id: "google/gemini-3.1-flash-lite",    label: "Gemini 3.1 Flash Lite",    notes: "GA low-latency model for high-volume work."),
        // DeepSeek
        .init(id: "deepseek/deepseek-v4-pro",        label: "DeepSeek V4 Pro",          notes: "1.6T MoE for advanced reasoning + coding."),
        .init(id: "deepseek/deepseek-v4-flash",      label: "DeepSeek V4 Flash",        notes: "284B MoE / 13B active — fast and efficient."),
        // Qwen
        .init(id: "qwen/qwen3.7-max",                label: "Qwen3.7 Max",              notes: "Flagship Qwen — agent-centric, coding-strong."),
        .init(id: "qwen/qwen3.6-max-preview",        label: "Qwen3.6 Max Preview",      notes: "~1T sparse MoE for agentic coding."),
        // Mistral
        .init(id: "mistralai/mistral-medium-3.5",    label: "Mistral Medium 3.5",       notes: "Dense 128B — agentic workflows."),
        .init(id: "mistralai/mistral-small-2603",    label: "Mistral Small (2603)",     notes: "Unified multimodal reasoning."),
        // xAI
        .init(id: "x-ai/grok-4.20",                  label: "Grok 4.20",                notes: "Industry-leading speed, low hallucination."),
        // Z-AI (GLM)
        .init(id: "z-ai/glm-5.1",                    label: "GLM-5.1",                  notes: "Long-horizon autonomous coding."),
        .init(id: "z-ai/glm-5-turbo",                label: "GLM-5 Turbo",              notes: "Fast inference, optimised for real-world agents."),
        // Xiaomi / ByteDance
        .init(id: "xiaomi/mimo-v2.5-pro",            label: "MiMo-V2.5 Pro",            notes: "1T params, optimised for agentic coding."),
        .init(id: "bytedance-seed/seed-2.0-lite",    label: "Seed-2.0 Lite",            notes: "Cost-efficient enterprise model, low latency."),
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
