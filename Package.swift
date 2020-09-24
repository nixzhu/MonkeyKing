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
            url: "https://github.com/nixzhu/MonkeyKing/releases/download/pre-1.17.0/MonkeyKing.xcframework.zip",
            checksum: "1b4fafe9b3c438c7fe9f3490a5b4194baad0cb70c20ee374e0fb86326ee0e283"
        )
    ]
)
