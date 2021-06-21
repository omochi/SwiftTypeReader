import Foundation

public struct EnumType: RegularTypeProtocol {
    public init(
        module: Module,
        file: URL?,
        location: Location,
        name: String,
        genericParameters: [GenericParameterType] = [],
        genericArguments: [TypeSpecifier] = [],
        inheritedTypes: [TypeSpecifier] = [],
        caseElements: [CaseElement] = []
    ) {
        self.module = module
        self.file = file
        self.location = location
        self.name = name
        self.genericParameters = genericParameters
        self.unresolvedGenericArguments = TypeCollection(genericArguments)
        self.unresolvedInheritedTypes = TypeCollection(inheritedTypes)
        self.caseElements = caseElements
    }

    public weak var module: Module?
    public var file: URL?
    public var location: Location
    public var name: String
    public var genericParameters: [GenericParameterType]
    public var unresolvedGenericArguments: TypeCollection
    public var unresolvedInheritedTypes: TypeCollection
    public var caseElements: [CaseElement]

    public func genericArguments() throws -> [SType] {
        try unresolvedGenericArguments.resolved()
    }

    public mutating func setGenericArguments(_ ts: [SType]) {
        unresolvedGenericArguments = .resolved(ts)
    }

    public var genericArgumentSpecifiers: [TypeSpecifier] {
        unresolvedGenericArguments.asSpecifiers()
    }

    public func inheritedTypes() throws -> [SType] {
        try unresolvedInheritedTypes.resolved()
    }
}
