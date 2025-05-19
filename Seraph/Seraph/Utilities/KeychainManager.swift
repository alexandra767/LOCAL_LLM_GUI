//
//  KeychainManager.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import Security

/// Utility for securely storing and retrieving sensitive data in the keychain
class KeychainManager {
    
    // MARK: - Constants
    
    /// Service name for keychain items
    private static let serviceName = "com.alexandratitus.Seraph"
    
    // MARK: - CRUD Operations
    
    /// Save a string value to the keychain for a given key
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("Error converting value to data")
            return false
        }
        
        // Create query dictionary
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as [CFString: Any]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve a string value from the keychain for a given key
    static func retrieve(key: String) -> String? {
        // Create query dictionary
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [CFString: Any]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// Update an existing keychain item
    static func update(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("Error converting value to data")
            return false
        }
        
        // Create query dictionary
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: key
        ] as [CFString: Any]
        
        // Create update dictionary
        let attributes = [
            kSecValueData: data
        ] as [CFString: Any]
        
        // Update the item
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        return status == errSecSuccess
    }
    
    /// Delete a keychain item for a given key
    static func delete(key: String) -> Bool {
        // Create query dictionary
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: key
        ] as [CFString: Any]
        
        // Delete the item
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Convenience Methods
    
    /// Save or update an API key
    static func saveApiKey(for provider: LLMProvider, key: String) -> Bool {
        let keyIdentifier = "api_key_\(provider.rawValue.lowercased())"
        return save(key: keyIdentifier, value: key)
    }
    
    /// Get an API key for a provider
    static func getApiKey(for provider: LLMProvider) -> String? {
        let keyIdentifier = "api_key_\(provider.rawValue.lowercased())"
        return retrieve(key: keyIdentifier)
    }
    
    /// Delete an API key for a provider
    static func deleteApiKey(for provider: LLMProvider) -> Bool {
        let keyIdentifier = "api_key_\(provider.rawValue.lowercased())"
        return delete(key: keyIdentifier)
    }
    
    /// Load all stored API keys
    static func loadAllApiKeys() -> [LLMProvider: String] {
        var apiKeys: [LLMProvider: String] = [:]
        
        for provider in LLMProvider.allCases {
            if let key = getApiKey(for: provider), !key.isEmpty {
                apiKeys[provider] = key
            }
        }
        
        return apiKeys
    }
}