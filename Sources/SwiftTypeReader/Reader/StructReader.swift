import Foundation
import SwiftSyntax

struct StructReader {
    var reader: Reader

    init(reader: Reader) {
        self.reader = reader
    }

    func read(struct syntax: StructDeclSyntax, on context: any DeclContext) -> StructDecl? {
        let name = syntax.identifier.text

//        let genericParameter: [GenericParameterType]
//        if let clause = syntax.genericParameterClause {
//            genericParameter = Readers.readGenericParameters(
//                context: context, clause: clause
//            )
//        } else {
//            genericParameter = []
//        }

//        let inheritedTypes: [TypeSpecifier]
//        if let clause = syntax.inheritanceClause {
//            inheritedTypes = Readers.readInheritedTypes(
//                context: context,
//                clause: clause
//            )
//        } else {
//            inheritedTypes = []
//        }

//        var storedProperties: [StoredProperty] = []
//        var nestedTypes: [SType] = []
//        let decls = syntax.members.members.map { $0.decl }
//        for decl in decls {
//            storedProperties += readStoredProperties(
//                context: context,
//                decl: decl
//            )
//            if let nestedType = Readers.readTypeDeclaration(
//                context: context,
//                declaration: decl
//            ) {
//                nestedTypes.append(nestedType)
//            }
//        }

        return StructDecl(context: context, name: name)
    }

    private func readStoredProperties(
        context: Readers.Context,
        decl: DeclSyntax
    ) -> [StoredProperty] {
        if let varDecl = decl.as(VariableDeclSyntax.self) {
            return varDecl.bindings.compactMap {
                readStoredProperty(context: context, binding: $0)
            }
        } else {
            return []
        }
    }

    private func readStoredProperty(
        context: Readers.Context,
        binding: PatternBindingSyntax
    ) -> StoredProperty? {
        if let accSyntax = binding.accessor {
            guard Readers.isStoredPropertyAccessor(accessor: accSyntax) else {
                return nil
            }
        }

        guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        let name = Readers.unescapeIdentifier(ident.identifier.text)

        guard let typeAnno = binding.typeAnnotation,
              let typeSpec = Readers.readTypeSpecifier(
                context: context,
                typeSyntax: typeAnno.type
              ) else
        {
            return nil
        }

        return StoredProperty(
            name: name,
            typeSpecifier: typeSpec
        )
    }


}
