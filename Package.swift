// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MonkeyKing",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(
            name: "MonkeyKingStatic",
            type: .static,
            targets: ["MonkeyKingSource"]
        ),
        .library(
            name: "MonkeyKingDynamic",
            type: .dynamic,
            targets: ["MonkeyKingSource"]
        ),
        .library(
            name: "MonkeyKingXCFramework",
            targets: ["MonkeyKing"]
        ),
    ],
    targets: [
        .target(
            name: "MonkeyKingSource",
            path: "Sources/MonkeyKing"
        ),
        .testTarget(
            name: "MonkeyKingTests",
            dependencies: ["MonkeyKing"],
            path: "Tests/MonkeyKingTests"
        ),
        .binaryTarget(
            name: "MonkeyKing",
            url: "https://github.com/nixzhu/MonkeyKing/releases/download/2.0.0/MonkeyKing.xcframework.zip",
            checksum: "d9a1eff556a38b2a435fb4eb8bfc4b0636d03eb2538e2fbdb36880d1d05499d7"
        )
    ]
)
