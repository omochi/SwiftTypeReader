import Foundation

/*
 Protocol.
 Not exsitential container type.
 */
public struct ProtocolType: RegularTypeProtocol {
    public init(
        module: Module,
        file: URL?,
        location: Location,
        name: String,
        inheritedTypes: [TypeSpecifier] = [],
        propertyRequirements: [PropertyRequirement] = [],
        functionRequirements: [FunctionRequirement] = [],
        associatedTypes: [String] = []
    ) {
        self.module = module
        self.file = file
        self.location = location
        self.name = name
        self.unresolvedInheritedTypes = TypeCollection(inheritedTypes)
        self.propertyRequirements = propertyRequirements
        self.functionRequirements = functionRequirements
        self.associatedTypes = associatedTypes
    }

    public unowned var module: Module
    public var file: URL?
    public var location: Location
    public var name: String
    public var unresolvedInheritedTypes: TypeCollection
    public var propertyRequirements: [PropertyRequirement]
    public var functionRequirements: [FunctionRequirement]
    public var associatedTypes: [String]

    public var genericParameters: [GenericParameterType] { [] }

    public func genericArguments() -> [SType] { [] }
    public var genericArgumentSpecifiers: [TypeSpecifier] { [] }

    public func inheritedTypes() -> [SType] {
        unresolvedInheritedTypes.resolved()
    }

    public var types: [SType] { [] }
}
