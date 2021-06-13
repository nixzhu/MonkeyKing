// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MonkeyKing",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "MonkeyKing",
            targets: ["MonkeyKing"]
        ),
        .library(
            name: "MonkeyKingBinary",
            targets: ["MonkeyKingBinary"]
        )
    ],
    targets: [
        .target(name: "MonkeyKing"),
        .testTarget(
            name: "MonkeyKingTests",
            dependencies: ["MonkeyKing"],
            path: "Tests/MonkeyKingTests"
        ),
        .binaryTarget(
            name: "MonkeyKingBinary",
            url: "https://github.com/nixzhu/MonkeyKing/releases/download/2.2.0/MonkeyKing.xcframework.zip",
            checksum: "9b456c3a79382f06243f7ac6dde6aaf30bfc7207d580e3aafae40dfa43be873c"
        ),
    ]
)
