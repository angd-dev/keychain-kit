// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainKit",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "KeychainKit", targets: ["KeychainKit"]),
    ],
    targets: [
        .target(name: "KeychainKit")
    ]
)
