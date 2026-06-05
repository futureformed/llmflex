import SwiftUI
import LLMFlexCore

struct StatusSection: View {
    let status: TargetStatus
    let title: String
    let iconSystemName: String
    let activeProvider: Provider?

    private var isActive: Bool { status.activeProviderKey != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: iconSystemName)
                    .foregroundStyle(isActive ? Theme.activeAccent : .secondary)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(Theme.Fonts.bodyBold)
                Spacer()
                authBadge
            }

            if isActive {
                // Provider line — the badge + human name of what's live.
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.activeAccent)
                        .frame(width: 7, height: 7)
                    if let provider = activeProvider {
                        ProviderBadge(provider: provider, size: 16)
                    }
                    Text(providerName)
                        .font(Theme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                // The two things the user actually wants to see at a glance.
                detailRow("Model", value: status.activeModel ?? "default", emphasized: status.activeModel != nil)
                detailRow("Endpoint", value: endpointValue, emphasized: false)
            } else {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                    Text(inactiveLine)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .padding(.leading, 12)
        .padding(.vertical, 10)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            if isActive {
                Rectangle()
                    .fill(Theme.activeAccent)
                    .frame(width: 3)
            }
        }
        .background(isActive ? Theme.activeBackground.opacity(0.45) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// A labelled key/value line: "MODEL  gpt-4o" / "ENDPOINT  https://…".
    /// The label column is fixed-width so Model and Endpoint values align.
    private func detailRow(_ label: String, value: String, emphasized: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(Theme.Fonts.label)
                .foregroundStyle(.secondary)
                .kerning(0.6)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .font(Theme.Fonts.mono(12))
                .fontWeight(emphasized ? .semibold : .regular)
                .foregroundStyle(emphasized ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .padding(.leading, 15) // align under the provider name (dot + spacing)
    }

    /// What to show on the Endpoint row. Prefer the real base URL; fall back to
    /// the derived label, then a sensible default per target.
    private var endpointValue: String {
        if let url = status.activeBaseURL { return url }
        if let label = status.activeProviderLabel { return label }
        switch status.target {
        case .codex:      return "Codex default"
        case .claudeCode: return "api.anthropic.com"
        }
    }

    /// The provider's display name for the provider line.
    private var providerName: String {
        if let provider = activeProvider { return provider.displayName }
        if let label = status.activeProviderLabel { return label }
        return "Custom endpoint"
    }

    private var inactiveLine: String {
        switch status.target {
        case .codex:       return "Codex defaults (no override)"
        case .claudeCode:  return "Claude Code defaults"
        }
    }

    @ViewBuilder private var authBadge: some View {
        switch status.authMode {
        case .apiKey:
            badge("API key", systemImage: "key.fill", color: Theme.activeAccent)
        case .chatgptLogin:
            badge("ChatGPT login", systemImage: "person.crop.circle.fill", color: .orange)
        case .unauthed:
            badge("Not signed in", systemImage: "person.crop.circle.badge.xmark", color: .secondary)
        case .unknown:
            badge("Auth: unknown", systemImage: "questionmark.circle", color: .secondary)
        }
    }

    private func badge(_ text: String, systemImage: String, color: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(Theme.Fonts.meta)
            .foregroundStyle(color)
    }
}
