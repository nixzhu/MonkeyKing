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
            url: "https://github.com/nixzhu/MonkeyKing/releases/download/2.2.1/MonkeyKingBinary.xcframework.zip",
            checksum: "0b9b13b7fc53136eb5e323a92a3c5fc8d273f8d4d85c6731605b8a534da027fb"
        ),
    ]
)
