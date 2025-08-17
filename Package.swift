// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(name: "KeychainKit", targets: ["KeychainKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/angd-dev/localizable.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(name: "KeychainKit", dependencies: [
            .product(name: "Localizable", package: "localizable")
        ])
    ]
)
