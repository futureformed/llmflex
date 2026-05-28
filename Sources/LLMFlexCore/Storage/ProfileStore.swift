import Foundation

/// UserDefaults-backed CRUD for Profiles. API keys are NOT stored here — see
/// `KeychainStore`. Only safe-to-serialize fields (name, base URL, model)
/// pass through this layer.
public final class ProfileStore: @unchecked Sendable {
    public static let defaultProfilesKey = "cc.holdtight.llmflex.profiles"
    public static let defaultActiveKey = "cc.holdtight.llmflex.activeProfile"

    private let defaults: UserDefaults
    private let profilesKey: String
    private let activeKey: String

    public init(
        defaults: UserDefaults = .standard,
        profilesKey: String = ProfileStore.defaultProfilesKey,
        activeKey: String = ProfileStore.defaultActiveKey
    ) {
        self.defaults = defaults
        self.profilesKey = profilesKey
        self.activeKey = activeKey
    }

    public func all() -> [Profile] {
        guard let data = defaults.data(forKey: profilesKey) else { return [] }
        return (try? JSONDecoder().decode([Profile].self, from: data)) ?? []
    }

    public func replaceAll(_ profiles: [Profile]) {
        let data = try? JSONEncoder().encode(profiles)
        defaults.set(data, forKey: profilesKey)
    }

    public func upsert(_ profile: Profile) {
        var list = all()
        if let i = list.firstIndex(where: { $0.id == profile.id }) {
            list[i] = profile
        } else {
            list.append(profile)
        }
        replaceAll(list)
    }

    public func delete(id: UUID) {
        var list = all()
        list.removeAll { $0.id == id }
        replaceAll(list)
        if activeID == id { activeID = nil }
    }

    public var activeID: UUID? {
        get {
            guard let s = defaults.string(forKey: activeKey) else { return nil }
            return UUID(uuidString: s)
        }
        set {
            if let id = newValue {
                defaults.set(id.uuidString, forKey: activeKey)
            } else {
                defaults.removeObject(forKey: activeKey)
            }
        }
    }
}
