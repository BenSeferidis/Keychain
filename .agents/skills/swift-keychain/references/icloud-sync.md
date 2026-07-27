# iCloud Sync & Service Namespaces (`icloud-sync.md`)

---

## 1. iCloud Keychain Synchronization (`isSynchronizable`)

By default, items stored in the Keychain are local to the current device (`isSynchronizable: false`). Set `isSynchronizable: true` to allow credentials to sync across a user's logged-in Apple devices via iCloud Keychain.

```swift
// Save synchronizable credential
try await Keychain.shared.saveString("user_jwt", for: .authToken, isSynchronizable: true)

// Load synchronizable credential
let jwt = try await Keychain.shared.loadString(for: .authToken, isSynchronizable: true)

// Check existence of synchronizable credential
let exists = try await Keychain.shared.exists(for: .authToken, isSynchronizable: true)
```

---

## 2. Service Namespace Partitioning (`service`)

Use the `service: String?` parameter (`kSecAttrService`) to partition generic passwords into distinct service domain namespaces within the same application:

```swift
// Save under Auth domain
try await Keychain.shared.saveString("auth_token_123", for: .authToken, service: "com.myapp.auth")

// Save under Database domain
try await Keychain.shared.saveString("db_secret_456", for: .authToken, service: "com.myapp.database")

// Load specifically from Auth domain
let authToken = try await Keychain.shared.loadString(for: .authToken, service: "com.myapp.auth")
```
