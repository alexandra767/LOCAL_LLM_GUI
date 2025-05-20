import Foundation
import Security

/// A helper class for securely storing and retrieving items from the keychain
public final class KeychainHelper {
    /// Shared instance
    static let shared = KeychainHelper()
    
    private init() {}
    
    /// Save a string to the keychain
    /// - Parameters:
    ///   - value: The string to save
    ///   - key: The key to associate with the value
    /// - Returns: A boolean indicating success or failure
    @discardableResult
    func save(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // Create a query for saving
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Load a string from the keychain
    /// - Parameter key: The key associated with the value
    /// - Returns: The retrieved string, or nil if not found or an error occurred
    func load(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    /// Delete an item from the keychain
    /// - Parameter key: The key of the item to delete
    /// - Returns: A boolean indicating success or failure
    @discardableResult
    func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Check if an item exists in the keychain
    /// - Parameter key: The key to check
    /// - Returns: A boolean indicating if the item exists
    func exists(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain as String: true
        ]
        
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }
}

// MARK: - API Key Management

public extension KeychainHelper {
    /// Save the API key to the keychain
    /// - Parameter apiKey: The API key to save
    /// - Returns: A boolean indicating success or failure
    @discardableResult
    func saveAPIKey(_ apiKey: String) -> Bool {
        return save(apiKey, for: "com.seraph.openai.apikey")
    }
    
    /// Retrieve the API key from the keychain
    /// - Returns: The API key if found, nil otherwise
    func retrieveAPIKey() -> String? {
        return load(for: "com.seraph.openai.apikey")
    }
    
    /// Delete the API key from the keychain
    /// - Returns: A boolean indicating success or failure
    @discardableResult
    func deleteAPIKey() -> Bool {
        return delete(for: "com.seraph.openai.apikey")
    }
    
    /// Check if an API key exists in the keychain
    /// - Returns: A boolean indicating if an API key exists
    func hasAPIKey() -> Bool {
        return exists(for: "com.seraph.openai.apikey")
    }
}

// MARK: - Keychain Errors

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidItemFormat
    case unexpectedStatus(OSStatus)
    
    static func error(from status: OSStatus) -> KeychainError? {
        switch status {
        case errSecSuccess: return nil
        case errSecItemNotFound: return .itemNotFound
        case errSecDuplicateItem: return .duplicateItem
        default: return .unexpectedStatus(status)
        }
    }
}
