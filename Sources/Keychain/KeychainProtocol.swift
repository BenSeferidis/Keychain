//
//  KeychainProtocol.swift
//  Keychain
//
//  Created by Ben Seferidis on 27/7/26.
//

import Foundation
import LocalAuthentication

/// Defines the asynchronous CRUD operations for storing, retrieving, and deleting `Codable` items in the system Keychain.
///
/// Types conforming to `KeychainProtocol` guarantee thread safety and data-race protection by isolating operations
/// within an actor execution context.
public protocol KeychainProtocol: Actor {
    
    /// Encodes and stores a `Codable & Sendable` item securely in the Keychain.
    ///
    /// - Parameters:
    ///   - item: The `Codable & Sendable` object to persist in the Keychain.
    ///   - key: A unique `KeychainKey` identifier for the item (e.g. `.password`).
    ///   - accessGroup: An optional Keychain access group string for sharing items across target applications. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    ///   - accessibility: The security accessibility policy for when the item can be read. Defaults to `.whenUnlocked`.
    ///   - accessControl: Optional biometric/passcode authentication flags (`KeychainAccessControl`). Defaults to `nil`.
    ///   - isSynchronizable: Whether the item syncs across user devices via iCloud Keychain. Defaults to `false`.
    ///   - updateIfExists: A boolean flag indicating whether an existing item with the same key should be updated. Defaults to `true`.
    ///   - encoder: The `JSONEncoder` instance used to serialize `item`. Defaults to `JSONEncoder()`.
    /// - Throws: A `KeychainError` if item encoding, insertion, or updating fails.
    func save<T: Codable & Sendable>(
        _ item: T,
        for key: KeychainKey,
        accessGroup: String?,
        service: String?,
        accessibility: KeychainAccessibility?,
        accessControl: KeychainAccessControl?,
        isSynchronizable: Bool,
        updateIfExists: Bool,
        encoder: JSONEncoder
    ) async throws
    
    /// Retrieves and decodes a stored `Codable & Sendable` item from the Keychain.
    ///
    /// - Parameters:
    ///   - key: The `KeychainKey` identifying the stored item.
    ///   - type: The expected `Codable` type `T` to decode.
    ///   - accessGroup: An optional Keychain access group string. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    ///   - isSynchronizable: Whether the item is synchronized via iCloud Keychain. Defaults to `false`.
    ///   - authenticationPrompt: Optional custom message displayed during biometric prompt. Defaults to `nil`.
    ///   - authenticationContext: Optional pre-authenticated `LAContext` to reuse. Defaults to `nil`.
    ///   - decoder: The `JSONDecoder` instance used to deserialize the Keychain payload. Defaults to `JSONDecoder()`.
    /// - Returns: The decoded object of type `T`.
    /// - Throws: A `KeychainError` if item lookup, retrieval, or decoding fails.
    func load<T: Codable & Sendable>(
        for key: KeychainKey,
        as type: T.Type,
        accessGroup: String?,
        service: String?,
        isSynchronizable: Bool,
        authenticationPrompt: String?,
        authenticationContext: KeychainAuthenticationContext?,
        decoder: JSONDecoder
    ) async throws -> T
    
    /// Stores raw binary `Data` in the Keychain without JSON serialization overhead.
    ///
    /// - Parameters:
    ///   - data: The raw `Data` payload to store.
    ///   - key: A unique `KeychainKey` identifier for the item.
    ///   - accessGroup: An optional Keychain access group string. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    ///   - accessibility: The accessibility policy for when data can be read. Defaults to `.whenUnlocked`.
    ///   - accessControl: Optional biometric/passcode authentication flags (`KeychainAccessControl`). Defaults to `nil`.
    ///   - isSynchronizable: Whether the item syncs across user devices via iCloud Keychain. Defaults to `false`.
    ///   - updateIfExists: Whether to overwrite an existing item with the same key. Defaults to `true`.
    /// - Throws: A `KeychainError` if storage fails.
    func saveData(
        _ data: Data,
        for key: KeychainKey,
        accessGroup: String?,
        service: String?,
        accessibility: KeychainAccessibility?,
        accessControl: KeychainAccessControl?,
        isSynchronizable: Bool,
        updateIfExists: Bool
    ) async throws
    
    /// Retrieves raw binary `Data` stored in the Keychain.
    ///
    /// - Parameters:
    ///   - key: The `KeychainKey` target.
    ///   - accessGroup: An optional Keychain access group string. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    ///   - isSynchronizable: Whether the item is synchronized via iCloud Keychain. Defaults to `false`.
    ///   - authenticationPrompt: Optional custom message displayed during biometric prompt. Defaults to `nil`.
    ///   - authenticationContext: Optional pre-authenticated `LAContext` to reuse. Defaults to `nil`.
    /// - Returns: The raw `Data` payload.
    /// - Throws: A `KeychainError` if retrieval fails.
    func loadData(
        for key: KeychainKey,
        accessGroup: String?,
        service: String?,
        isSynchronizable: Bool,
        authenticationPrompt: String?,
        authenticationContext: KeychainAuthenticationContext?
    ) async throws -> Data
    
    /// Stores a raw `String` in the Keychain using UTF-8 encoding without JSON overhead.
    ///
    /// - Parameters:
    ///   - string: The string payload to store.
    ///   - key: A unique `KeychainKey` identifier for the item.
    ///   - accessGroup: An optional Keychain access group string. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    ///   - accessibility: The accessibility policy for when the string can be read. Defaults to `.whenUnlocked`.
    ///   - accessControl: Optional biometric/passcode authentication flags (`KeychainAccessControl`). Defaults to `nil`.
    ///   - isSynchronizable: Whether the item syncs across user devices via iCloud Keychain. Defaults to `false`.
    ///   - updateIfExists: Whether to overwrite an existing item with the same key. Defaults to `true`.
    /// - Throws: A `KeychainError` if encoding or storage fails.
    func saveString(
        _ string: String,
        for key: KeychainKey,
        accessGroup: String?,
        service: String?,
        accessibility: KeychainAccessibility?,
        accessControl: KeychainAccessControl?,
        isSynchronizable: Bool,
        updateIfExists: Bool
    ) async throws
    
    /// Retrieves a raw `String` stored in the Keychain.
    ///
    /// - Parameters:
    ///   - key: The `KeychainKey` target.
    ///   - accessGroup: An optional Keychain access group string. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    ///   - isSynchronizable: Whether the item is synchronized via iCloud Keychain. Defaults to `false`.
    ///   - authenticationPrompt: Optional custom message displayed during biometric prompt. Defaults to `nil`.
    ///   - authenticationContext: Optional pre-authenticated `LAContext` to reuse. Defaults to `nil`.
    /// - Returns: The decoded UTF-8 string payload.
    /// - Throws: A `KeychainError` if lookup or UTF-8 decoding fails.
    func loadString(
        for key: KeychainKey,
        accessGroup: String?,
        service: String?,
        isSynchronizable: Bool,
        authenticationPrompt: String?,
        authenticationContext: KeychainAuthenticationContext?
    ) async throws -> String
    
    /// Checks whether an item associated with the specified key exists in the Keychain.
    ///
    /// - Parameters:
    ///   - key: The `KeychainKey` to check.
    ///   - accessGroup: An optional Keychain access group string. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    ///   - isSynchronizable: Whether the item is synchronized via iCloud Keychain. Defaults to `false`.
    /// - Returns: `true` if an item exists for the key, otherwise `false`.
    /// - Throws: A `KeychainError` if the query fails for reasons other than item non-existence.
    func exists(
        for key: KeychainKey,
        accessGroup: String?,
        service: String?,
        isSynchronizable: Bool
    ) async throws -> Bool
    
    /// Deletes an item from the Keychain.
    ///
    /// - Parameters:
    ///   - key: A unique `KeychainKey` identifying the item to remove.
    ///   - accessGroup: An optional Keychain access group string. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    ///   - isSynchronizable: Whether the item is synchronized via iCloud Keychain. Defaults to `false`.
    /// - Throws: A `KeychainError` if deletion fails for reasons other than item non-existence.
    func delete(
        for key: KeychainKey,
        accessGroup: String?,
        service: String?,
        isSynchronizable: Bool
    ) async throws
    
    /// Deletes all items managed by the application within the specified access group (or default access group).
    ///
    /// - Parameters:
    ///   - accessGroup: An optional Keychain access group string. Defaults to `nil`.
    ///   - service: An optional service identifier string. Defaults to `nil`.
    /// - Throws: A `KeychainError` if bulk deletion fails.
    func deleteAll(
        accessGroup: String?,
        service: String?
    ) async throws
}

