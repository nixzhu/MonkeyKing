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
        .library(name: "MonkeyKingBinary", targets: ["MonkeyKingBinary"])
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
                    url: "https://github.com/CodeEagle/MonkeyKing/releases/download/2.2.0/MonkeyKingBinary.xcframework.zip",
                    checksum: "c186cb3a81a2a9b4434632829ff83f7f4c2b16ab119bf175d1e2e0a5bd88fed3"
                ),
    ]
)
