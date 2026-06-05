import SwiftUI
import LLMFlexCore

struct StatusSection: View {
    let status: TargetStatus
    let title: String
    /// Brand-icon key — looks for `Resources/TargetIcons/<iconKey>.png`.
    let iconKey: String
    /// SF Symbol shown if the brand PNG isn't bundled yet.
    let iconSystemName: String
    let activeProvider: Provider?

    private var isActive: Bool { status.activeProviderKey != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TargetBadge(iconKey: iconKey,
                            fallbackSystemName: iconSystemName,
                            size: 18,
                            active: isActive)
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
                    Spacer(minLength: 8)
                    stateTag("Flexed", color: Theme.activeAccent)
                }
                // The model is what the user wants at a glance here; the full
                // endpoint URL belongs in the profile editor, not this summary.
                detailRow("Model", value: status.activeModel ?? "default", emphasized: status.activeModel != nil)
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
                    Spacer(minLength: 8)
                    stateTag("Default", color: .secondary)
                }
            }
        }
        .padding(.leading, 12)
        .padding(.vertical, 10)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Both targets read as peer cards: flexed = green, on-defaults =
        // neutral. The left bar + fill give the inactive one a container too,
        // so it no longer floats next to the active card.
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isActive ? Theme.activeAccent : Color.secondary.opacity(0.35))
                .frame(width: 3)
        }
        .background(isActive ? Theme.activeBackground.opacity(0.45)
                             : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
    }

    /// Small uppercase pill naming the target's state ("Flexed" / "Default")
    /// so the meaning is carried by words, not colour alone.
    private func stateTag(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(Theme.Fonts.label)
            .kerning(0.6)
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
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
