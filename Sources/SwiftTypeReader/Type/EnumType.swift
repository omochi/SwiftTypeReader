import Foundation

public struct EnumType {
    public init(
        module: Module,
        file: URL?,
        name: String,
        genericArguments: [TypeSpecifier] = [],
        inheritedTypes: [TypeSpecifier] = [],
        caseElements: [CaseElement] = []
    ) {
        self.module = module
        self.file = file
        self.name = name
        self.unresolvedGenericArguments = TypeCollection(genericArguments)
        self.unresolvedInheritedTypes = TypeCollection(inheritedTypes)
        self.caseElements = caseElements
    }

    public var module: Module
    public var file: URL?
    public var name: String
    public var unresolvedGenericArguments: TypeCollection
    public var unresolvedInheritedTypes: TypeCollection
    public var caseElements: [CaseElement]

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
