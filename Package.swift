// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(macOS)
let package = Package(
    name: "Canary",
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Datable", from: "1.1.1"),
        
        .package(url: "https://github.com/OperatorFoundation/rethink-swift", from: "1.1.0")
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Canary",
            dependencies: ["Datable", "Rethink"]),
        .testTarget(
            name: "CanaryTests",
            dependencies: ["Canary"]),
    ]
)
#else
let package = Package(
    name: "Canary",
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Datable", from: "1.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Canary",
            dependencies: ["Datable"]),
        .testTarget(
            name: "CanaryTests",
            dependencies: ["Canary"]),
    ]
)
#endif
