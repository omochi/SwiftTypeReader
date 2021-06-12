import Foundation
import SwiftSyntax

enum Readers {
    static func readTypeSpecifier(
        module: Module,
        file: URL?,
        typeSyntax: TypeSyntax
    ) -> TypeSpecifier? {
        if let simple = typeSyntax.as(SimpleTypeIdentifierSyntax.self) {
            let args: [TypeSpecifier]
            if let gac = simple.genericArgumentClause {
                args = gac.arguments.compactMap {
                    readTypeSpecifier(
                        module: module,
                        file: file,
                        typeSyntax: $0.argumentType
                    )
                }
                guard args.count == gac.arguments.count else { return nil }
            } else {
                args = []
            }
            return TypeSpecifier(
                module: module,
                file: file,
                name: simple.name.text,
                genericArguments: args
            )
        }

        guard let swiftModule = module.modules?.swift else { return nil }

        if let opt = typeSyntax.as(OptionalTypeSyntax.self) {
            guard let wrapped = readTypeSpecifier(
                module: module,
                file: file,
                typeSyntax: opt.wrappedType
            ) else { return nil }
            return TypeSpecifier(
                module: swiftModule,
                file: file,
                name: "Optional",
                genericArguments: [wrapped]
            )
        } else if let array = typeSyntax.as(ArrayTypeSyntax.self) {
            guard let element = readTypeSpecifier(
                module: module,
                file: file,
                typeSyntax: array.elementType
            ) else { return nil }
            return TypeSpecifier(
                module: swiftModule,
                file: file,
                name: "Array",
                genericArguments: [element]
            )
        } else if let dict = typeSyntax.as(DictionaryTypeSyntax.self) {
            guard let key = readTypeSpecifier(
                module: module,
                file: file,
                typeSyntax: dict.keyType
            ),
            let value = readTypeSpecifier(
                module: module,
                file: file,
                typeSyntax: dict.valueType
            ) else { return nil }
            return TypeSpecifier(
                module: swiftModule,
                file: file,
                name: "Dictionary",
                genericArguments: [key, value]
            )
        } else {
            return nil
        }
    }

    static func readInheritedTypes(
        module: Module,
        file: URL?,
        clause: TypeInheritanceClauseSyntax
    ) -> [TypeSpecifier] {
        var types: [TypeSpecifier] = []
        for type in clause.inheritedTypeCollection {
            if let typeSpec = readTypeSpecifier(
                module: module,
                file: file,
                typeSyntax: type.typeName
            ) {
                types.append(typeSpec)
            }
        }
        return types
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
