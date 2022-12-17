// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "SwiftTypeReader",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "SwiftTypeReader",
            targets: ["SwiftTypeReader"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", exact: "0.50700.1"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.3"),
        .package(url: "https://github.com/omochi/CodegenKit", from: "1.1.0")
    ],
    targets: [
        .executableTarget(
            name: "codegen",
            dependencies: [
                .product(name: "CodegenKit", package: "CodegenKit")
            ]
        ),
        .plugin(
            name: "CodegenPlugin",
            capability: .command(
                intent: .custom(verb: "codegen", description: "codegen"),
                permissions: [.writeToPackageDirectory(reason: "codegen")]
            ),
            dependencies: [
                .target(name: "codegen")
            ]
        ),
        .target(
            name: "SwiftTypeReader",
            dependencies: [
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "SwiftTypeReaderTests",
            dependencies: ["SwiftTypeReader"]
        )
    ]
)
