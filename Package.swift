// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainKit",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "KeychainKit", targets: ["KeychainKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(name: "KeychainKit")
    ]
)
