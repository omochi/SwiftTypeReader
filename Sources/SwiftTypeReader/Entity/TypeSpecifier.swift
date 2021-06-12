import Foundation

public struct TypeSpecifier: CustomStringConvertible {
    public init(
        module: Module?,
        file: URL?,
        name: String,
        genericArguments: [TypeSpecifier]
    ) {
        self.module = module
        self.file = file
        self.name = name
        self.genericArguments = genericArguments
    }

    public weak var module: Module?
    public var file: URL?
    public var name: String
    public var genericArguments: [TypeSpecifier]

    public var description: String {
        var str = name
        if !genericArguments.isEmpty {
            str += "<"
            str += genericArguments.map { $0.description }
                .joined(separator: ", ")
            str += ">"
        }
        return str
    }

    public func resolve() throws -> SType {
        guard let module = self.module else {
            return .unresolved(self)
        }

        return try module.resolveType(specifier: self)
    }
}
