// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "kuyu-core",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "KuyuCore",
            targets: ["KuyuCore"]
        ),
        .library(
            name: "KuyuRuntime",
            targets: ["KuyuRuntime"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.9.1"),
        .package(url: "https://github.com/apple/swift-configuration", from: "1.0.2"),
    ],
    targets: [
        .target(
            name: "KuyuCore",
            dependencies: []
        ),
        .target(
            name: "KuyuRuntime",
            dependencies: [
                "KuyuCore",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Configuration", package: "swift-configuration"),
            ]
        ),
        .testTarget(
            name: "KuyuCoreTests",
            dependencies: ["KuyuCore"]
        ),
    ]
)
