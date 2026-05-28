import Foundation
import Observation
import LLMFlexCore

/// The view model. Owns the storage, target, and live status. Views observe
/// `profiles` and `codexStatus`; mutations route through methods here so
/// state stays consistent across re-renders.
@MainActor
@Observable
final class AppModel {
    static let editorWindowID = "profile-editor"

    // Storage / services
    let profileStore: ProfileStore
    let keychain: KeychainStore
    let codex: CodexTarget
    let claudeCode: ClaudeCodeTarget
    let tester: ConnectivityTester
    let migrator: SwitchCodeCleanup

    // Published state
    var profiles: [Profile] = []
    var codexStatus: TargetStatus
    var claudeCodeStatus: TargetStatus
    var lastError: String?
    var lastApplyMessage: String?
    var legacyCleanupAvailable: Bool = false

    // Editor state — editingProfile is what the standalone window edits.
    // editorOpenToken bumps every time we want PopoverView to call openWindow,
    // so re-clicking Add/Edit re-focuses an already-open window.
    var editingProfile: Profile?
    var editorOpenToken: Int = 0

    init(
        profileStore: ProfileStore = ProfileStore(),
        keychain: KeychainStore = KeychainStore(),
        codex: CodexTarget = CodexTarget(),
        claudeCode: ClaudeCodeTarget = ClaudeCodeTarget(),
        tester: ConnectivityTester = ConnectivityTester(),
        migrator: SwitchCodeCleanup = SwitchCodeCleanup()
    ) {
        self.profileStore = profileStore
        self.keychain = keychain
        self.codex = codex
        self.claudeCode = claudeCode
        self.tester = tester
        self.migrator = migrator
        // Synchronous best-effort initial inspect so the first render has data.
        self.codexStatus = (try? codex.inspect()) ?? Self.placeholderStatus(for: .codex)
        self.claudeCodeStatus = (try? claudeCode.inspect()) ?? Self.placeholderStatus(for: .claudeCode)
        reload()
    }

    private static func placeholderStatus(for id: TargetID) -> TargetStatus {
        TargetStatus(
            target: id,
            activeProviderKey: nil,
            activeProviderLabel: nil,
            activeModel: nil,
            activeBaseURL: nil,
            authMode: .unknown,
            applicationRunning: false
        )
    }

    // MARK: - Lifecycle

    func reload() {
        profiles = profileStore.all()
        do {
            codexStatus = try codex.inspect()
            claudeCodeStatus = try claudeCode.inspect()
        } catch {
            lastError = error.localizedDescription
        }
        let configContent = (try? String(contentsOf: codex.configURL, encoding: .utf8)) ?? ""
        legacyCleanupAvailable = migrator.needsCleanup(configContent)
    }

    /// Targets a profile can validly be applied to (provider's wire format
    /// is native for those targets).
    func applicableTargets(for profile: Profile) -> [TargetID] {
        TargetID.allCases.filter { profile.provider.compatibility(for: $0) == .native }
    }

    // MARK: - Derived state

    /// True if any target the profile would apply to currently points at it.
    func isApplied(_ profile: Profile) -> Bool {
        for target in applicableTargets(for: profile) {
            if let onDisk = status(for: target).activeBaseURL,
               profileMatches(profile, baseURL: onDisk) {
                return true
            }
        }
        return false
    }

    func status(for target: TargetID) -> TargetStatus {
        switch target {
        case .codex: return codexStatus
        case .claudeCode: return claudeCodeStatus
        }
    }

    /// The profile currently matching the on-disk state of `target`, if any.
    /// Used by the UI to render the active provider's badge.
    func activeProfile(for target: TargetID) -> Profile? {
        let s = status(for: target)
        guard let baseURL = s.activeBaseURL else { return nil }
        return profiles.first { p in
            applicableTargets(for: p).contains(target) && profileMatches(p, baseURL: baseURL)
        }
    }

    /// Profile.baseURL may include /v1 while a target's on-disk URL may not
    /// (e.g. Claude Code strips it for ANTHROPIC_BASE_URL). Match on prefix
    /// either way so the UI lights up correctly.
    private func profileMatches(_ profile: Profile, baseURL onDisk: String) -> Bool {
        if profile.baseURL == onDisk { return true }
        if profile.baseURL.hasPrefix(onDisk) { return true }
        if onDisk.hasPrefix(profile.baseURL) { return true }
        return false
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
        let raw = (try? keychain.key(for: profile.id)) ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Apply / restore

    func apply(_ profile: Profile) {
        do {
            let key = loadKey(for: profile)
            if profile.provider.requiresAPIKey, key.isEmpty {
                throw TargetError.noAPIKey
            }
            let targets = applicableTargets(for: profile)
            if targets.isEmpty {
                throw TargetError.blocked(.chatgptLoginActive) // sentinel — will surface as a clear error in UI text
            }
            var appliedNames: [String] = []
            for target in targets {
                switch target {
                case .codex:
                    try codex.apply(profile: profile, apiKey: key)
                    appliedNames.append("Codex")
                case .claudeCode:
                    try claudeCode.apply(profile: profile, apiKey: key)
                    appliedNames.append("Claude Code")
                }
            }
            profileStore.activeID = profile.id
            lastApplyMessage = "Switched \(appliedNames.joined(separator: " + ")) to \(profile.name)."
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            lastApplyMessage = nil
        }
        reload()
    }

    func restoreDefaults() {
        var restoredAny = false
        do {
            restoredAny = try codex.restore() || restoredAny
            restoredAny = try claudeCode.restore() || restoredAny
            profileStore.activeID = nil
            lastApplyMessage = restoredAny
                ? "Restored Codex and Claude Code to original state."
                : "Cleared LLM Flex config (no snapshots to restore from)."
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
            // 1. Strip SwitchCode artifacts from the CURRENT config. Keep
            //    our active managed block in place.
            let url = codex.configURL
            let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            let cleaned = migrator.clean(existing)
            try cleaned.write(to: url, atomically: true, encoding: .utf8)

            // 2. Also scrub the snapshot: remove SwitchCode artifacts AND
            //    any LLM Flex managed block. The snapshot should represent
            //    Codex AS IF LLM Flex (and the broken v1) had never touched
            //    it — so a future Restore unwinds cleanly to that baseline.
            let snap = codex.snapshots.snapshotURL(for: url, tag: CodexTarget.snapshotTag)
            if FileManager.default.fileExists(atPath: snap.path) {
                let snapContent = try String(contentsOf: snap, encoding: .utf8)
                let snapCleaned = migrator.clean(snapContent)
                let editor = TOMLBlockEditor(
                    startMarker: CodexTarget.blockStartMarker,
                    endMarker: CodexTarget.blockEndMarker
                )
                let snapStripped = editor.strip(source: snapCleaned)
                try snapStripped.write(to: snap, atomically: true, encoding: .utf8)
            }
            lastApplyMessage = "Cleaned up legacy SwitchCode entries and reset snapshot baseline."
        } catch {
            lastError = error.localizedDescription
        }
        reload()
    }

    // MARK: - Editor

    func startAdding() {
        editingProfile = nil
        editorOpenToken &+= 1
    }

    func startEditing(_ profile: Profile) {
        editingProfile = profile
        editorOpenToken &+= 1
    }

    func cancelEditing() {
        editingProfile = nil
    }
}
