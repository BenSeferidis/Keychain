//
//  KeychainTests.swift
//  Keychain
//
//  Created by Ben Seferidis on 27/7/26.
//

import Foundation
import Security
import Testing
@testable import Keychain

// MARK: - Test Models

struct UserAccount: Codable, Equatable, Sendable {
    let id: UUID
    let username: String
    let email: String
    let createdDate: Date
}

struct IncompatiblePayload: Codable, Equatable, Sendable {
    let wrongField: Int
    let invalidString: String
}

struct SnakeCasePayload: Codable, Equatable, Sendable {
    let userIdentifier: String
    let authenticationToken: String
}

// MARK: - Error Tests

@Suite("KeychainError Comprehensive Tests")
struct KeychainErrorTests {

    @Test("Status Initializer Mapping for all OSStatus codes")
    func testOSStatusInitialization() {
        #expect(KeychainError(errSecItemNotFound) == .itemNotFound)
        #expect(KeychainError(errSecDuplicateItem) == .duplicateItem)
        #expect(KeychainError(errSecAuthFailed) == .authFailed)
        #expect(KeychainError(errSecUserCanceled) == .userCancelled)
        #expect(KeychainError(errSecInteractionNotAllowed) == .interactionNotAllowed)
        #expect(KeychainError(errSecMissingEntitlement) == .missingEntitlement)
        #expect(KeychainError(errSecParam) == .invalidParameters)
        #expect(KeychainError(errSecNotAvailable) == .notAvailable)
        #expect(KeychainError(errSecDecode) == .decodeFailed)
        #expect(KeychainError(errSecAllocate) == .allocateFailed)
        #expect(KeychainError(errSecIO) == .ioError)
        #expect(KeychainError(errSecUnimplemented) == .unimplemented)
        #expect(KeychainError(errSecDataTooLarge) == .invalidData)
        #expect(KeychainError(-1234) == .unexpectedStatus(-1234))
    }

    @Test("CaseIterable Conformance")
    func testCaseIterable() {
        let allCases = KeychainError.allCases
        #expect(allCases.count == 15)
        #expect(allCases.contains(.itemNotFound))
        #expect(allCases.contains(.duplicateItem))
        #expect(allCases.contains(.authFailed))
        #expect(allCases.contains(.userCancelled))
        #expect(allCases.contains(.interactionNotAllowed))
        #expect(allCases.contains(.missingEntitlement))
        #expect(allCases.contains(.invalidParameters))
        #expect(allCases.contains(.invalidData))
        #expect(allCases.contains(.notAvailable))
        #expect(allCases.contains(.decodeFailed))
        #expect(allCases.contains(.allocateFailed))
        #expect(allCases.contains(.ioError))
        #expect(allCases.contains(.unimplemented))
        #expect(allCases.contains(.unexpectedStatus(errSecSuccess)))
        #expect(allCases.contains(.incorrectAttributesForClass))
    }

    @Test("LocalizedError Conformance Properties")
    func testLocalizedErrorProperties() {
        for error in KeychainError.allCases {
            #expect(error.errorDescription != nil && !error.errorDescription!.isEmpty)
            #expect(error.failureReason != nil && !error.failureReason!.isEmpty)
            #expect(error.recoverySuggestion != nil && !error.recoverySuggestion!.isEmpty)
        }
    }
}

// MARK: - Key & ItemClass Tests

@Suite("KeychainKey & ItemClass Tests")
struct KeychainKeyTests {

    @Test("KeychainKey Enum Properties")
    func testKeychainKeys() {
        #expect(KeychainKey.password.rawValue == "password")
        #expect(KeychainKey.authToken.rawValue == "authToken")
        #expect(KeychainKey.refreshToken.rawValue == "refreshToken")
        #expect(KeychainKey.userCredentials.rawValue == "userCredentials")
        
        #expect(KeychainKey.allCases.count == 4)
        
        for key in KeychainKey.allCases {
            #expect(key.itemClass.isPasswordClass)
        }
    }

    @Test("ItemClass Raw Values and Classification")
    func testItemClassRawValues() {
        #expect(KeychainKey.ItemClass.generic.rawValue == kSecClassGenericPassword)
        #expect(KeychainKey.ItemClass.password.rawValue == kSecClassInternetPassword)
        #expect(KeychainKey.ItemClass.certificate().rawValue == kSecClassCertificate)
        #expect(KeychainKey.ItemClass.cryptography.rawValue == kSecClassKey)
        #expect(KeychainKey.ItemClass.identity.rawValue == kSecClassIdentity)

        #expect(KeychainKey.ItemClass.generic.isPasswordClass)
        #expect(KeychainKey.ItemClass.password.isPasswordClass)
        #expect(!KeychainKey.ItemClass.certificate(exportPassphrase: "secret").isPasswordClass)
        #expect(!KeychainKey.ItemClass.cryptography.isPasswordClass)
        #expect(!KeychainKey.ItemClass.identity.isPasswordClass)
    }
}

@Suite("KeychainAccessControl Tests")
struct KeychainAccessControlTests {

    @Test("KeychainAccessControl Flags and SecAccessControl Creation")
    func testAccessControlCreation() throws {
        #expect(KeychainAccessControl.userPresence.flags == .userPresence)
        #expect(KeychainAccessControl.biometryAny.flags == .biometryAny)
        #expect(KeychainAccessControl.biometryCurrentSet.flags == .biometryCurrentSet)
        #expect(KeychainAccessControl.allCases.count == 3)

        let secControl = try KeychainAccessControl.userPresence.createSecAccessControl(protection: .whenUnlocked)
        #expect(CFGetTypeID(secControl) == SecAccessControlGetTypeID())
    }
}

@Suite("KeychainAccessibility Tests")
struct KeychainAccessibilityTests {

    @Test("KeychainAccessibility Raw CFString Mapping")
    func testAccessibilityCFStrings() {
        #expect(KeychainAccessibility.whenUnlocked.secAccessible == kSecAttrAccessibleWhenUnlocked)
        #expect(KeychainAccessibility.afterFirstUnlock.secAccessible == kSecAttrAccessibleAfterFirstUnlock)
        #expect(KeychainAccessibility.whenPasscodeSetThisDeviceOnly.secAccessible == kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
        #expect(KeychainAccessibility.whenUnlockedThisDeviceOnly.secAccessible == kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        #expect(KeychainAccessibility.afterFirstUnlockThisDeviceOnly.secAccessible == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
        
        #expect(KeychainAccessibility.allCases.count == 5)
    }
}


// MARK: - Integration Scenarios

@Suite("Keychain Integration Scenario Tests", .serialized)
struct KeychainScenarioTests {

    @Test("Scenario 1: Save, Load, Overwrite and Delete Item")
    func testStandardCRUDScenario() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.authToken
        let initialAccount = UserAccount(id: UUID(), username: "john_doe", email: "john@example.com", createdDate: Date(timeIntervalSince1970: 1000))

        // Cleanup
        try? await keychain.delete(for: key)

        // Save
        try await keychain.save(initialAccount, for: key)

        // Load
        let loaded = try await keychain.load(for: key, as: UserAccount.self)
        #expect(loaded.id == initialAccount.id)
        #expect(loaded.username == initialAccount.username)
        #expect(loaded.email == initialAccount.email)

        // Overwrite
        let updatedAccount = UserAccount(id: initialAccount.id, username: "john_updated", email: "john_updated@example.com", createdDate: Date(timeIntervalSince1970: 2000))
        try await keychain.save(updatedAccount, for: key, updateIfExists: true)

        let reloaded = try await keychain.load(for: key, as: UserAccount.self)
        #expect(reloaded.username == "john_updated")
        #expect(reloaded.email == "john_updated@example.com")

        // Delete
        try await keychain.delete(for: key)

        // Verify deletion
        await #expect(throws: KeychainError.itemNotFound) {
            _ = try await keychain.load(for: key, as: UserAccount.self)
        }
    }

    @Test("Scenario 2: Duplicate Item throwing duplicateItem when updateIfExists is false")
    func testDuplicateItemStrategy() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.userCredentials
        let account = UserAccount(id: UUID(), username: "alice", email: "alice@example.com", createdDate: Date())

        try? await keychain.delete(for: key)

        // Initial save
        try await keychain.save(account, for: key)

        // Save duplicate with updateIfExists = false -> should throw .duplicateItem
        await #expect(throws: KeychainError.duplicateItem) {
            try await keychain.save(account, for: key, updateIfExists: false)
        }

        try? await keychain.delete(for: key)
    }

    @Test("Scenario 3: Loading non-existent item throws itemNotFound")
    func testLoadMissingItem() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.refreshToken

        try? await keychain.delete(for: key)

        await #expect(throws: KeychainError.itemNotFound) {
            _ = try await keychain.load(for: key, as: UserAccount.self)
        }
    }

    @Test("Scenario 4: Deleting non-existent item succeeds silently")
    func testDeleteMissingItemSucceeds() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.password

        try? await keychain.delete(for: key)
        
        // Deleting non-existent item should not throw
        try await keychain.delete(for: key)
    }

    @Test("Scenario 5: Incompatible JSON Payload throws decodeFailed")
    func testDecodeFailedScenario() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.password
        let account = UserAccount(id: UUID(), username: "bob", email: "bob@example.com", createdDate: Date())

        try? await keychain.delete(for: key)
        try await keychain.save(account, for: key)

        // Attempting to decode UserAccount JSON into IncompatiblePayload struct
        await #expect(throws: KeychainError.decodeFailed) {
            _ = try await keychain.load(for: key, as: IncompatiblePayload.self)
        }

        try? await keychain.delete(for: key)
    }

    @Test("Scenario 6: Custom JSONEncoder and JSONDecoder strategies")
    func testCustomEncoderDecoderStrategies() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.authToken
        let payload = SnakeCasePayload(userIdentifier: "usr_999", authenticationToken: "bearer_xyz")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        try? await keychain.delete(for: key)

        try await keychain.save(payload, for: key, encoder: encoder)
        let loaded = try await keychain.load(for: key, as: SnakeCasePayload.self, decoder: decoder)

        #expect(loaded == payload)

        try? await keychain.delete(for: key)
    }

    @Test("Scenario 7: Raw Data Storage and Retrieval")
    func testRawDataStorage() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.authToken
        let rawBytes = Data([0x01, 0x02, 0x03, 0x04, 0xFF])

        try? await keychain.delete(for: key)

        try await keychain.saveData(rawBytes, for: key, accessibility: .whenUnlocked)
        let loadedBytes = try await keychain.loadData(for: key)

        #expect(loadedBytes == rawBytes)

        try? await keychain.delete(for: key)
    }

    @Test("Scenario 8: Raw String Storage and Retrieval")
    func testRawStringStorage() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.userCredentials
        let rawToken = "raw_secret_api_key_12345"

        try? await keychain.delete(for: key)

        try await keychain.saveString(rawToken, for: key, accessibility: .afterFirstUnlock)
        let loadedToken = try await keychain.loadString(for: key)

        #expect(loadedToken == rawToken)

        try? await keychain.delete(for: key)
    }

    @Test("Scenario 9: Key Existence Check (exists)")
    func testKeyExistence() async throws {
        let keychain = Keychain.shared
        let key = KeychainKey.refreshToken

        try? await keychain.delete(for: key)
        let existsBefore = try await keychain.exists(for: key)
        #expect(!existsBefore)

        try await keychain.saveString("refresh_token_abc", for: key)
        let existsAfter = try await keychain.exists(for: key)
        #expect(existsAfter)

        try? await keychain.delete(for: key)
    }

    @Test("Scenario 10: Bulk Delete (deleteAll)")
    func testBulkDeleteAll() async throws {
        let keychain = Keychain.shared
        
        try await keychain.saveString("pass1", for: .password)
        try await keychain.saveString("token1", for: .authToken)

        #expect(try await keychain.exists(for: .password))
        #expect(try await keychain.exists(for: .authToken))

        try await keychain.deleteAll()

        #expect(!(try await keychain.exists(for: .password)))
        #expect(!(try await keychain.exists(for: .authToken)))
    }

    @Test("Scenario 11: Concurrent thread-safe execution under multi-task load")
    func testConcurrentActorOperations() async throws {
        let keychain = Keychain.shared
        let keys = KeychainKey.allCases

        // Run 10 parallel tasks saving and loading across different keys concurrently
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<10 {
                group.addTask {
                    let key = keys[index % keys.count]
                    let account = UserAccount(id: UUID(), username: "user_\(index)", email: "user_\(index)@test.com", createdDate: Date())
                    try? await keychain.save(account, for: key)
                    let _ = try? await keychain.load(for: key, as: UserAccount.self)
                }
            }
        }

        // Clean up
        try? await keychain.deleteAll()
    }
}




