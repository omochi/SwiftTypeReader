// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "SwiftTypeReader",
    products: [
        .library(
            name: "SwiftTypeReader",
            targets: ["SwiftTypeReader"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", branch: "0.50600.1"),
    ],
    targets: [
        .target(
            name: "SwiftTypeReader",
            dependencies: [
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SwiftTypeReaderTests",
            dependencies: ["SwiftTypeReader"]
        )
    ]
)
