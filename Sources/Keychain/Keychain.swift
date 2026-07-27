// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Security
import LocalAuthentication

/// A thread-safe, actor-isolated manager for performing secure Keychain operations.
///
/// `Keychain` acts as a global actor and singleton actor implementation conforming to `KeychainProtocol`.
/// It manages the lifecycle, storage, retrieval, and deletion of `Codable & Sendable` items using Apple's Security framework APIs.
@globalActor
public actor Keychain: KeychainProtocol {
    
    // MARK: - Properties
    
    /// The shared singleton instance of `Keychain`.
    public static let shared = Keychain()
    
    // MARK: - Initialization
    
    private init() {}
    
    deinit {}
    
    // MARK: - Public Codable Methods
    
    /// Encodes and stores a `Codable & Sendable` item securely in the Keychain.
    public func save<T: Codable & Sendable>(
        _ item: T,
        for key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        accessibility: KeychainAccessibility? = .whenUnlocked,
        accessControl: KeychainAccessControl? = nil,
        isSynchronizable: Bool = false,
        updateIfExists: Bool = true,
        encoder: JSONEncoder = JSONEncoder()
    ) async throws {
        let data = try encoder.encode(item)
        try await saveData(
            data,
            for: key,
            accessGroup: accessGroup,
            service: service,
            accessibility: accessibility,
            accessControl: accessControl,
            isSynchronizable: isSynchronizable,
            updateIfExists: updateIfExists
        )
    }
    
    /// Retrieves and decodes a stored `Codable & Sendable` item from the Keychain.
    public func load<T: Codable & Sendable>(
        for key: KeychainKey,
        as type: T.Type,
        accessGroup: String? = nil,
        service: String? = nil,
        isSynchronizable: Bool = false,
        authenticationPrompt: String? = nil,
        authenticationContext: KeychainAuthenticationContext? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let data = try await loadData(
            for: key,
            accessGroup: accessGroup,
            service: service,
            isSynchronizable: isSynchronizable,
            authenticationPrompt: authenticationPrompt,
            authenticationContext: authenticationContext
        )
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw KeychainError.decodeFailed
        }
    }
    
    // MARK: - Public Raw Data & String Methods
    
    /// Stores raw binary `Data` in the Keychain without JSON serialization.
    public func saveData(
        _ data: Data,
        for key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        accessibility: KeychainAccessibility? = .whenUnlocked,
        accessControl: KeychainAccessControl? = nil,
        isSynchronizable: Bool = false,
        updateIfExists: Bool = true
    ) async throws {
        var addQuery = baseQuery(
            key: key,
            accessGroup: accessGroup,
            service: service,
            isSynchronizable: isSynchronizable
        )
        
        let classExtras = try attributesForAdd(
            itemClass: key.itemClass,
            data: data,
            accessibility: accessibility,
            accessControl: accessControl
        )
        
        classExtras.forEach { addQuery[$0] = $1 }
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if status == errSecDuplicateItem, updateIfExists {
            try update(
                data: data,
                for: key,
                accessGroup: accessGroup,
                service: service,
                accessibility: accessibility,
                isSynchronizable: isSynchronizable
            )
        } else if status != errSecSuccess {
            throw KeychainError(status)
        }
    }
    
    /// Retrieves raw binary `Data` stored in the Keychain.
    public func loadData(
        for key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        isSynchronizable: Bool = false,
        authenticationPrompt: String? = nil,
        authenticationContext: KeychainAuthenticationContext? = nil
    ) async throws -> Data {
        var query = baseQuery(
            key: key,
            accessGroup: accessGroup,
            service: service,
            isSynchronizable: isSynchronizable
        )
        
        let classExtras = try attributesForLoad(
            itemClass: key.itemClass,
            authenticationPrompt: authenticationPrompt,
            authenticationContext: authenticationContext
        )
        
        classExtras.forEach { query[$0] = $1 }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { throw KeychainError(status) }
        
        guard let data = try dataFromResult(result, itemClass: key.itemClass) else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    /// Stores a raw `String` in the Keychain using UTF-8 encoding.
    public func saveString(
        _ string: String,
        for key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        accessibility: KeychainAccessibility? = .whenUnlocked,
        accessControl: KeychainAccessControl? = nil,
        isSynchronizable: Bool = false,
        updateIfExists: Bool = true
    ) async throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try await saveData(
            data,
            for: key,
            accessGroup: accessGroup,
            service: service,
            accessibility: accessibility,
            accessControl: accessControl,
            isSynchronizable: isSynchronizable,
            updateIfExists: updateIfExists
        )
    }
    
    /// Retrieves a raw `String` stored in the Keychain.
    public func loadString(
        for key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        isSynchronizable: Bool = false,
        authenticationPrompt: String? = nil,
        authenticationContext: KeychainAuthenticationContext? = nil
    ) async throws -> String {
        let data = try await loadData(
            for: key,
            accessGroup: accessGroup,
            service: service,
            isSynchronizable: isSynchronizable,
            authenticationPrompt: authenticationPrompt,
            authenticationContext: authenticationContext
        )
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodeFailed
        }
        return string
    }
    
    // MARK: - Existence & Deletion Methods
    
    /// Checks whether an item associated with the specified key exists in the Keychain.
    public func exists(
        for key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        isSynchronizable: Bool = false
    ) async throws -> Bool {
        var query = baseQuery(key: key, accessGroup: accessGroup, service: service, isSynchronizable: isSynchronizable)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnAttributes] = false as CFBoolean
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            throw KeychainError(status)
        }
    }
    
    /// Deletes an item matching the specified key from the Keychain.
    public func delete(
        for key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        isSynchronizable: Bool = false
    ) async throws {
        let query = baseQuery(
            key: key,
            accessGroup: accessGroup,
            service: service,
            isSynchronizable: isSynchronizable
        )
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status)
        }
    }
    
    /// Deletes all items managed by the application within the specified access group and service namespace.
    public func deleteAll(
        accessGroup: String? = nil,
        service: String? = nil
    ) async throws {
        for key in KeychainKey.allCases {
            try await delete(for: key, accessGroup: accessGroup, service: service)
        }
    }
}

// MARK: - Private Helpers

private extension Keychain {
    
    /// Updates an existing Keychain entry with new payload data, accessibility, and synchronizability.
    func update(
        data: Data,
        for key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        accessibility: KeychainAccessibility? = nil,
        isSynchronizable: Bool = false
    ) throws {
        let search = baseQuery(
            key: key,
            accessGroup: accessGroup,
            service: service,
            isSynchronizable: isSynchronizable
        )
        
        var attributes: [CFString: Any] = [ kSecValueData: data ]
        if let accessibility {
            attributes[kSecAttrAccessible] = accessibility.secAccessible
        }
        
        let status = SecItemUpdate(search as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError(status)
        }
    }
    
    /// Generates the fundamental search query dictionary for a given `KeychainKey`.
    func baseQuery(
        key: KeychainKey,
        accessGroup: String? = nil,
        service: String? = nil,
        isSynchronizable: Bool = false
    ) -> [CFString: Any] {
        var query: [CFString: Any] = [ kSecClass: key.itemClass.rawValue ]
        if key.itemClass.isPasswordClass {
            query[kSecAttrAccount] = key.rawValue
        }
        
        if let accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }
        
        if let service {
            query[kSecAttrService] = service
        }
        
        query[kSecAttrSynchronizable] = isSynchronizable as CFBoolean
        
        return query
    }
    
    /// Constructs additional attributes required when executing `SecItemAdd`.
    func attributesForAdd(
        itemClass: KeychainKey.ItemClass,
        data: Data,
        accessibility: KeychainAccessibility? = nil,
        accessControl: KeychainAccessControl? = nil
    ) throws -> [CFString: Any] {
        var dict: [CFString: Any] = [:]
        
        if let accessControl {
            let secAccessControl = try accessControl.createSecAccessControl(protection: accessibility ?? .whenUnlocked)
            dict[kSecAttrAccessControl] = secAccessControl
        } else if let accessibility {
            dict[kSecAttrAccessible] = accessibility.secAccessible
        }
        
        switch itemClass {
        case .generic, .password:
            dict[kSecValueData] = data
            return dict
        case .certificate(let exportPassphrase):
            dict[kSecValueData] = data
            dict[kSecImportExportPassphrase] = exportPassphrase ?? ""
            return dict
        case .cryptography, .identity:
            throw KeychainError.incorrectAttributesForClass
        }
    }
    
    /// Constructs additional attributes required when querying `SecItemCopyMatching`.
    func attributesForLoad(
        itemClass: KeychainKey.ItemClass,
        authenticationPrompt: String? = nil,
        authenticationContext: KeychainAuthenticationContext? = nil
    ) throws -> [CFString: Any] {
        var dict: [CFString: Any] = [:]
        
        if let authenticationPrompt {
            dict[kSecUseOperationPrompt] = authenticationPrompt
        }
        
        if let authenticationContext {
            dict[kSecUseAuthenticationContext] = authenticationContext.context
        }
        
        switch itemClass {
        case .generic, .password:
            dict[kSecReturnData] = true as CFBoolean
            dict[kSecMatchLimit] = kSecMatchLimitOne
            return dict
        case .certificate:
            dict[kSecReturnRef] = true as CFBoolean
            return dict
        case .cryptography:
            dict[kSecReturnRef] = true as CFBoolean
            dict[kSecMatchLimit] = kSecMatchLimitOne
            return dict
        case .identity:
            dict[kSecReturnRef] = true as CFBoolean
            dict[kSecMatchLimit] = kSecMatchLimitOne
            return dict
        }
    }
    
    /// Extracts raw `Data` from a `SecItemCopyMatching` query result.
    func dataFromResult(
        _ result: AnyObject?,
        itemClass: KeychainKey.ItemClass
    ) throws -> Data? {
        switch itemClass {
        case .generic, .password:
            return result as? Data
        case .certificate:
            guard let cfRef = result as CFTypeRef?,
                  CFGetTypeID(cfRef) == SecCertificateGetTypeID()
            else {
                throw KeychainError.invalidData
            }
            
            let cert = unsafeDowncast(cfRef, to: SecCertificate.self)
            return SecCertificateCopyData(cert) as Data
        case .cryptography:
            guard let cfRef = result as CFTypeRef?,
                  CFGetTypeID(cfRef) == SecKeyGetTypeID()
            else {
                throw KeychainError.invalidData
            }
            
            let secKey = unsafeDowncast(cfRef, to: SecKey.self)
            
            var error: Unmanaged<CFError>?
            guard let data = SecKeyCopyExternalRepresentation(secKey, &error) as? Data else {
                throw error?.takeRetainedValue() as? KeychainError
                ?? KeychainError.invalidData
            }
            
            return data
        case .identity:
            throw KeychainError.incorrectAttributesForClass
        }
    }
}

