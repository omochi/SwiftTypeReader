import SwiftIfConfig
import SwiftSyntax

#if canImport(SwiftSyntax603)
public typealias StaticBuildConfiguration = SwiftIfConfig.StaticBuildConfiguration
#else
public struct StaticBuildConfiguration: BuildConfiguration {
    public var customConditions: Set<String>
    public var features: Set<String>
    public var attributes: Set<String>
    public var importableModules: Set<String>
    public var targetOSs: Set<String>
    public var targetArchitectures: Set<String>
    public var targetEnvironments: Set<String>
    public var targetRuntimes: Set<String>
    public var targetPointerAuthentications: Set<String>
    public var targetPointerBitWidth: Int
    public var targetAtomicBitWidths: [Int]
    public var endianness: Endianness
    public var languageVersion: VersionTuple
    public var compilerVersion: VersionTuple

    public init(
        customConditions: Set<String> = [],
        features: Set<String> = [],
        attributes: Set<String> = [],
        importableModules: Set<String> = [],
        targetOSs: Set<String> = [],
        targetArchitectures: Set<String> = [],
        targetEnvironments: Set<String> = [],
        targetRuntimes: Set<String> = [],
        targetPointerAuthentications: Set<String> = [],
        targetPointerBitWidth: Int = 64,
        targetAtomicBitWidths: [Int] = [8, 16, 32, 64],
        endianness: Endianness = .little,
        languageVersion: VersionTuple,
        compilerVersion: VersionTuple
    ) {
        self.customConditions = customConditions
        self.features = features
        self.attributes = attributes
        self.importableModules = importableModules
        self.targetOSs = targetOSs
        self.targetArchitectures = targetArchitectures
        self.targetEnvironments = targetEnvironments
        self.targetRuntimes = targetRuntimes
        self.targetPointerAuthentications = targetPointerAuthentications
        self.targetPointerBitWidth = targetPointerBitWidth
        self.targetAtomicBitWidths = targetAtomicBitWidths
        self.endianness = endianness
        self.languageVersion = languageVersion
        self.compilerVersion = compilerVersion
    }

    public func isCustomConditionSet(name: String) throws -> Bool {
        customConditions.contains(name)
    }

    public func hasFeature(name: String) throws -> Bool {
        features.contains(name)
    }

    public func hasAttribute(name: String) throws -> Bool {
        attributes.contains(name)
    }

    public func canImport(importPath: [(TokenSyntax, String)], version: CanImportVersion) throws -> Bool {
        guard let moduleName = importPath.first?.1 else {
            return false
        }
        return importableModules.contains(moduleName)
    }

    public func isActiveTargetOS(name: String) throws -> Bool {
        targetOSs.contains(name)
    }

    public func isActiveTargetArchitecture(name: String) throws -> Bool {
        targetArchitectures.contains(name)
    }

    public func isActiveTargetEnvironment(name: String) throws -> Bool {
        targetEnvironments.contains(name)
    }

    public func isActiveTargetRuntime(name: String) throws -> Bool {
        targetRuntimes.contains(name)
    }

    public func isActiveTargetPointerAuthentication(name: String) throws -> Bool {
        targetPointerAuthentications.contains(name)
    }

    public func isActiveTargetObjectFormat(name: String) throws -> Bool {
        false
    }
}
#endif
