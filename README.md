# Keychain

A lightweight, modern, actor-isolated Swift library for secure, type-safe Keychain operations on iOS and macOS. Built for Swift 6+ with strict concurrency safety (`Sendable`, `Actor`, `@globalActor`).

---

## Features

- 🔒 **Actor Isolated & Thread-Safe**: Isolated to an `actor` context to prevent data races in Swift Concurrency.
- 🌐 **Global Actor Support**: Annotate functions or types with `@Keychain` for compile-time actor isolation.
- 👤 **Biometric Protection**: Require Face ID, Touch ID, or device passcode verification (`KeychainAccessControl`) on item access.
- ☁️ **iCloud Keychain Synchronization**: Seamlessly sync credentials across a user's Apple devices (`isSynchronizable: true`).
- 🏷️ **Service Partitioning**: Isolate entries into custom service namespaces (`service: "com.myapp.auth"`).
- 📦 **Codable & Sendable Integration**: Seamlessly save and load any `Codable & Sendable` struct or enum.
- ⚡ **Raw Data & String Overloads**: Fast storage for raw binary `Data` and UTF-8 `String` tokens without JSON overhead.
- 🛡️ **Keychain Accessibility Policies**: Configure device lock security attributes (`.whenUnlocked`, `.afterFirstUnlock`, `.whenUnlockedThisDeviceOnly`, etc.).
- 🔍 **Existence Checking & Bulk Wipe**: Easily test key existence (`exists(for:)`) and clear application secrets on logout (`deleteAll()`).
- ⚙️ **Custom Encoders & Decoders**: Support for custom `JSONEncoder` and `JSONDecoder` strategies (e.g. ISO8601 dates, snake_case keys).
- 💬 **Rich Error Localization**: `KeychainError` conforms to `LocalizedError`, `CaseIterable`, `Equatable`, and `Sendable`, offering user descriptions, failure reasons, and recovery suggestions.

---

## Installation

Add `Keychain` to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/BenSeferidis/Keychain.git", from: "1.0.0")
]
```

Or add it directly via Xcode: **File -> Add Package Dependencies...**

---

## Usage Examples

### 1. Basic Saving, Loading & Deleting (`Codable`)

```swift
import Keychain
import Foundation

struct UserSession: Codable, Sendable, Equatable {
    let userId: String
    let token: String
    let createdAt: Date
}

// 1. Save an item
let session = UserSession(userId: "user_123", token: "secret_abc", createdAt: Date())
try await Keychain.shared.save(session, for: .authToken)

// 2. Load an item
let loadedSession = try await Keychain.shared.load(for: .authToken, as: UserSession.self)
print("Loaded token for user:", loadedSession.userId)

// 3. Delete an item
try await Keychain.shared.delete(for: .authToken)
```

---

### 2. Raw String & Data Storage (Bypassing JSON Overhead)

For API tokens, raw encryption keys, or UTF-8 strings, use `saveString` or `saveData` directly:

```swift
// Save raw string
try await Keychain.shared.saveString("secret_api_token_xyz", for: .authToken)

// Load raw string
let token = try await Keychain.shared.loadString(for: .authToken)

// Save raw binary data
let rawBytes = Data([0x01, 0x02, 0x03, 0xFF])
try await Keychain.shared.saveData(rawBytes, for: .userCredentials)

// Load raw binary data
let loadedBytes = try await Keychain.shared.loadData(for: .userCredentials)
```

---

### 3. Keychain Accessibility Policies (`KeychainAccessibility`)

Specify when Keychain entries are accessible relative to device unlock state:

```swift
// Only accessible when device is unlocked
try await Keychain.shared.save(session, for: .authToken, accessibility: .whenUnlocked)

// Accessible after first device unlock following reboot
try await Keychain.shared.saveString("background_token", for: .refreshToken, accessibility: .afterFirstUnlock)

// Accessible only on this device (will not migrate via iCloud/device backup)
try await Keychain.shared.saveData(rawBytes, for: .userCredentials, accessibility: .whenUnlockedThisDeviceOnly)
```

---

### 4. Biometric Protection, Custom Prompts & iCloud Sync

```swift
// Enforce Face ID / Touch ID or Passcode prompt on access
try await Keychain.shared.saveString(
    "super_secret_seed_phrase",
    for: .password,
    accessControl: .userPresence
)

// Load with custom biometric prompt string
let seed = try await Keychain.shared.loadString(
    for: .password,
    authenticationPrompt: "Authenticate to view your master seed phrase"
)

// Reuse an existing pre-authenticated LocalAuthentication context
let laContext = LAContext()
let authContext = KeychainAuthenticationContext(laContext)
let item = try await Keychain.shared.loadString(
    for: .password,
    authenticationContext: authContext
)

// Sync credentials across user's Apple devices via iCloud Keychain
try await Keychain.shared.saveString(
    "user_jwt_token",
    for: .authToken,
    isSynchronizable: true
)
```

---

### 5. Key Existence Check & Bulk Wipe

```swift
// Check if a key exists
if try await Keychain.shared.exists(for: .authToken) {
    print("User is logged in")
}

// Bulk delete all managed Keychain items (e.g. on user logout)
try await Keychain.shared.deleteAll()
```

---

### 5. Updating vs Preventing Duplicates

By default, `save` will overwrite an existing item if `updateIfExists` is `true`. Set `updateIfExists` to `false` if you want an error thrown when a key already exists:

```swift
do {
    try await Keychain.shared.save(session, for: .authToken, updateIfExists: false)
} catch KeychainError.duplicateItem {
    print("Item already exists in the Keychain!")
}
```

---

### 6. Custom Encoders & Decoders

Pass custom `JSONEncoder` or `JSONDecoder` instances to configure key formatting, date formatting, or data strategies:

```swift
let customEncoder = JSONEncoder()
customEncoder.dateEncodingStrategy = .iso8601
customEncoder.keyEncodingStrategy = .convertToSnakeCase

let customDecoder = JSONDecoder()
customDecoder.dateDecodingStrategy = .iso8601
customDecoder.keyDecodingStrategy = .convertFromSnakeCase

// Save with custom encoder
try await Keychain.shared.save(session, for: .userCredentials, encoder: customEncoder)

// Load with custom decoder
let loaded = try await Keychain.shared.load(for: .userCredentials, as: UserSession.self, decoder: customDecoder)
```

---

### 7. Global Actor Isolation (`@Keychain`)

You can annotate methods or entire classes with `@Keychain` to isolate execution to the `Keychain` global actor context:

```swift
@Keychain
final class AuthManager {
    func persistSession(_ session: UserSession) async throws {
        // Automatically isolated to the Keychain global actor
        try await Keychain.shared.save(session, for: .authToken)
    }
}
```

---

### 8. Dependency Injection (`KeychainProtocol`)

Inject `KeychainProtocol` into your service layers to facilitate testing and mock implementations:

```swift
final class TokenRepository {
    private let keychain: any KeychainProtocol

    init(keychain: any KeychainProtocol = Keychain.shared) {
        self.keychain = keychain
    }

    func saveToken(_ token: String) async throws {
        try await keychain.saveString(token, for: .authToken, accessGroup: nil, accessibility: .whenUnlocked, updateIfExists: true)
    }
}
```

---

### 9. Error Handling

`KeychainError` maps Apple's `OSStatus` codes into type-safe error cases with localized human-readable messages:

```swift
do {
    let session = try await Keychain.shared.load(for: .authToken, as: UserSession.self)
} catch let error as KeychainError {
    print("Error Description:", error.errorDescription ?? "")
    print("Failure Reason:", error.failureReason ?? "")
    print("Recovery Suggestion:", error.recoverySuggestion ?? "")
} catch {
    print("Unexpected error:", error)
}
```

---

## License

MIT License.
