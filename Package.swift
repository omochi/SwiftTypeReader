// swift-tools-version: 6.0

import PackageDescription

let defaultSwiftSyntaxVersionRange: Range<Version> = "602.0.0"..<"999.0.0"

func swiftSyntaxVersionRange() -> Range<Version> {
    let key = "SWIFTTYPEREADER_SWIFTSYNTAX_VERSION"

    guard let versionString = Context.environment[key] else {
        return defaultSwiftSyntaxVersionRange
    }

    let rangeParts = versionString.split(separator: "..<", maxSplits: 1).map(String.init)
    guard
        rangeParts.count == 2,
        let lowerBound = Version(rangeParts[0]),
        let upperBound = Version(rangeParts[1])
    else {
        fatalError("Invalid \(key): \(versionString)")
    }

    return lowerBound..<upperBound
}

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
        .package(url: "https://github.com/swiftlang/swift-syntax.git", swiftSyntaxVersionRange()),
        .package(url: "https://github.com/omochi/CodegenKit.git", from: "2.1.1"),
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
            ]
        ),
        .testTarget(
            name: "SwiftTypeReaderTests",
            dependencies: ["SwiftTypeReader"]
        )
    ]
)
