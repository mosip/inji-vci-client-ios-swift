// swift-tools-version: 5.7.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VCIClient",
    platforms: [
        .macOS(.v11),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "VCIClient",
            targets: ["VCIClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/valpackett/SwiftCBOR", .upToNextMajor(from: "0.5.0"))
    ],
    targets: [
        .target(
            name: "VCIClient",
            dependencies: ["SwiftCBOR"]
        ),
        .testTarget(
            name: "VCIClientTests",
            dependencies: ["VCIClient","SwiftCBOR"]),
    ]
)
