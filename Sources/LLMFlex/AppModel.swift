import Foundation
import Observation
import LLMFlexCore

/// The view model. Owns the storage, target, and live status. Views observe
/// `profiles` and `codexStatus`; mutations route through methods here so
/// state stays consistent across re-renders.
@MainActor
@Observable
final class AppModel {
    // Storage / services
    let profileStore: ProfileStore
    let keychain: KeychainStore
    let codex: CodexTarget
    let tester: ConnectivityTester
    let migrator: SwitchCodeCleanup

    // Published state
    var profiles: [Profile] = []
    var codexStatus: TargetStatus
    var lastError: String?
    var lastApplyMessage: String?
    var legacyCleanupAvailable: Bool = false

    // Editor state
    var editingProfile: Profile?
    var isShowingEditor: Bool = false

    init(
        profileStore: ProfileStore = ProfileStore(),
        keychain: KeychainStore = KeychainStore(),
        codex: CodexTarget = CodexTarget(),
        tester: ConnectivityTester = ConnectivityTester(),
        migrator: SwitchCodeCleanup = SwitchCodeCleanup()
    ) {
        self.profileStore = profileStore
        self.keychain = keychain
        self.codex = codex
        self.tester = tester
        self.migrator = migrator
        // Synchronous best-effort initial inspect so the first render has data.
        self.codexStatus = (try? codex.inspect()) ?? TargetStatus(
            target: .codex,
            activeProviderKey: nil,
            activeProviderLabel: nil,
            activeModel: nil,
            activeBaseURL: nil,
            authMode: .unknown,
            applicationRunning: false
        )
        reload()
    }

    // MARK: - Lifecycle

    func reload() {
        profiles = profileStore.all()
        do {
            codexStatus = try codex.inspect()
        } catch {
            lastError = error.localizedDescription
        }
        let configContent = (try? String(contentsOf: codex.configURL, encoding: .utf8)) ?? ""
        legacyCleanupAvailable = migrator.needsCleanup(configContent)
    }

    // MARK: - Derived state

    /// True if the on-disk Codex config currently points at `profile`.
    func isApplied(_ profile: Profile) -> Bool {
        guard let baseURL = codexStatus.activeBaseURL else { return false }
        return baseURL == profile.baseURL
    }

    var isBlockedByChatGPT: Bool {
        codexStatus.authMode == .chatgptLogin
    }

    // MARK: - Profile CRUD

    func upsertProfile(_ profile: Profile, apiKey: String?) {
        profileStore.upsert(profile)
        if let key = apiKey, !key.isEmpty {
            try? keychain.set(key, for: profile.id)
        }
        reload()
    }

    func deleteProfile(_ profile: Profile) {
        profileStore.delete(id: profile.id)
        try? keychain.delete(profile.id)
        reload()
    }

    func loadKey(for profile: Profile) -> String {
        (try? keychain.key(for: profile.id)) ?? ""
    }

    // MARK: - Apply / restore

    func apply(_ profile: Profile) {
        do {
            let key = loadKey(for: profile)
            if profile.provider.requiresAPIKey, key.isEmpty {
                throw TargetError.noAPIKey
            }
            try codex.apply(profile: profile, apiKey: key)
            profileStore.activeID = profile.id
            lastApplyMessage = "Switched to \(profile.name)."
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            lastApplyMessage = nil
        }
        reload()
    }

    func restoreDefaults() {
        do {
            let restored = try codex.restore()
            profileStore.activeID = nil
            lastApplyMessage = restored
                ? "Restored Codex defaults."
                : "Cleared LLM Flex config (no snapshot to restore from)."
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            lastApplyMessage = nil
        }
        reload()
    }

    // MARK: - Codex.app control

    func relaunchCodex() {
        codex.appController.quit()
        // brief delay to let it terminate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [codex] in
            codex.appController.relaunch()
        }
    }

    // MARK: - Legacy cleanup

    func cleanupLegacy() {
        do {
            let url = codex.configURL
            let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let cleaned = migrator.clean(existing)
            try cleaned.write(to: url, atomically: true, encoding: .utf8)
            lastApplyMessage = "Cleaned up legacy SwitchCode entries."
        } catch {
            lastError = error.localizedDescription
        }
        reload()
    }

    // MARK: - Editor

    func startAdding() {
        editingProfile = nil
        isShowingEditor = true
    }

    func startEditing(_ profile: Profile) {
        editingProfile = profile
        isShowingEditor = true
    }

    func cancelEditing() {
        isShowingEditor = false
        editingProfile = nil
    }
}
