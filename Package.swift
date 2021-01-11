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
            url: "https://github.com/nixzhu/MonkeyKing/releases/download/2.1.0/MonkeyKing.xcframework.zip",
            checksum: "80fb1624d14be17687867c6046abc62e0b92cd183882acf036158dc3b9570013"
        ),
    ]
)
