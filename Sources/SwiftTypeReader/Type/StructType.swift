import Foundation

public struct StructType {
    public init(
        module: Module,
        file: URL?,
        name: String,
        genericArguments: [TypeSpecifier] = [],
        inheritedTypes: [TypeSpecifier] = [],
        storedProperties: [StoredProperty] = []
    ) {
        self.module = module
        self.file = file
        self.name = name
        self.unresolvedGenericArguments = TypeCollection(genericArguments)
        self.unresolvedInheritedTypes = TypeCollection(inheritedTypes)
        self.storedProperties = storedProperties
    }

    public weak var module: Module?
    public var file: URL?
    public var name: String
    public var unresolvedGenericArguments: TypeCollection
    public var unresolvedInheritedTypes: TypeCollection
    public var storedProperties: [StoredProperty]

    public func genericArguments() throws -> [SType] {
        try unresolvedGenericArguments.resolved()
    }

    public mutating func setGenericArguments(_ ts: [SType]) {
        unresolvedGenericArguments = .resolved(ts)
    }

    public func inheritedTypes() throws -> [SType] {
        try unresolvedInheritedTypes.resolved()
    }
}
