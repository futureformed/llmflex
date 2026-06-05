import SwiftUI

struct BlockedBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Sign out of ChatGPT in Codex first")
                    .font(Theme.Fonts.body)
                    .fontWeight(.semibold)
                Text("Codex.app refreshes its ChatGPT tokens on every launch and will overwrite the API key you set here. Sign out in Codex → Settings → Account, then come back.")
                    .font(Theme.Fonts.meta)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(.orange.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.orange.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct LegacyCleanupBanner: View {
    let onCleanup: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "broom")
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Legacy SwitchCode entries found")
                    .font(Theme.Fonts.body)
                    .fontWeight(.semibold)
                Text("Earlier broken builds left junk in config.toml. Clean it up so future switches stay tidy.")
                    .font(Theme.Fonts.meta)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Clean up now", action: onCleanup)
                    .buttonStyle(.borderless)
                    .font(Theme.Fonts.body)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct UpdateAvailableBanner: View {
    let version: String
    let url: URL

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(Theme.accent)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Version \(version) is available")
                    .font(Theme.Fonts.body)
                    .fontWeight(.semibold)
                Text("Download the latest build from GitHub and drag it into Applications to update.")
                    .font(Theme.Fonts.meta)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Link(destination: url) {
                    Label("Download update", systemImage: "arrow.up.forward.square")
                        .font(Theme.Fonts.body)
                }
                .llmAccentTint()
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Theme.accent.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.accent.opacity(0.30), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
