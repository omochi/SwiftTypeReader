import Foundation

public final class Module {
    public init() {}

    public var types: [Type] = []

    public func resolveType(specifier: TypeSpecifier) -> Type {
        guard var type = findType(name: specifier.name) else {
            return .unresolved(UnresolvedType(module: self, specifier: specifier))
        }

        let args = specifier.genericArguments.compactMap { (argSpec) in
            resolveType(specifier: argSpec)
        }

        type.genericArguments = args

        return type
    }

    private func findType(name: String) -> Type? {
        if let type = (types.first { (type) in
            type.name == name
        }) {
            return type
        }

        if let type = (Self.standardTypes.first { (type) in
            type.name == name
        }) {
            return type
        }

        return nil
    }

    public static let standardTypes: [Type] = [
        .struct(StructType(name: "Void")),
        .struct(StructType(name: "Bool")),
        .struct(StructType(name: "Int")),
        .struct(StructType(name: "Float")),
        .struct(StructType(name: "Double")),
        .struct(StructType(name: "String")),
        .struct(StructType(name: "Optional")),
        .struct(StructType(name: "Array")),
        .struct(StructType(name: "Dictionary"))
    ]
}
