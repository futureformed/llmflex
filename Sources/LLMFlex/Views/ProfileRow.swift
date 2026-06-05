import SwiftUI
import LLMFlexCore

struct ProfileRow: View {
    let profile: Profile
    let isApplied: Bool
    let canApply: Bool
    let onApply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var confirmDelete = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Active dot — green to match the status panel's "live" treatment.
            Circle()
                .fill(isApplied ? Theme.activeAccent : Color.secondary.opacity(0.35))
                .frame(width: 9, height: 9)
                .padding(.top, 7)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    ProviderBadge(provider: profile.provider, size: 16)
                    Text(profile.name)
                        .font(Theme.Fonts.body)
                        .fontWeight(.medium)
                    if isApplied {
                        Text("active")
                            .font(Theme.Fonts.label)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Theme.activeAccent.opacity(0.22))
                            .foregroundStyle(Theme.activeAccent)
                            .clipShape(Capsule())
                    }
                    if profile.provider.codexCompatibility == .incompatible {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                            .help("Codex won't talk to this directly — needs a proxy or non-Codex target.")
                    }
                }
                Text(metaLine)
                    .font(Theme.Fonts.mono(12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !targetLabels.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text(targetLabels.joined(separator: " · "))
                            .font(Theme.Fonts.meta)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Inline confirmation rather than a system .alert: an alert steals
            // key focus from the MenuBarExtra popover, which dismisses it and
            // drops the button action. Inline state stays inside the popover.
            if confirmDelete {
                HStack(spacing: 6) {
                    Button("Delete", role: .destructive, action: onDelete)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                    Button("Cancel") { confirmDelete = false }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .help("Deletes the profile and its stored API key")
            } else {
                Menu {
                    Button("Apply", systemImage: "play.fill", action: onApply)
                        .disabled(!canApply)
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        confirmDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Don't apply while a delete confirmation is showing on this row.
            guard canApply, !confirmDelete else { return }
            onApply()
        }
        .padding(.vertical, 4)
    }

    private var metaLine: String {
        let host = displayHost(profile.baseURL)
        if profile.modelName.isEmpty { return host }
        return "\(host) · \(profile.modelName)"
    }

    private var targetLabels: [String] {
        TargetID.allCases.compactMap { t in
            guard profile.provider.compatibility(for: t) == .native else { return nil }
            switch t {
            case .codex: return "Codex"
            case .claudeCode: return "Claude Code"
            }
        }
    }

    private func displayHost(_ url: String) -> String {
        guard let parsed = URL(string: url), let host = parsed.host else { return url }
        return host + parsed.path
    }
}
