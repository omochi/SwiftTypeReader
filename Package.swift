// swift-tools-version:5.3

import PackageDescription

#if swift(<5.5)
let swiftSyntax: Package.Dependency = .package(
    name: "SwiftSyntax",
    url: "https://github.com/apple/swift-syntax.git", .exact("0.50400.0")
)
#else
let swiftSyntax: Package.Dependency = .package(
    name: "SwiftSyntax",
    url: "https://github.com/apple/swift-syntax.git", .revision("swift-DEVELOPMENT-SNAPSHOT-2021-05-14-a")
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
    dependencies: [
        swiftSyntax,
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
