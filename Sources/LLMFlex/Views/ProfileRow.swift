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
            // Active dot
            Circle()
                .fill(isApplied ? Theme.accent : Color.secondary.opacity(0.35))
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
                            .background(Theme.accent.opacity(0.18))
                            .foregroundStyle(Theme.accent)
                            .clipShape(Capsule())
                    }
                }
                Text(metaLine)
                    .font(Theme.Fonts.mono(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
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

    private func displayHost(_ url: String) -> String {
        guard let parsed = URL(string: url), let host = parsed.host else { return url }
        return host + parsed.path
    }
}
