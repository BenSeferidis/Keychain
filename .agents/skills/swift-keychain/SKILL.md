---
name: swift-keychain
description: Comprehensive expert skill for storing, retrieving, and managing items in Apple's Keychain using the thread-safe, actor-isolated Swift 6 Keychain package (BenSeferidis/Keychain). Covers Codable payloads, raw Data/String overloads, device accessibility policies (KeychainAccessibility), biometric protection (KeychainAccessControl), custom operation prompts, LAContext session reuse, iCloud sync (isSynchronizable), service namespaces, key existence checks, bulk wipe, and dependency injection patterns. Use whenever developing, refactoring, reviewing, or integrating Keychain operations in Swift.
---

# Swift Keychain Skill (`swift-keychain`)

This skill provides full architecture patterns, code snippets, and security guidelines for implementing, refactoring, and testing secure Keychain storage using the thread-safe **BenSeferidis/Keychain** package.

---

## 📦 Package Setup

Add `Keychain` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/BenSeferidis/Keychain.git", from: "1.0.0")
]
```

Or via Xcode: **File -> Add Package Dependencies...** -> `https://github.com/BenSeferidis/Keychain.git`

---

## 🔒 Concurrency Architecture

- **Global Actor Singleton**: `Keychain.shared` isolates operations to an actor context, eliminating data races under Swift 6 strict concurrency checks (`swiftLanguageModes: [.v6]`).
- **Global Actor Attribute**: Use `@Keychain` to isolate custom manager classes or functions directly to the `Keychain` actor context.
- **Protocol Abstraction**: Inject `any KeychainProtocol` into repositories and ViewModels for clean mock testing.

---

## 🚀 Common Usage Patterns

### 1. Codable Struct & Enum Storage

```swift
import Keychain
import Foundation

struct UserSession: Codable, Sendable, Equatable {
    let userId: String
    let token: String
    let createdAt: Date
}

// Save Codable item
let session = UserSession(userId: "user_123", token: "secret_token", createdAt: Date())
try await Keychain.shared.save(session, for: .authToken)

// Load Codable item
let loadedSession = try await Keychain.shared.load(for: .authToken, as: UserSession.self)

// Delete item
try await Keychain.shared.delete(for: .authToken)
```

---

### 2. Raw String & Data Overloads (Zero Serialization Overhead)

For API tokens, raw encryption keys, or UTF-8 strings, bypass JSON serialization:

```swift
// Raw String
try await Keychain.shared.saveString("secret_api_key_xyz", for: .authToken)
let apiKey = try await Keychain.shared.loadString(for: .authToken)

// Raw Data
let rawBytes = Data([0x01, 0x02, 0x03, 0xFF])
try await Keychain.shared.saveData(rawBytes, for: .userCredentials)
let loadedBytes = try await Keychain.shared.loadData(for: .userCredentials)
```

---

### 3. Biometric Protection (Touch ID / Face ID) & Custom Alerts

Require biometric verification on read, set custom system alert messages, or reuse existing `LAContext` sessions:

```swift
import LocalAuthentication

// Enforce Touch ID / Face ID prompt on access
try await Keychain.shared.saveString(
    "master_seed_phrase",
    for: .password,
    accessControl: .userPresence
)

// Read with custom biometric alert title
let seed = try await Keychain.shared.loadString(
    for: .password,
    authenticationPrompt: "Authenticate to view your master seed phrase"
)

// Reuse an active pre-authenticated LAContext session
let laContext = LAContext()
let authContext = KeychainAuthenticationContext(laContext)
let item = try await Keychain.shared.loadString(
    for: .password,
    authenticationContext: authContext
)
```

---

### 4. Lock Screen Accessibility Policies (`KeychainAccessibility`)

Control when entries can be read relative to device unlock state:

```swift
// Accessible only when device is unlocked (Default)
try await Keychain.shared.save(session, for: .authToken, accessibility: .whenUnlocked)

// Accessible after first unlock following reboot (Good for background tasks)
try await Keychain.shared.saveString("bg_token", for: .refreshToken, accessibility: .afterFirstUnlock)

// Bound strictly to current device (Does not migrate via backups)
try await Keychain.shared.saveData(rawBytes, for: .userCredentials, accessibility: .whenUnlockedThisDeviceOnly)
```

---

### 5. iCloud Keychain Synchronization (`isSynchronizable`)

Sync credentials seamlessly across user's Apple devices via iCloud Keychain:

```swift
// Sync item across user's logged-in Apple devices
try await Keychain.shared.saveString(
    "user_jwt_token",
    for: .authToken,
    isSynchronizable: true
)

// Load synchronized item
let jwt = try await Keychain.shared.loadString(for: .authToken, isSynchronizable: true)
```

---

### 6. Service Namespace Partitioning (`service`)

Partition generic passwords by service domain:

```swift
// Isolate token under auth service namespace
try await Keychain.shared.saveString("token123", for: .authToken, service: "com.myapp.auth")

// Separate token under db service namespace
try await Keychain.shared.saveString("db_pass", for: .authToken, service: "com.myapp.database")
```

---

### 7. Existence Check & Bulk Wipe on Logout

```swift
// Check key existence
if try await Keychain.shared.exists(for: .authToken) {
    print("User is authenticated")
}

// Bulk wipe all application secrets on user log-out
try await Keychain.shared.deleteAll()
```

---

### 8. Dependency Injection & Unit Testing Pattern

```swift
final class AuthRepository {
    private let keychain: any KeychainProtocol

    init(keychain: any KeychainProtocol = Keychain.shared) {
        self.keychain = keychain
    }

    func login(session: UserSession) async throws {
        try await keychain.save(session, for: .authToken, accessGroup: nil, service: nil, accessibility: .whenUnlocked, accessControl: nil, isSynchronizable: false, updateIfExists: true, encoder: JSONEncoder())
    }
}
```

---

## 🛡️ Error Handling Reference

`KeychainError` conforms to `LocalizedError`, `CaseIterable`, `Equatable`, and `Sendable`:

| Error Case | `OSStatus` Code | Trigger Scenario |
| :--- | :--- | :--- |
| `.duplicateItem` | `errSecDuplicateItem` (-25299) | `updateIfExists` is `false` and item already exists. |
| `.itemNotFound` | `errSecItemNotFound` (-25300) | Item matching key, service, or access group does not exist. |
| `.unhandledStatus` | Varying | Unmapped Security framework error code. |
| `.decodeFailed` | N/A | JSON payload mismatch or UTF-8 decoding failure. |
| `.invalidData` | N/A | Data conversion or SecCertificate/SecKey type extraction failed. |
| `.invalidParameters` | N/A | SecAccessControl creation failed due to invalid options. |

```swift
do {
    let session = try await Keychain.shared.load(for: .authToken, as: UserSession.self)
} catch let error as KeychainError {
    print(error.errorDescription ?? "Keychain error occurred")
    print(error.failureReason ?? "")
    print(error.recoverySuggestion ?? "")
}
```
