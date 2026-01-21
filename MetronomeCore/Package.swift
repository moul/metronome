// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetronomeCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "MetronomeCore",
            targets: ["MetronomeCore"]),
    ],
    targets: [
        .target(
            name: "MetronomeCore"),
        .testTarget(
            name: "MetronomeCoreTests",
            dependencies: ["MetronomeCore"]),
    ]
)
