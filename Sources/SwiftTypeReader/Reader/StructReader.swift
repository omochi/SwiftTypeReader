import Foundation
import SwiftSyntax

struct StructReader {
    var reader: Reader

    init(reader: Reader) {
        self.reader = reader
    }

    func read(struct structSyntax: StructDeclSyntax, on context: any DeclContext) -> StructDecl? {
        let name = structSyntax.identifier.text

        let `struct` = StructDecl(context: context, name: name)

        `struct`.genericParams = Reader.readOptionalGenericParamList(
            clause: structSyntax.genericParameterClause, on: `struct`
        )

        `struct`.inheritedTypeReprs = Reader.readOptionalInheritedTypes(
            inheritance: structSyntax.inheritanceClause
        )

        let memberDecls = structSyntax.members.members.map { $0.decl }
        for memberDecl in memberDecls {
            `struct`.storedProperties += readStoredProperties(
                decl: memberDecl, on: `struct`
            )
            if let nestedType = reader.readNominalTypeDecl(
                decl: memberDecl, on: `struct`
            ) {
                `struct`.types.append(nestedType)
            }
        }

        return `struct`
    }

    private func readStoredProperties(
        decl: DeclSyntax,
        on context: any DeclContext
    ) -> [VarDecl] {
        guard let varDecl = decl.as(VariableDeclSyntax.self) else {
            return []
        }

        return varDecl.bindings.compactMap {
            readStoredProperty(binding: $0, on: context)
        }
    }

    private func readStoredProperty(
        binding: PatternBindingSyntax,
        on context: any DeclContext
    ) -> VarDecl? {
        if let accessorSyntax = binding.accessor {
            guard Reader.isStoredPropertyAccessor(accessor: accessorSyntax) else {
                return nil
            }
        }

        guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        let name = Reader.unescapeIdentifier(ident.identifier.text)

        guard let typeAnno = binding.typeAnnotation,
              let typeRepr = Reader.readTypeRepr(
                type: typeAnno.type
              ) else
        {
            return nil
        }

        return VarDecl(
            context: context,
            name: name,
            typeRepr: typeRepr
        )
    }


}
