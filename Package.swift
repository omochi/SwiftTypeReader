// swift-tools-version:5.3

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
        .package(
            name: "SwiftSyntax",
            url: "https://github.com/apple/swift-syntax.git", .exact("0.50400.0")
        )
    ],
    targets: [
        .target(
            name: "SwiftTypeReader",
            dependencies: [
                "SwiftSyntax"
            ]
        ),
        .testTarget(
            name: "SwiftTypeReaderTests",
            dependencies: ["SwiftTypeReader"],
            exclude: ["Resources"]

        )
    ]
)
