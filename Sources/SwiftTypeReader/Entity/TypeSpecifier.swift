import Foundation

public struct TypeSpecifier: CustomStringConvertible {
    public init(
        module: Module?,
        file: URL?,
        location: Location,
        name: String,
        genericArgumentSpecifiers: [TypeSpecifier]
    ) {
        self.module = module
        self.file = file
        self.location = location
        self.name = name
        self.unresolvedGenericArguments = TypeCollection(genericArgumentSpecifiers)
    }

    public weak var module: Module?
    public var file: URL?
    public var location: Location
    public var name: String

    public func genericArguments() throws -> [SType] {
        try unresolvedGenericArguments.resolved()
    }

    public var genericArgumentSpecifiers: [TypeSpecifier] {
        get {
            unresolvedGenericArguments.asSpecifiers()
        }
        set {
            unresolvedGenericArguments = TypeCollection(newValue)
        }
    }

    public var unresolvedGenericArguments: TypeCollection

    public var description: String {
        var str = name
        if !genericArgumentSpecifiers.isEmpty {
            str += "<"
            str += genericArgumentSpecifiers.map { $0.description }
                .joined(separator: ", ")
            str += ">"
        }
        return str
    }

    public func resolve() throws -> SType {
        guard let module = self.module else {
            throw MessageError("no Module")
        }

        return try module.resolveType(specifier: self)
    }
}
