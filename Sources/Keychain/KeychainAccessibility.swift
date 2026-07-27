//
//  KeychainAccessibility.swift
//  Keychain
//
//  Created by Ben Seferidis on 27/7/26.
//

import Foundation
import Security

/// Defines Keychain item accessibility policies specifying when stored items can be read.
///
/// Accessibility attributes dictate whether data is accessible only when the device is unlocked,
/// after the first unlock following a boot, or restricted to the creating device.
public enum KeychainAccessibility: String, Sendable, CaseIterable {
    /// The item data can be accessed only while the device is unlocked by the user (`kSecAttrAccessibleWhenUnlocked`).
    case whenUnlocked
    
    /// The item data can be accessed after the first device unlock following a reboot (`kSecAttrAccessibleAfterFirstUnlock`).
    case afterFirstUnlock
    
    /// The item data can be accessed only while the device is unlocked, and requires a device passcode to be set (`kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`).
    case whenPasscodeSetThisDeviceOnly
    
    /// The item data can be accessed only while the device is unlocked, and will not migrate to a new device (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
    case whenUnlockedThisDeviceOnly
    
    /// The item data can be accessed after the first unlock, and will not migrate to a new device (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
    case afterFirstUnlockThisDeviceOnly
    
    /// The Security framework `CFString` representation for the accessibility attribute.
    public var secAccessible: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}

