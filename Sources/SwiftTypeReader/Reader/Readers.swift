import Foundation
import SwiftSyntax

enum Readers {
    struct Context {
        var module: Module
        var file: URL?
        var location: Location
    }

    static func readTypeSpecifier(
        context: Context,
        typeSyntax: TypeSyntax
    ) -> TypeSpecifier? {
        if let simple = typeSyntax.as(SimpleTypeIdentifierSyntax.self) {
            let args: [TypeSpecifier]
            if let gac = simple.genericArgumentClause {
                args = gac.arguments.compactMap {
                    readTypeSpecifier(
                        context: context,
                        typeSyntax: $0.argumentType
                    )
                }
                guard args.count == gac.arguments.count else { return nil }
            } else {
                args = []
            }
            return TypeSpecifier(
                module: context.module,
                file: context.file,
                location: context.location,
                name: simple.name.text,
                genericArguments: args
            )
        }

        guard let swiftModule = context.module.modules?.swift else { return nil }

        if let opt = typeSyntax.as(OptionalTypeSyntax.self) {
            guard let wrapped = readTypeSpecifier(
                context: context,
                typeSyntax: opt.wrappedType
            ) else { return nil }
            return TypeSpecifier(
                module: swiftModule,
                file: context.file,
                location: swiftModule.asLocation(),
                name: "Optional",
                genericArguments: [wrapped]
            )
        } else if let array = typeSyntax.as(ArrayTypeSyntax.self) {
            guard let element = readTypeSpecifier(
                context: context,
                typeSyntax: array.elementType
            ) else { return nil }
            return TypeSpecifier(
                module: swiftModule,
                file: context.file,
                location: swiftModule.asLocation(),
                name: "Array",
                genericArguments: [element]
            )
        } else if let dict = typeSyntax.as(DictionaryTypeSyntax.self) {
            guard let key = readTypeSpecifier(
                context: context,
                typeSyntax: dict.keyType
            ),
            let value = readTypeSpecifier(
                context: context,
                typeSyntax: dict.valueType
            ) else { return nil }
            return TypeSpecifier(
                module: swiftModule,
                file: context.file,
                location: swiftModule.asLocation(),
                name: "Dictionary",
                genericArguments: [key, value]
            )
        } else {
            return nil
        }
    }

    static func readGenericParameters(
        context: Context,
        clause: GenericParameterClauseSyntax
    ) -> [GenericParameterType] {
        var types: [GenericParameterType] = []
        for syn in clause.genericParameterList {
            let name = syn.name.text
            let type = GenericParameterType(
                module: context.module,
                file: context.file,
                location: context.location,
                name: name
            )
            types.append(type)
        }
        return types
    }

    static func readInheritedTypes(
        context: Context,
        clause: TypeInheritanceClauseSyntax
    ) -> [TypeSpecifier] {
        var types: [TypeSpecifier] = []
        for type in clause.inheritedTypeCollection {
            if let typeSpec = readTypeSpecifier(
                context: context,
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
