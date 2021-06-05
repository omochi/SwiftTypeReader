import SwiftSyntax

enum Readers {
    static func readTypeSpecifier(_ typeSyntax: TypeSyntax) -> TypeSpecifier? {
        if let simple = typeSyntax.as(SimpleTypeIdentifierSyntax.self) {
            let args: [TypeSpecifier]
            if let gac = simple.genericArgumentClause {
                args = gac.arguments.compactMap { readTypeSpecifier($0.argumentType) }
                guard args.count == gac.arguments.count else { return nil }
            } else {
                args = []
            }
            return TypeSpecifier(
                name: simple.name.text,
                genericArguments: args
            )
        } else if let opt = typeSyntax.as(OptionalTypeSyntax.self) {
            guard let wrapped = readTypeSpecifier(opt.wrappedType) else { return nil }
            return TypeSpecifier(
                name: "Optional",
                genericArguments: [wrapped]
            )
        } else if let array = typeSyntax.as(ArrayTypeSyntax.self) {
            guard let element = readTypeSpecifier(array.elementType) else { return nil }
            return TypeSpecifier(
                name: "Array",
                genericArguments: [element]
            )
        } else if let dict = typeSyntax.as(DictionaryTypeSyntax.self) {
            guard let key = readTypeSpecifier(dict.keyType),
                  let value = readTypeSpecifier(dict.valueType) else { return nil }
            return TypeSpecifier(
                name: "Dictionary",
                genericArguments: [key, value]
            )
        } else {
            return nil
        }
    }

    static func unescapeIdentifier(_ str: String) -> String {
        return str.trimmingCharacters(in: ["`"])
    }

    static func isStoredPropertyAccessor(accessor: Syntax) -> Bool {
        if let _ = accessor.as(CodeBlockSyntax.self) {
            return false
        } else if let accessors = accessor.as(AccessorBlockSyntax.self) {
            return accessors.accessors.allSatisfy { (accsessor) in
                isStoredPropertyAccessor(name: accsessor.accessorKind.text)
            }
        } else {
            return false
        }
    }

    static func isStoredPropertyAccessor(name: String) -> Bool {
        return name == "willSet" || name == "didSet"
    }
}
