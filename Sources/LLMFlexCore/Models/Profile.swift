import Foundation

/// A user-defined provider configuration. Crucially, the API key is NOT a
/// stored field — it lives in the Keychain and is fetched on demand at apply
/// time. This keeps it out of UserDefaults, JSON encodings, logs, and stack
/// traces.
public struct Profile: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var provider: Provider
    public var baseURL: String
    public var modelName: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        provider: Provider,
        baseURL: String = "",
        modelName: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.baseURL = baseURL.isEmpty ? provider.defaultBaseURL : baseURL
        self.modelName = modelName
        self.createdAt = createdAt
    }
}
