import Foundation
import Security

public enum KeychainStoreError: Error, LocalizedError {
    case osStatus(OSStatus)
    case dataConversion

    public var errorDescription: String? {
        switch self {
        case .osStatus(let s): "Keychain error (\(s))"
        case .dataConversion: "Keychain data could not be decoded"
        }
    }
}

/// Stores API keys in the user's login keychain, keyed by profile ID.
/// Keys never leave this class as part of the Profile model.
public final class KeychainStore: @unchecked Sendable {
    public let service: String

    public init(service: String = "cc.holdtight.llmflex.apikeys") {
        self.service = service
    }

    public func set(_ key: String, for profileID: UUID) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainStoreError.dataConversion
        }
        let account = profileID.uuidString
        // Replace any existing item.
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(baseQuery as CFDictionary)

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainStoreError.osStatus(status)
        }
    }

    public func key(for profileID: UUID) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: profileID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let s = String(data: data, encoding: .utf8) else {
                throw KeychainStoreError.dataConversion
            }
            return s
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainStoreError.osStatus(status)
        }
    }

    public func delete(_ profileID: UUID) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: profileID.uuidString,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.osStatus(status)
        }
    }
}
