import SwiftUI
import LLMFlexCore

/// Shows where a chosen provider can actually be applied. Lists each target
/// (Codex, Claude Code) with a tick or warning + reason. Replaces the old
/// single-target chip.
struct TargetCompatibilityChip: View {
    let provider: Provider

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(TargetID.allCases, id: \.self) { target in
                row(for: target)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private func row(for target: TargetID) -> some View {
        let native = provider.compatibility(for: target) == .native
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: native ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(native ? Theme.accent : .orange)
                .font(.caption2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label(target) + (native ? " — works directly" : " — needs proxy"))
                    .font(.caption2)
                    .fontWeight(.semibold)
                if !native, let reason = provider.incompatibilityReason(for: target) {
                    Text(reason)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func label(_ target: TargetID) -> String {
        switch target {
        case .codex: return "Codex"
        case .claudeCode: return "Claude Code"
        }
    }
}
