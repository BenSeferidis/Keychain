# Unit Testing & Dependency Injection (`testing.md`)

Use `KeychainProtocol` to inject mock instances or isolated Keychain implementations for reliable unit tests.

---

## 1. Dependency Injection Setup

```swift
import Keychain

final class TokenRepository {
    private let keychain: any KeychainProtocol

    init(keychain: any KeychainProtocol = Keychain.shared) {
        self.keychain = keychain
    }

    func saveAuthToken(_ token: String) async throws {
        try await keychain.saveString(
            token,
            for: .authToken,
            accessGroup: nil,
            service: nil,
            accessibility: .whenUnlocked,
            accessControl: nil,
            isSynchronizable: false,
            updateIfExists: true
        )
    }
}
```

---

## 2. Testing Swift Packages with Swift Testing (`@Suite`)

Integration tests accessing the shared macOS Keychain should use `.serialized` suite execution to prevent parallel access collisions:

```swift
import Testing
import Keychain

@Suite("Keychain Repository Integration Tests", .serialized)
struct KeychainRepositoryTests {

    @Test("Save and Load Auth Token")
    func testTokenFlow() async throws {
        let repo = TokenRepository(keychain: Keychain.shared)
        try await repo.saveAuthToken("test_secret_123")

        let exists = try await Keychain.shared.exists(for: .authToken)
        #expect(exists)

        try await Keychain.shared.delete(for: .authToken)
    }
}
```
