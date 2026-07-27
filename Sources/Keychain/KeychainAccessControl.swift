//
//  KeychainAccessControl.swift
//  Keychain
//
//  Created by Ben Seferidis on 27/7/26.
//

import Foundation
import Security
import LocalAuthentication

/// Specifies biometric and device passcode authentication flags for Keychain item access.
///
/// Use `KeychainAccessControl` to enforce Face ID, Touch ID, or device passcode verification
/// whenever an item is read from the Keychain.
public enum KeychainAccessControl: String, Sendable, CaseIterable {
    /// Requires user presence evaluation via biometric authentication (Touch ID / Face ID) or device passcode (`SecAccessControlCreateFlags.userPresence`).
    case userPresence
    
    /// Requires biometric authentication with any enrolled fingerprint or Face ID (`SecAccessControlCreateFlags.biometryAny`).
    case biometryAny
    
    /// Requires biometric authentication with the set of fingerprints or Face ID currently enrolled (`SecAccessControlCreateFlags.biometryCurrentSet`).
    ///
    /// Items created with `.biometryCurrentSet` are permanently invalidated if new biometric enrollments (fingerprints or faces) are added to the device.
    case biometryCurrentSet
    
    /// Returns the corresponding Security framework `SecAccessControlCreateFlags`.
    public var flags: SecAccessControlCreateFlags {
        switch self {
        case .userPresence:
            return .userPresence
        case .biometryAny:
            return .biometryAny
        case .biometryCurrentSet:
            return .biometryCurrentSet
        }
    }
    
    /// Creates a `SecAccessControl` object configured with the specified accessibility policy and biometric flags.
    ///
    /// - Parameter protection: The protection policy specifying when the item can be accessed. Defaults to `.whenUnlocked`.
    /// - Returns: An initialized `SecAccessControl` reference.
    /// - Throws: `KeychainError.invalidParameters` if `SecAccessControl` creation fails.
    public func createSecAccessControl(protection: KeychainAccessibility = .whenUnlocked) throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            protection.secAccessible,
            flags,
            &error
        ) else {
            throw KeychainError.invalidParameters
        }
        return accessControl
    }
}

/// A wrapper around `LAContext` for passing pre-authenticated LocalAuthentication contexts into Keychain operations.
public struct KeychainAuthenticationContext: @unchecked Sendable {
    /// The underlying `LAContext` instance.
    public let context: LAContext
    
    /// Initializes a new `KeychainAuthenticationContext` wrapping the given `LAContext`.
    ///
    /// - Parameter context: An `LAContext` instance.
    public init(_ context: LAContext) {
        self.context = context
    }
}

