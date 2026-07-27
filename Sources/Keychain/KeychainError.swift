//
//  KeychainError.swift
//  Keychain
//
//  Created by Ben Seferidis on 27/7/26.
//

import Foundation
import Security

/// An enumeration representing errors that can occur during Keychain operations.
///
/// `KeychainError` maps common Security framework `OSStatus` result codes into type-safe Swift error cases,
/// while providing localized error descriptions, failure reasons, recovery suggestions, and `CaseIterable` support.
public enum KeychainError: Error, Sendable {
    /// The requested item does not exist in the Keychain (`errSecItemNotFound`).
    case itemNotFound
    
    /// An item with the same identity already exists in the Keychain (`errSecDuplicateItem`).
    case duplicateItem
    
    /// Authentication failed (e.g. failed biometrics or passcode) (`errSecAuthFailed`).
    case authFailed
    
    /// The user canceled the authentication prompt (`errSecUserCanceled`).
    case userCancelled
    
    /// User interaction is required but not allowed (e.g. the device is locked) (`errSecInteractionNotAllowed`).
    case interactionNotAllowed
    
    /// The app is missing the required entitlement (e.g. an invalid `keychain-access-groups` value) (`errSecMissingEntitlement`).
    case missingEntitlement
    
    /// One or more parameters passed to the Keychain call were invalid (`errSecParam`).
    case invalidParameters
    
    /// Large or invalid data provided or retrieved (`errSecDataTooLarge`).
    case invalidData
    
    /// No keychain is available (e.g. before the first unlock after boot) (`errSecNotAvailable`).
    case notAvailable
    
    /// The stored data could not be decoded (`errSecDecode`).
    case decodeFailed
    
    /// Failed to allocate memory for the operation (`errSecAllocate`).
    case allocateFailed
    
    /// An I/O error occurred while accessing the keychain store (`errSecIO`).
    case ioError
    
    /// The function or operation is not implemented (`errSecUnimplemented`).
    case unimplemented
    
    /// The Keychain returned an unexpected `OSStatus` code.
    case unexpectedStatus(OSStatus)
    
    /// The attributes provided are incorrect or unsupported for the requested item class.
    case incorrectAttributesForClass
    
    /// Initializes a `KeychainError` from a Security framework `OSStatus` code.
    ///
    /// - Parameter status: The `OSStatus` value returned by a Keychain Security API call.
    public init(_ status: OSStatus) {
        switch status {
        case errSecItemNotFound:            self = .itemNotFound
        case errSecDuplicateItem:           self = .duplicateItem
        case errSecAuthFailed:              self = .authFailed
        case errSecUserCanceled:            self = .userCancelled
        case errSecInteractionNotAllowed:   self = .interactionNotAllowed
        case errSecMissingEntitlement:      self = .missingEntitlement
        case errSecParam:                   self = .invalidParameters
        case errSecNotAvailable:            self = .notAvailable
        case errSecDecode:                  self = .decodeFailed
        case errSecAllocate:                self = .allocateFailed
        case errSecIO:                      self = .ioError
        case errSecUnimplemented:           self = .unimplemented
        case errSecDataTooLarge:            self = .invalidData
        default:                            self = .unexpectedStatus(status)
        }
    }
}

// MARK: - LocalizedError & CaseIterable & Equatable

extension KeychainError: LocalizedError, Equatable, CaseIterable {
    /// A collection of all representative cases of `KeychainError`.
    ///
    /// For `.unexpectedStatus`, `allCases` contains a representative case with `errSecSuccess` (0).
    public static var allCases: [KeychainError] {
        [
            .itemNotFound,
            .duplicateItem,
            .authFailed,
            .userCancelled,
            .interactionNotAllowed,
            .missingEntitlement,
            .invalidParameters,
            .invalidData,
            .notAvailable,
            .decodeFailed,
            .allocateFailed,
            .ioError,
            .unimplemented,
            .unexpectedStatus(errSecSuccess),
            .incorrectAttributesForClass
        ]
    }
    
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return NSLocalizedString("The requested item was not found in the Keychain.", comment: "Keychain error description")
        case .duplicateItem:
            return NSLocalizedString("An item with this key already exists in the Keychain.", comment: "Keychain error description")
        case .authFailed:
            return NSLocalizedString("Authentication failed when attempting to access the Keychain.", comment: "Keychain error description")
        case .userCancelled:
            return NSLocalizedString("The user canceled the Keychain authentication prompt.", comment: "Keychain error description")
        case .interactionNotAllowed:
            return NSLocalizedString("Keychain access requires user interaction, which is currently prohibited.", comment: "Keychain error description")
        case .missingEntitlement:
            return NSLocalizedString("The application is missing a required Keychain entitlement.", comment: "Keychain error description")
        case .invalidParameters:
            return NSLocalizedString("Invalid parameters were supplied to the Keychain operation.", comment: "Keychain error description")
        case .invalidData:
            return NSLocalizedString("The data provided or retrieved from the Keychain is invalid or malformed.", comment: "Keychain error description")
        case .notAvailable:
            return NSLocalizedString("The Keychain service is currently unavailable.", comment: "Keychain error description")
        case .decodeFailed:
            return NSLocalizedString("Failed to decode the data retrieved from the Keychain.", comment: "Keychain error description")
        case .allocateFailed:
            return NSLocalizedString("Failed to allocate memory for the Keychain operation.", comment: "Keychain error description")
        case .ioError:
            return NSLocalizedString("An I/O error occurred while communicating with the Keychain.", comment: "Keychain error description")
        case .unimplemented:
            return NSLocalizedString("The requested Keychain functionality is not implemented on this system.", comment: "Keychain error description")
        case .unexpectedStatus(let status):
            return String(format: NSLocalizedString("Keychain operation failed with unexpected status code: %d.", comment: "Keychain error description"), status)
        case .incorrectAttributesForClass:
            return NSLocalizedString("The specified attributes are invalid for this Keychain item class.", comment: "Keychain error description")
        }
    }
    
    /// A localized message describing the reason for the failure.
    public var failureReason: String? {
        switch self {
        case .itemNotFound:
            return NSLocalizedString("No keychain item matching the specified key and access group could be located.", comment: "Keychain failure reason")
        case .duplicateItem:
            return NSLocalizedString("A keychain item with the same identifier already exists.", comment: "Keychain failure reason")
        case .authFailed:
            return NSLocalizedString("Passcode, Touch ID, or Face ID verification was unsuccessful.", comment: "Keychain failure reason")
        case .userCancelled:
            return NSLocalizedString("User dismissed the system biometric or passcode authentication prompt.", comment: "Keychain failure reason")
        case .interactionNotAllowed:
            return NSLocalizedString("The device may be locked or operating in a restricted background mode.", comment: "Keychain failure reason")
        case .missingEntitlement:
            return NSLocalizedString("Check your App ID entitlements for keychain-access-groups configuration.", comment: "Keychain failure reason")
        case .invalidParameters:
            return NSLocalizedString("One or more attributes in the Security framework query dictionary are out of range or invalid.", comment: "Keychain failure reason")
        case .invalidData:
            return NSLocalizedString("The keychain result data could not be cast or parsed correctly.", comment: "Keychain failure reason")
        case .notAvailable:
            return NSLocalizedString("Keychain storage is locked or not accessible prior to first device unlock.", comment: "Keychain failure reason")
        case .decodeFailed:
            return NSLocalizedString("JSON decoding failed for the payload retrieved from the keychain.", comment: "Keychain failure reason")
        case .allocateFailed:
            return NSLocalizedString("System memory allocation failed during keychain item processing.", comment: "Keychain failure reason")
        case .ioError:
            return NSLocalizedString("Disk write or security daemon communication error occurred.", comment: "Keychain failure reason")
        case .unimplemented:
            return NSLocalizedString("The system API is not supported on the current OS version or platform.", comment: "Keychain failure reason")
        case .unexpectedStatus(let status):
            return String(format: NSLocalizedString("The Security framework returned OSStatus error code %d.", comment: "Keychain failure reason"), status)
        case .incorrectAttributesForClass:
            return NSLocalizedString("The item class does not support raw value data insertion or extraction via SecItemAdd.", comment: "Keychain failure reason")
        }
    }
    
    /// A localized message describing how to recover from the failure.
    public var recoverySuggestion: String? {
        switch self {
        case .itemNotFound:
            return NSLocalizedString("Ensure the item has been saved before attempting to load or delete it.", comment: "Keychain recovery suggestion")
        case .duplicateItem:
            return NSLocalizedString("Set `updateIfExists: true` when saving to overwrite existing keychain values.", comment: "Keychain recovery suggestion")
        case .authFailed:
            return NSLocalizedString("Prompt the user to retry authentication with valid credentials.", comment: "Keychain recovery suggestion")
        case .userCancelled:
            return NSLocalizedString("Retry the operation after confirming user consent.", comment: "Keychain recovery suggestion")
        case .interactionNotAllowed:
            return NSLocalizedString("Unlock the device or postpone keychain access until the application enters the foreground.", comment: "Keychain recovery suggestion")
        case .missingEntitlement:
            return NSLocalizedString("Add the required Keychain Sharing entitlement in your Xcode project settings.", comment: "Keychain recovery suggestion")
        case .invalidParameters:
            return NSLocalizedString("Verify key name, item class, and access group parameter values.", comment: "Keychain recovery suggestion")
        case .invalidData:
            return NSLocalizedString("Verify that the item stored matches the expected type schema.", comment: "Keychain recovery suggestion")
        case .notAvailable:
            return NSLocalizedString("Wait until the device is unlocked before attempting to access the keychain.", comment: "Keychain recovery suggestion")
        case .decodeFailed:
            return NSLocalizedString("Ensure the data stored matches the `Codable` model type being loaded.", comment: "Keychain recovery suggestion")
        case .allocateFailed:
            return NSLocalizedString("Free system memory and retry the operation.", comment: "Keychain recovery suggestion")
        case .ioError:
            return NSLocalizedString("Check device disk space and retry.", comment: "Keychain recovery suggestion")
        case .unimplemented:
            return NSLocalizedString("Check system compatibility and API availability for target platform.", comment: "Keychain recovery suggestion")
        case .unexpectedStatus:
            return NSLocalizedString("Refer to Apple's Security Framework documentation for the specific OSStatus error code.", comment: "Keychain recovery suggestion")
        case .incorrectAttributesForClass:
            return NSLocalizedString("Use supported item classes (generic password or internet password) for raw data storage.", comment: "Keychain recovery suggestion")
        }
    }
}

