# Storage & Retrieval Operations (`crud-operations.md`)

The `Keychain` package provides API overloads for storing `Codable & Sendable` objects as well as raw binary `Data` and UTF-8 `String` payloads.

---

## 1. Codable Objects

```swift
import Keychain
import Foundation

struct UserSession: Codable, Sendable {
    let userId: String
    let token: String
}

let session = UserSession(userId: "user_123", token: "abc")

// Save
try await Keychain.shared.save(session, for: .authToken)

// Load
let loaded = try await Keychain.shared.load(for: .authToken, as: UserSession.self)

// Delete
try await Keychain.shared.delete(for: .authToken)
```

---

## 2. Raw String & Data Overloads (Zero JSON Overhead)

```swift
// Save Raw String
try await Keychain.shared.saveString("secret_token_123", for: .authToken)

// Load Raw String
let token = try await Keychain.shared.loadString(for: .authToken)

// Save Raw Data
let data = Data([0x01, 0x02, 0x03])
try await Keychain.shared.saveData(data, for: .userCredentials)

// Load Raw Data
let loadedData = try await Keychain.shared.loadData(for: .userCredentials)
```

---

## 3. Key Existence & Bulk Wipe

```swift
// Test if a key exists without decoding payload
if try await Keychain.shared.exists(for: .authToken) {
    print("Session exists")
}

// Bulk delete all managed entries (e.g. on user logout)
try await Keychain.shared.deleteAll()
```
