import XCTest
import SwiftTypeReader
import SwiftIfConfig

final class IfConfigTests: ReaderTestCaseBase {
    func testNoBuildConfiguration() throws {
        let reader = Reader(
            context: context,
            buildConfiguration: nil
        )
        _ = reader.read(
            source: """
            #if os(Linux)
            struct LinuxOnly {}
            #else
            struct OtherOnly {}
            #endif
            """,
            file: URL(fileURLWithPath: "main.swift")
        )

        XCTAssertNil(reader.module.find(name: "LinuxOnly"))
        XCTAssertNotNil(reader.module.find(name: "OtherOnly")?.asStruct)
    }

    func testBuildConfigurationCustomCondition() throws {
        let reader = Reader(
            context: context,
            buildConfiguration: StaticBuildConfiguration(
                customConditions: ["DEBUG"],
                languageVersion: VersionTuple(components: [6, 0]),
                compilerVersion: VersionTuple(components: [6, 0])
            )
        )
        _ = reader.read(
            source: """
            #if DEBUG
            struct DebugOnly {}
            #else
            struct ReleaseOnly {}
            #endif
            """,
            file: URL(fileURLWithPath: "main.swift")
        )

        XCTAssertNotNil(reader.module.find(name: "DebugOnly")?.asStruct)
        XCTAssertNil(reader.module.find(name: "ReleaseOnly"))
    }

    func testBuildConfigurationTargetOS() throws {
        let reader = Reader(
            context: context,
            buildConfiguration: StaticBuildConfiguration(
                targetOSs: ["macOS"],
                languageVersion: VersionTuple(components: [6, 0]),
                compilerVersion: VersionTuple(components: [6, 0])
            )
        )
        _ = reader.read(
            source: """
            #if os(macOS)
            struct MacOnly {}
            #elseif os(Linux)
            struct LinuxOnly {}
            #else
            struct Fallback {}
            #endif
            """,
            file: URL(fileURLWithPath: "main.swift")
        )

        XCTAssertNotNil(reader.module.find(name: "MacOnly")?.asStruct)
        XCTAssertNil(reader.module.find(name: "LinuxOnly"))
        XCTAssertNil(reader.module.find(name: "Fallback"))
    }

}
