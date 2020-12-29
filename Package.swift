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
            url: "https://github.com/nixzhu/MonkeyKing/releases/download/2.0.2/MonkeyKing.xcframework.zip",
            checksum: "5e29ed06a90f454ab756fe78d0b53753cee65b14f0af969f673bc42184d018e8"
        ),
    ]
)
