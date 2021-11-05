// swift-tools-version:5.3

import PackageDescription

var dependencies: [Package.Dependency] = []
var targetDependencies: [Target.Dependency] = []

#if os(macOS)
#if swift(>=5.5)
dependencies.append(
    .package(
        name: "SwiftSyntax",
        url: "https://github.com/apple/swift-syntax", .exact("0.50500.0")
    )
)
targetDependencies.append(
    .product(
        name: "SwiftSyntax",
        package: "SwiftSyntax"
    )
)
#else
dependencies.append(
    .package(
        name: "BinarySwiftSyntax",
        url: "https://github.com/omochi/BinarySwiftSyntax", .branch("main")
    )
)
targetDependencies.append(
    .product(
        name: "SwiftSyntax-Xcode12.5",
        package: "BinarySwiftSyntax"
    )
)
#endif
#else
dependencies.append(
    .package(
        name: "SwiftSyntax",
        url: "https://github.com/apple/swift-syntax", .exact("0.50400.0")
    )
)
targetDependencies.append(
    .product(
        name: "SwiftSyntax",
        package: "SwiftSyntax"
    )
)
#endif

let package = Package(
    name: "SwiftTypeReader",
    products: [
        .library(
            name: "SwiftTypeReader",
            targets: ["SwiftTypeReader"]
        )
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "SwiftTypeReader",
            dependencies: targetDependencies
        ),
        .testTarget(
            name: "SwiftTypeReaderTests",
            dependencies: ["SwiftTypeReader"],
            exclude: ["Resources"]
        )
    ]
)
