# KeychainKit

KeychainKit is a type-safe, easy-to-use wrapper around Apple’s Keychain service that supports storing, retrieving, and deleting data with optional local authentication.

## Overview

This library enables working with Keychain without losing control over security settings while simplifying type-safe access to data types like `Data`, `String`, `UUID`, and any `Codable` types.

It supports optional authentication via `LAContext`, allowing integration with Face ID, Touch ID, or device passcode.

KeychainKit does not hide the complexity of Keychain operations but provides a clean API and convenient error handling via a custom `KeychainError` type.

## Requirements

- **Swift**: 5.10+
- **Platforms**: macOS 10.15+, iOS 13.0+

## Installation

To add KeychainKit to your project, use Swift Package Manager (SPM).

### Adding to an Xcode Project

1. Open your project in Xcode.
2. Navigate to the `File` menu and select `Add Package Dependencies`.
3. Enter the repository URL: `https://github.com/angd-dev/keychain-kit.git`
4. Choose the version to install (e.g., `2.0.0`).
5. Add the library to your target module.

### Adding to Package.swift

If you are using Swift Package Manager with a `Package.swift` file, add the dependency like this:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/angd-dev/keychain-kit.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: [
                .product(name: "KeychainKit", package: "keychain-kit")
            ]
        )
    ]
)
```

## Additional Resources

For more information and usage examples, see the [documentation](https://docs.angd.dev/?package=keychain-kit&version=2.0.0).

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
