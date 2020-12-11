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
            url: "https://github.com/nixzhu/MonkeyKing/releases/download/2.0.1/MonkeyKing.xcframework.zip",
            checksum: "b3fdd9c97ce4a0acfe0cf09226f6aa1e866b0eef41828de971bbcc1ac42c21d4"
        )
    ]
)
