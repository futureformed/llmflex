import SwiftUI
import LLMFlexCore

struct StatusSection: View {
    let status: TargetStatus
    let title: String
    let iconSystemName: String

    private var isActive: Bool { status.activeProviderKey != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: iconSystemName)
                    .foregroundStyle(isActive ? Theme.activeAccent : .secondary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                authBadge
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(isActive ? Theme.activeAccent : .secondary)
                    .frame(width: 6, height: 6)
                Text(activeLine)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if let m = status.activeModel {
                Text(m)
                    .font(Theme.Fonts.mono(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.leading, 10)
        .padding(.vertical, 8)
        .padding(.trailing, 6)
        .overlay(alignment: .leading) {
            if isActive {
                Rectangle()
                    .fill(Theme.activeAccent)
                    .frame(width: 3)
            }
        }
        .background(isActive ? Theme.activeAccent.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
            .font(.caption2)
            .foregroundStyle(color)
    }
}
