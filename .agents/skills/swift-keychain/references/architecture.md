# Actor Isolation & Architecture (`architecture.md`)

`Keychain` guarantees compile-time thread safety and data-race prevention under Swift 6 strict concurrency checks (`swiftLanguageModes: [.v6]`).

---

## Key Principles

1. **Actor Isolation**: All Keychain operations (`save`, `load`, `delete`, `saveData`, `loadData`, etc.) run inside an actor executor.
2. **Global Actor `@Keychain`**: You can annotate your own classes or functions with `@Keychain` to run them directly within the Keychain global actor execution context.
3. **Protocol Abstraction**: `KeychainProtocol` requires `Actor` conformance (`public protocol KeychainProtocol: Actor`), guaranteeing that any injected mock implementation is also an actor.

---

## Code Examples

### Global Actor Singleton Access

```swift
import Keychain

// Call actor methods asynchronously
try await Keychain.shared.saveString("secret_token", for: .authToken)
let token = try await Keychain.shared.loadString(for: .authToken)
```

### `@Keychain` Global Actor Annotation

```swift
import Keychain

@Keychain
final class AuthManager {
    func refreshSession(token: String) async throws {
        // Isolated to the Keychain global actor context
        try await Keychain.shared.saveString(token, for: .authToken)
    }
}
```
