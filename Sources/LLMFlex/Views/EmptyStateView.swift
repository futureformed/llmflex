import SwiftUI

struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No profiles yet")
                .font(Theme.Fonts.title)
            Text("Add one for OpenRouter, Anthropic, OpenAI, or any other supported provider.")
                .font(Theme.Fonts.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                onAdd()
            } label: {
                Label("Add profile", systemImage: "plus")
                    .font(Theme.Fonts.body)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .llmAccentTint()
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }
}
