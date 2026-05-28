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
            // Active dot — purple to match the status panel's "live" treatment.
            Circle()
                .fill(isApplied ? Theme.activeAccent : Color.secondary.opacity(0.35))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.callout)
                        .fontWeight(.medium)
                    if isApplied {
                        Text("active")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.activeAccent.opacity(0.18))
                            .foregroundStyle(Theme.activeAccent)
                            .clipShape(Capsule())
                    }
                    if profile.provider.codexCompatibility == .incompatible {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .help("Codex won't talk to this directly — needs a proxy or non-Codex target.")
                    }
                }
                Text(metaLine)
                    .font(Theme.Fonts.mono(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !targetLabels.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        Text(targetLabels.joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

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
                    .imageScale(.medium)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 22)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard canApply else { return }
            onApply()
        }
        .padding(.vertical, 4)
        .alert("Delete \(profile.name)?",
               isPresented: $confirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This removes the profile and its stored API key.")
        }
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
