// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(macOS)
let package = Package(
    name: "Canary",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "Canary", targets: ["Canary"]),
        .executable(name: "BuildForLinux", targets:["BuildForLinux"]),
        .executable(name: "PackageCanary", targets:["PackageCanary"])
    ],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Datable",
                 from: "3.0.3"),
        .package(url: "https://github.com/apple/swift-argument-parser.git",
                 from: "0.3.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git",
                 from: "0.9.11"),
        .package(url: "https://github.com/OperatorFoundation/AdversaryLabClientSwift",
                 from: "0.1.7"),
        .package(url: "https://github.com/OperatorFoundation/Gardener.git",
                 from: "0.0.12")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Canary",
            dependencies: ["Datable",
                           "ZIPFoundation",
                           "Gardener",
                           .product(name: "ArgumentParser",
                                    package: "swift-argument-parser"),
                           .product(name: "AdversaryLabClientCore",
                                    package: "AdversaryLabClientSwift")
            ]),
        .target(name: "BuildForLinux",
                dependencies: ["Gardener",
                               .product(name: "ArgumentParser",
                                        package: "swift-argument-parser")]),
        .target(name: "PackageCanary",
                dependencies: ["Gardener"]),
        .testTarget(
            name: "CanaryTests",
            dependencies: ["Canary"]),
    ],
    swiftLanguageVersions: [.v5]
)
#else
let package = Package(
    name: "Canary",
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Datable", from: "3.0.3"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.1"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11"),
        .package(url: "https://github.com/OperatorFoundation/AdversaryLabClientSwift", from: "0.1.7"),
        .package(url: "https://github.com/OperatorFoundation/Gardener.git", from: "0.0.12")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Canary",
            dependencies: ["Datable",
                           "ZIPFoundation",
                           "Gardener",
                           .product(name: "ArgumentParser",
                                    package: "swift-argument-parser"),
                           .product(name: "AdversaryLabClientCore",
                                    package: "AdversaryLabClientSwift")]),
        .target(name: "PackageCanary",
                dependencies: ["Gardener"]),
        .testTarget(
            name: "CanaryTests",
            dependencies: ["Canary"]),
    ],
    swiftLanguageVersions: [.v5]
)
#endif
