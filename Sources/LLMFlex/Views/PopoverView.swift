import SwiftUI
import LLMFlexCore

struct PopoverView: View {
    @Bindable var model: AppModel
    @State private var statusTimerActive = false

    var body: some View {
        Group {
            if model.isShowingEditor {
                ProfileEditor(model: model, profile: model.editingProfile)
            } else {
                mainContent
            }
        }
        .frame(width: Theme.Metric.popoverWidth)
        .background(.regularMaterial)
        .onAppear { model.reload() }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            VStack(alignment: .leading, spacing: Theme.Metric.sectionGap) {
                VStack(spacing: 6) {
                    StatusSection(
                        status: model.codexStatus,
                        title: "Codex",
                        iconSystemName: "terminal"
                    )
                    StatusSection(
                        status: model.claudeCodeStatus,
                        title: "Claude Code",
                        iconSystemName: "sparkles"
                    )
                }
                if model.isBlockedByChatGPT {
                    BlockedBanner()
                }
                if model.legacyCleanupAvailable {
                    LegacyCleanupBanner {
                        model.cleanupLegacy()
                    }
                }
                Divider()
                profilesSection
            }
            .padding(.horizontal, Theme.Metric.outerPadding)
            .padding(.vertical, Theme.Metric.sectionGap)
            Divider()
            footer
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .foregroundStyle(Theme.accent)
                .font(.title3)
            Text("LLM Flex")
                .font(.headline)
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit LLM Flex")
        }
        .padding(.horizontal, Theme.Metric.outerPadding)
        .padding(.vertical, 10)
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.rowGap) {
            HStack {
                Text("PROFILES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .kerning(0.6)
                Spacer()
                Button {
                    model.startAdding()
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .llmAccentTint()
            }
            if model.profiles.isEmpty {
                EmptyStateView { model.startAdding() }
                    .padding(.vertical, 16)
            } else {
                ForEach(model.profiles) { profile in
                    ProfileRow(
                        profile: profile,
                        isApplied: model.isApplied(profile),
                        canApply: !model.isBlockedByChatGPT,
                        onApply: { model.apply(profile) },
                        onEdit: { model.startEditing(profile) },
                        onDelete: { model.deleteProfile(profile) }
                    )
                }
            }
            if let message = model.lastApplyMessage {
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 4)
            }
            if let error = model.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                model.restoreDefaults()
            } label: {
                Label("Restore defaults", systemImage: "arrow.uturn.backward")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Restore Codex and Claude Code to the state they were in before LLM Flex first touched them.")

            Spacer()

            if model.codexStatus.applicationRunning {
                Button {
                    model.relaunchCodex()
                } label: {
                    Label("Relaunch Codex", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .llmAccentTint()
            }
        }
        .padding(.horizontal, Theme.Metric.outerPadding)
        .padding(.vertical, 10)
    }
}
