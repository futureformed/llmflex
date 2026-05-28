import Foundation

public enum TargetError: Error, LocalizedError {
    case blocked(BlockReason)
    case noAPIKey
    case ioFailure(String, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .blocked(let r):
            switch r {
            case .chatgptLoginActive:
                return "Codex.app is signed in via ChatGPT. Sign out in Codex Settings before switching providers — otherwise Codex.app will overwrite the API key on its next launch."
            }
        case .noAPIKey:
            return "No API key was provided for this profile."
        case .ioFailure(let what, let underlying):
            return "\(what): \(underlying.localizedDescription)"
        }
    }
}

/// A switchable AI-CLI / app. Today: Codex. Tomorrow: Claude Code.
public protocol Target: AnyObject, Sendable {
    var id: TargetID { get }
    var displayName: String { get }

    /// Read-only inspection of the target's current on-disk state.
    func inspect() throws -> TargetStatus

    /// Whether `apply` is safe to call right now.
    func policy() throws -> ApplyPolicy

    /// Apply a profile to the target. Throws `TargetError.blocked` if policy
    /// says no.
    func apply(profile: Profile, apiKey: String) throws

    /// Roll back to the state captured before LLM Flex first touched this
    /// target. Returns true if a snapshot existed and was restored.
    @discardableResult
    func restore() throws -> Bool
}
