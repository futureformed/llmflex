import SwiftUI
import LLMFlexCore

struct StatusSection: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .foregroundStyle(.secondary)
                Text("Codex")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                authBadge
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(model.codexStatus.activeProviderKey == nil ? .secondary : Theme.accent)
                    .frame(width: 6, height: 6)
                Text(activeLine)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if let model = model.codexStatus.activeModel {
                Text(model)
                    .font(Theme.Fonts.mono(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var activeLine: String {
        if let label = model.codexStatus.activeProviderLabel {
            return label
        }
        if let url = model.codexStatus.activeBaseURL {
            return url
        }
        return "Codex defaults (no override)"
    }

    @ViewBuilder private var authBadge: some View {
        switch model.codexStatus.authMode {
        case .apiKey:
            badge("API key", systemImage: "key.fill", color: Theme.accent)
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
