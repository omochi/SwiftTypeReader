// swift-tools-version: 6.1

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
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "603.0.1"..<"999.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.3"),
        .package(url: "https://github.com/omochi/CodegenKit.git", from: "2.1.0"),
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
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftIfConfig", package: "swift-syntax"),
                .product(name: "Collections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "SwiftTypeReaderTests",
            dependencies: ["SwiftTypeReader"]
        )
    ]
)
