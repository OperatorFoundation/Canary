// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(macOS)
let package = Package(
    name: "Canary",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Datable", from: "3.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Canary",
            dependencies: ["Datable", "ZIPFoundation"]),
        .testTarget(
            name: "CanaryTests",
            dependencies: ["Canary"]),
    ]
)
#else
let package = Package(
    name: "Canary",
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Datable", from: "1.1.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Canary",
            dependencies: ["Datable", "ZIPFoundation"]),
        .testTarget(
            name: "CanaryTests",
            dependencies: ["Canary"]),
    ]
)
#endif
