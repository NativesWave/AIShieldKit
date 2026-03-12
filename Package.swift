// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AIShieldKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "AIShieldKit",
            targets: ["AIShieldKit"]
        )
    ],
    targets: [
        .target(
            name: "AIShieldKit"
        ),
        .testTarget(
            name: "AIShieldKitTests",
            dependencies: ["AIShieldKit"]
        )
    ]
)
