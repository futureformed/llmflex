import SwiftUI

struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No profiles yet")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("Add one for OpenRouter, Ollama, or your own endpoint.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                onAdd()
            } label: {
                Label("Add profile", systemImage: "plus")
                    .font(.callout)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .llmAccentTint()
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }
}
