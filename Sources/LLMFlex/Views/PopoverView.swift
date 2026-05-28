import SwiftUI
import LLMFlexCore

struct PopoverView: View {
    @Bindable var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        mainContent
            .frame(width: Theme.Metric.popoverWidth)
            .background(.thickMaterial)
            .onAppear { model.reload() }
            .onChange(of: model.editorOpenToken) { _, _ in
                // AppModel bumps this token when the user clicks Add/Edit.
                // Open the standalone editor Window and bring the app forward.
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: AppModel.editorWindowID)
            }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            VStack(alignment: .leading, spacing: Theme.Metric.sectionGap) {
                VStack(spacing: 8) {
                    StatusSection(
                        status: model.codexStatus,
                        title: "Codex",
                        iconSystemName: "terminal",
                        activeProvider: model.activeProfile(for: .codex)?.provider
                    )
                    StatusSection(
                        status: model.claudeCodeStatus,
                        title: "Claude Code",
                        iconSystemName: "sparkles",
                        activeProvider: model.activeProfile(for: .claudeCode)?.provider
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
        HStack(spacing: 10) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .foregroundStyle(Theme.accent)
                .font(.title2)
            Text("LLM Flex")
                .font(Theme.Fonts.title)
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .help("Quit LLM Flex")
        }
        .padding(.horizontal, Theme.Metric.outerPadding)
        .padding(.vertical, 12)
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Metric.rowGap) {
            HStack {
                Text("PROFILES")
                    .font(Theme.Fonts.label)
                    .foregroundStyle(.secondary)
                    .kerning(0.8)
                Spacer()
                Button {
                    model.startAdding()
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                        .font(Theme.Fonts.body)
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
                    .font(Theme.Fonts.meta)
                    .foregroundStyle(Theme.activeAccent)
                    .padding(.top, 4)
            }
            if let error = model.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.Fonts.meta)
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
                    .font(Theme.Fonts.body)
            }
            .buttonStyle(.borderless)
            .help("Restore Codex and Claude Code to the state they were in before LLM Flex first touched them.")

            Spacer()

            if model.codexStatus.applicationRunning {
                Button {
                    model.relaunchCodex()
                } label: {
                    Label("Relaunch Codex", systemImage: "arrow.clockwise")
                        .font(Theme.Fonts.body)
                }
                .buttonStyle(.borderless)
                .llmAccentTint()
            }
        }
        .padding(.horizontal, Theme.Metric.outerPadding)
        .padding(.vertical, 12)
    }
}
