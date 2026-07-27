# Security & Lock Screen Policies (`security-policies.md`)

Configure lock screen accessibility rules and biometric evaluation (Touch ID / Face ID) when storing secrets.

---

## 1. Device Lock Screen Accessibility (`KeychainAccessibility`)

| Value | Security Attribute (`kSecAttrAccessible`) | Behavior |
| :--- | :--- | :--- |
| `.whenUnlocked` *(Default)* | `kSecAttrAccessibleWhenUnlocked` | Data accessible only when device is unlocked. |
| `.afterFirstUnlock` | `kSecAttrAccessibleAfterFirstUnlock` | Accessible after first unlock following device reboot. |
| `.whenPasscodeSetThisDeviceOnly` | `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` | Accessible only if passcode is set; non-migratable. |
| `.whenUnlockedThisDeviceOnly` | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | Accessible when unlocked; non-migratable. |
| `.afterFirstUnlockThisDeviceOnly` | `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | Accessible after first unlock; non-migratable. |

```swift
try await Keychain.shared.saveString("bg_token", for: .refreshToken, accessibility: .afterFirstUnlock)
```

---

## 2. Biometric Protection (`KeychainAccessControl`)

| Value | `SecAccessControlCreateFlags` | Protection Guarantee |
| :--- | :--- | :--- |
| `.userPresence` | `.userPresence` | Requires Touch ID / Face ID or device passcode. |
| `.biometryAny` | `.biometryAny` | Requires biometric authentication with any enrolled biometric. |
| `.biometryCurrentSet` | `.biometryCurrentSet` | Requires current biometrics (invalidated if new fingerprints/faces added). |

```swift
import LocalAuthentication

// Save with Touch ID / Face ID protection
try await Keychain.shared.saveString("seed_phrase", for: .password, accessControl: .userPresence)

// Load with custom system prompt alert message
let seed = try await Keychain.shared.loadString(
    for: .password,
    authenticationPrompt: "Authenticate to view your master seed phrase"
)

// Reuse active LAContext session
let laContext = LAContext()
let authContext = KeychainAuthenticationContext(laContext)
let item = try await Keychain.shared.loadString(for: .password, authenticationContext: authContext)
```
