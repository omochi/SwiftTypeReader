import Foundation

public struct GenericParameterType: RegularTypeProtocol {
    public init(
        module: Module,
        file: URL,
        location: Location,
        name: String
    ) {
        self.module = module
        self.file = file
        self.location = location
        self.name = name
    }

    public unowned var module: Module
    public var file: URL
    public var location: Location
    public var name: String

    public var genericParameters: [GenericParameterType] { [] }

    public func genericArguments() -> [SType] { [] }
    public var genericArgumentSpecifiers: [TypeSpecifier] { [] }

    public func inheritedTypes() -> [SType] { [] }

    public var types: [SType] { [] }

    public func asSpecifier() -> TypeSpecifier {
        let elements: [TypeSpecifier.Element] = [
            .init(name: name)
        ]

        return TypeSpecifier(
            module: module,
            file: file,
            location: location,
            elements: elements
        )
    }
}
