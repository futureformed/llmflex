import SwiftUI
import LLMFlexCore

struct StatusSection: View {
    @Bindable var model: AppModel

    private var isActive: Bool { model.codexStatus.activeProviderKey != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .foregroundStyle(isActive ? Theme.activeAccent : .secondary)
                Text("Codex")
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
            if let m = model.codexStatus.activeModel {
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
        // Use overlay (not HStack) so the accent bar never asks for its
        // own height — the panel sizes purely from its text content. This
        // is what was causing the panel to balloon vertically.
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
