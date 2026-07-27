# Error Handling & OSStatus Mapping (`error-handling.md`)

`KeychainError` bridges Apple's low-level Security framework `OSStatus` error codes into type-safe Swift error cases conforming to `LocalizedError`, `CaseIterable`, `Equatable`, and `Sendable`.

---

## Error Case Mapping

| Case | `OSStatus` | Description | Recovery Suggestion |
| :--- | :--- | :--- | :--- |
| `.duplicateItem` | `errSecDuplicateItem` (-25299) | Item already exists. | Set `updateIfExists: true` or delete existing item. |
| `.itemNotFound` | `errSecItemNotFound` (-25300) | Item not found in Keychain. | Verify key, service, access group, or sync parameters. |
| `.unhandledStatus(OSStatus)` | Varying | Unmapped Security error. | Inspect underlying `OSStatus` code. |
| `.decodeFailed` | N/A | Payload decoding failed. | Verify JSON model structure or string UTF-8 encoding. |
| `.invalidData` | N/A | Data conversion failed. | Ensure input payload is non-empty. |
| `.invalidParameters` | N/A | SecAccessControl failed. | Verify accessibility and access control flags. |

---

## Catching & Handling Errors

```swift
do {
    let token = try await Keychain.shared.loadString(for: .authToken)
} catch let error as KeychainError {
    switch error {
    case .itemNotFound:
        print("User needs to log in.")
    case .duplicateItem:
        print("Item already exists.")
    default:
        print("Error Description:", error.errorDescription ?? "")
        print("Failure Reason:", error.failureReason ?? "")
        print("Recovery Suggestion:", error.recoverySuggestion ?? "")
    }
}
```
