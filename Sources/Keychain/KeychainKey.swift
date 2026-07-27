//
//  KeychainKey.swift
//  Keychain
//
//  Created by Ben Seferidis on 27/7/26.
//

import Security

/// Represents unique key identifiers for items stored in the Keychain.
///
/// `KeychainKey` maps each key case to a raw string identifier used in Keychain search queries
/// and associates it with a specific `ItemClass` type.
public enum KeychainKey: String, Sendable, CaseIterable {
    /// A general password item key.
    case password
    
    /// An authentication token key.
    case authToken
    
    /// A refresh token key.
    case refreshToken
    
    /// A user credentials item key.
    case userCredentials
    
    /// Returns the Keychain `ItemClass` associated with this key.
    public var itemClass: ItemClass {
        switch self {
        case .password, .authToken, .refreshToken, .userCredentials:
            return .password
        }
    }
}

public extension KeychainKey {
    
    /// Specifies the Security framework item class for a Keychain entry.
    enum ItemClass: Sendable {
        /// Generic password item class (`kSecClassGenericPassword`).
        case generic
        
        /// Internet password item class (`kSecClassInternetPassword`).
        case password
        
        /// Certificate item class (`kSecClassCertificate`) with an optional export passphrase.
        case certificate(exportPassphrase: String? = nil)
        
        /// Cryptographic key item class (`kSecClassKey`).
        case cryptography
        
        /// Identity item class (`kSecClassIdentity`).
        case identity
        
        /// The Security framework `CFString` representation for the item class.
        public var rawValue: CFString {
            switch self {
            case .generic: return kSecClassGenericPassword
            case .password: return kSecClassInternetPassword
            case .certificate: return kSecClassCertificate
            case .cryptography: return kSecClassKey
            case .identity: return kSecClassIdentity
            }
        }
        
        /// Indicates whether the item class supports password-style attributes (`kSecAttrAccount` and `kSecValueData`).
        var isPasswordClass: Bool {
            switch self {
            case .generic, .password:
                return true
            case .certificate, .cryptography, .identity:
                return false
            }
        }
    }
}
