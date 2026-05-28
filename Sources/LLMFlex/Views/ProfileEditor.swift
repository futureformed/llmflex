import SwiftUI
import LLMFlexCore

struct ProfileEditor: View {
    @Bindable var model: AppModel
    let profile: Profile?

    @State private var name: String = ""
    @State private var provider: Provider = .openrouter
    @State private var baseURL: String = ""
    @State private var modelName: String = ""
    @State private var apiKey: String = ""
    @State private var testing: Bool = false
    @State private var testResult: ConnectivityResult?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            VStack(alignment: .leading, spacing: 14) {
                field("Name") {
                    TextField("OpenRouter — Sonnet 4", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                field("Provider") {
                    Picker("", selection: $provider) {
                        ForEach(Provider.allCases) { p in
                            HStack {
                                Text(p.displayName)
                                if p.codexCompatibility == .incompatible {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: provider) { old, new in
                        // Only auto-swap baseURL if the user hadn't customised
                        // it — i.e. it still matches the previous provider's
                        // default (or is empty for OpenAI-compatible / Custom).
                        if baseURL.isEmpty || baseURL == old.defaultBaseURL {
                            baseURL = new.defaultBaseURL
                        }
                    }
                    TargetCompatibilityChip(provider: provider)
                }
                field("Base URL") {
                    TextField("https://…", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                        .font(Theme.Fonts.mono(12))
                }
                if provider.requiresAPIKey {
                    field("API key") {
                        SecureField("sk-…", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                        Text("Stored in your macOS Keychain only.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                field("Model") {
                    HStack(spacing: 6) {
                        TextField("anthropic/claude-sonnet-4-…", text: $modelName)
                            .textFieldStyle(.roundedBorder)
                            .font(Theme.Fonts.mono(12))
                        let entries = ModelCatalog.entries(for: provider)
                        if !entries.isEmpty {
                            Menu {
                                ForEach(entries) { entry in
                                    Button {
                                        modelName = entry.id
                                    } label: {
                                        if let notes = entry.notes {
                                            Text("\(entry.label) — \(notes)")
                                        } else {
                                            Text(entry.label)
                                        }
                                    }
                                }
                            } label: {
                                Label("Quick pick", systemImage: "list.bullet.below.rectangle")
                                    .labelStyle(.iconOnly)
                                    .imageScale(.medium)
                            }
                            .menuStyle(.borderlessButton)
                            .menuIndicator(.hidden)
                            .frame(width: 28)
                            .help("Pick from \(entries.count) curated models")
                        }
                    }
                }
                testRow
            }
            .padding(Theme.Metric.outerPadding)
            Divider()
            footer
        }
        .onAppear(perform: loadFromProfile)
    }

    private var header: some View {
        HStack {
            Button {
                model.cancelEditing()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            Text(profile == nil ? "Add profile" : "Edit profile")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, Theme.Metric.outerPadding)
        .padding(.vertical, 10)
    }

    private var testRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    runTest()
                } label: {
                    if testing {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Test connection", systemImage: "wifi")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(testing || baseURL.isEmpty)

                if let r = testResult, r.ok {
                    Label(r.message, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
                Spacer()
            }
            // Errors go below the row so the full provider message can wrap
            // freely without fighting the Test button for horizontal space.
            if let r = testResult, !r.ok {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "xmark.octagon.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(r.message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            if profile != nil {
                Button(role: .destructive) {
                    if let p = profile {
                        model.deleteProfile(p)
                        model.cancelEditing()
                        dismiss()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            Spacer()
            Button("Cancel") {
                model.cancelEditing()
                dismiss()
            }
            .keyboardShortcut(.escape)
            Button(profile == nil ? "Save" : "Save changes") {
                save()
            }
            .buttonStyle(.borderedProminent)
            .llmAccentTint()
            .disabled(!canSave)
        }
        .padding(.horizontal, Theme.Metric.outerPadding)
        .padding(.vertical, 10)
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .kerning(0.5)
            content()
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !baseURL.trimmingCharacters(in: .whitespaces).isEmpty &&
        !modelName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadFromProfile() {
        if let p = profile {
            name = p.name
            provider = p.provider
            baseURL = p.baseURL
            modelName = p.modelName
            apiKey = model.loadKey(for: p)
        } else {
            provider = .openrouter
            baseURL = Provider.openrouter.defaultBaseURL
        }
    }

    private func save() {
        let cleanedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = Profile(
            id: profile?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            provider: provider,
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            modelName: modelName.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: profile?.createdAt ?? Date()
        )
        model.upsertProfile(updated, apiKey: cleanedKey.isEmpty ? nil : cleanedKey)
        model.cancelEditing()
        dismiss()
    }

    private func runTest() {
        testing = true
        testResult = nil
        let keySnapshot = apiKey
        let urlSnapshot = baseURL
        let schemeSnapshot = provider.authScheme
        Task {
            let result = await model.tester.test(
                baseURL: urlSnapshot,
                apiKey: keySnapshot.isEmpty ? nil : keySnapshot,
                scheme: schemeSnapshot
            )
            await MainActor.run {
                testResult = result
                testing = false
            }
        }
    }
}
