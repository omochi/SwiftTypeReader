import Foundation
import SwiftSyntax

enum Readers {
    struct Context {
        var module: Module
        var file: URL
        var location: Location
    }

    static func readTypeDeclaration(
        context: Context,
        declaration: DeclSyntax
    ) -> SType? {
        if let _ = declaration.as(StructDeclSyntax.self) {
            fatalError()
//            let reader = StructReader(
//                module: context.module,
//                file: context.file,
//                location: context.location
//            )
//            guard let type = reader.read(structDecl: decl) else {
//                return nil
//            }
//            return .struct(type)
        } else if let _ = declaration.as(EnumDeclSyntax.self) {
            fatalError()
//            let reader = EnumReader(
//                module: context.module,
//                file: context.file,
//                location: context.location
//            )
//            guard let type = reader.read(enumDecl: decl) else {
//                return nil
//            }
//            return .enum(type)
        } else if let decl = declaration.as(ProtocolDeclSyntax.self) {
            let reader = ProtocolReader(
                module: context.module,
                file: context.file,
                location: context.location
            )
            guard let pt = reader.read(protocolDecl: decl) else {
                return nil
            }
            return .protocol(pt)
        } else {
            return nil
        }
    }

    static func readTypeSpecifier(
        context: Context,
        typeSyntax: TypeSyntax
    ) -> TypeSpecifier? {
        func makeTypeSpecifier(
            context: Context = context,
            elements: [TypeSpecifier.Element]
        ) -> TypeSpecifier {
            .init(
                module: context.module,
                file: context.file,
                location: context.location,
                elements: elements
            )
        }

        if let member = typeSyntax.as(MemberTypeIdentifierSyntax.self) {
            guard let base = readTypeSpecifier(
                context: context,
                typeSyntax: member.baseType
            ) else { return nil }

            let args = member.genericArgumentClause.flatMap {
                readGenericArguments(context: context, clause: $0)
            } ?? []

            var elements = base.elements
            elements.append(
                .init(
                    name: member.name.text,
                    genericArgumentSpecifiers: args
                )
            )
            return makeTypeSpecifier(elements: elements)
        }

        if let simple = typeSyntax.as(SimpleTypeIdentifierSyntax.self) {
            let args = simple.genericArgumentClause.flatMap {
                readGenericArguments(context: context, clause: $0)
            } ?? []

            return makeTypeSpecifier(elements: [.init(
                name: simple.name.text,
                genericArgumentSpecifiers: args
            )])
        }

        if let opt = typeSyntax.as(OptionalTypeSyntax.self) {
            guard let wrapped = readTypeSpecifier(
                context: context,
                typeSyntax: opt.wrappedType
            ) else { return nil }
            return makeTypeSpecifier(
                context: context,
                elements: [.init(
                    name: "Optional",
                    genericArgumentSpecifiers: [wrapped]
                )]
            )
        } else if let array = typeSyntax.as(ArrayTypeSyntax.self) {
            guard let element = readTypeSpecifier(
                context: context,
                typeSyntax: array.elementType
            ) else { return nil }
            return makeTypeSpecifier(
                context: context,
                elements: [.init(
                    name: "Array",
                    genericArgumentSpecifiers: [element]
                )]
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
            return makeTypeSpecifier(
                context: context,
                elements: [.init(
                    name: "Dictionary",
                    genericArgumentSpecifiers: [key, value]
                )]
            )
        } else {
            return nil
        }
    }

    static func readGenericArguments(
        context: Context,
        clause: GenericArgumentClauseSyntax
    ) -> [TypeSpecifier]? {
        let args = clause.arguments.compactMap {
            readTypeSpecifier(
                context: context,
                typeSyntax: $0.argumentType
            )
        }
        guard args.count == clause.arguments.count else { return nil }
        return args
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
