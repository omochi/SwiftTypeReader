import Foundation

/*
 Protocol.
 Not exsitential container type.
 */
public struct ProtocolType: RegularTypeProtocol {
    public init(
        module: Module?,
        file: URL?,
        location: Location,
        name: String,
        inheritedTypes: [TypeSpecifier] = [],
        propertyRequirements: [PropertyRequirement] = []
    ) {
        self.module = module
        self.file = file
        self.location = location
        self.name = name
        self.unresolvedInheritedTypes = TypeCollection(inheritedTypes)
        self.propertyRequirements = propertyRequirements
    }

    public weak var module: Module?
    public var file: URL?
    public var location: Location
    public var name: String
    public var unresolvedInheritedTypes: TypeCollection
    public var propertyRequirements: [PropertyRequirement]

    public var genericParameters: [GenericParameterType] { [] }

    public func genericArguments() throws -> [SType] { [] }
    public var genericArgumentSpecifiers: [TypeSpecifier] { [] }

}
