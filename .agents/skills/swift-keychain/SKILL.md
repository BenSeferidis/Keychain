---
name: swift-keychain
description: Comprehensive expert skill for storing, retrieving, and managing items in Apple's Keychain using the thread-safe, actor-isolated Swift 6 Keychain package (BenSeferidis/Keychain). Covers Codable payloads, raw Data/String overloads, device accessibility policies (KeychainAccessibility), biometric protection (KeychainAccessControl), custom operation prompts, LAContext session reuse, iCloud sync (isSynchronizable), service namespaces, key existence checks, bulk wipe, and dependency injection patterns. Use whenever developing, refactoring, reviewing, or integrating Keychain operations in Swift.
---

# Swift Keychain Skill (`swift-keychain`)

Expert guidance for storing, retrieving, and managing Keychain secrets using the actor-isolated **BenSeferidis/Keychain** package.

---

## 🎯 Quick Decision Triage

Find your task below to jump directly to the relevant reference guide:

| Task / Scenario | Reference File |
| :--- | :--- |
| **Actor Isolation & Concurrency Setup** | [references/architecture.md](file://references/architecture.md) |
| **Storing Codable Structs, Raw Data & Strings** | [references/crud-operations.md](file://references/crud-operations.md) |
| **Biometric Verification (Touch ID / Face ID) & Lock Policies** | [references/security-policies.md](file://references/security-policies.md) |
| **iCloud Sync & Service Namespaces** | [references/icloud-sync.md](file://references/icloud-sync.md) |
| **Error Handling & OSStatus Mapping** | [references/error-handling.md](file://references/error-handling.md) |
| **Unit Testing & Dependency Injection** | [references/testing.md](file://references/testing.md) |

---

## 📦 Package Installation Quickstart

Add `Keychain` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/BenSeferidis/Keychain.git", from: "1.0.0")
]
```

Or in Xcode: **File -> Add Package Dependencies...** -> `https://github.com/BenSeferidis/Keychain.git`

---

## 📁 Reference Documentation Structure

- [_index.md](file://references/_index.md): Index of all reference guides.
- [architecture.md](file://references/architecture.md): Actor isolation, global actor `@Keychain`, and `KeychainProtocol`.
- [crud-operations.md](file://references/crud-operations.md): Saving, loading, deleting `Codable`, raw `Data`, and `String` payloads.
- [security-policies.md](file://references/security-policies.md): Lock screen policies (`KeychainAccessibility`) & Biometrics (`KeychainAccessControl`).
- [icloud-sync.md](file://references/icloud-sync.md): Synchronizable items (`isSynchronizable`) & Service namespaces (`service`).
- [error-handling.md](file://references/error-handling.md): `KeychainError` localization, failure reasons, and recovery suggestions.
- [testing.md](file://references/testing.md): Dependency injection with `any KeychainProtocol` and Swift Testing patterns.
