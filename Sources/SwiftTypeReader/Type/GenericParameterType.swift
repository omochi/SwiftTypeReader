import Foundation

public struct GenericParameterType: RegularTypeProtocol {
    public init(
        module: Module?,
        file: URL?,
        location: Location,
        name: String
    ) {
        self.module = module
        self.file = file
        self.location = location
        self.name = name
    }

    public weak var module: Module?
    public var file: URL?
    public var location: Location
    public var name: String

    public var genericParameters: [GenericParameterType] { [] }

    public func genericArguments() throws -> [SType] { [] }
    public var genericArgumentSpecifiers: [TypeSpecifier] { [] }
}
