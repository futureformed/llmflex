import SwiftUI
import LLMFlexCore

struct StatusSection: View {
    let status: TargetStatus
    let title: String
    let iconSystemName: String
    let activeProvider: Provider?

    private var isActive: Bool { status.activeProviderKey != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: iconSystemName)
                    .foregroundStyle(isActive ? Theme.activeAccent : .secondary)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(Theme.Fonts.bodyBold)
                Spacer()
                authBadge
            }
            HStack(spacing: 8) {
                Circle()
                    .fill(isActive ? Theme.activeAccent : .secondary)
                    .frame(width: 7, height: 7)
                if let provider = activeProvider {
                    ProviderBadge(provider: provider, size: 16)
                }
                Text(activeLine)
                    .font(Theme.Fonts.body)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if let m = status.activeModel {
                Text(m)
                    .font(Theme.Fonts.mono(12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.leading, 12)
        .padding(.vertical, 10)
        .padding(.trailing, 10)
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

    private var activeLine: String {
        if let label = status.activeProviderLabel { return label }
        if let url = status.activeBaseURL { return url }
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
