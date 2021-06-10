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
            url: "https://github.com/apple/swift-syntax", .exact("0.50400.0")
        ),
        .package(
            name: "BinarySwiftSyntax",
            url: "https://github.com/omochi/BinarySwiftSyntax", .branch("main")
        )
    ],
    targets: [
        .target(
            name: "SwiftTypeReader",
            dependencies: [
                .product(
                    name: "SwiftSyntax",
                    package: "SwiftSyntax",
                    condition: .when(platforms: [.linux])
                ),
                .product(
                    name: "SwiftSyntax-Xcode12.5",
                    package: "BinarySwiftSyntax",
                    condition: .when(platforms: [.macOS])
                )
            ]
        ),
        .testTarget(
            name: "SwiftTypeReaderTests",
            dependencies: ["SwiftTypeReader"],
            exclude: ["Resources"]
        )
    ]
)
