import Foundation
import SwiftSyntax

final class StructReader {
    private let module: Module
    private let file: URL?
    private let location: Location

    init(
        module: Module,
        file: URL?,
        location: Location
    ) {
        self.module = module
        self.file = file
        self.location = location
    }

    func read(structDecl: StructDeclSyntax) -> StructType? {
        let name = structDecl.identifier.text

        let context = Readers.Context(
            module: module,
            file: file,
            location: location.appending(.type(name: name))
        )

        let genericParameter: [GenericParameterType]
        if let clause = structDecl.genericParameterClause {
            genericParameter = Readers.readGenericParameters(
                context: context, clause: clause
            )
        } else {
            genericParameter = []
        }

        let inheritedTypes: [TypeSpecifier]
        if let clause = structDecl.inheritanceClause {
            inheritedTypes = Readers.readInheritedTypes(
                context: context,
                clause: clause
            )
        } else {
            inheritedTypes = []
        }

        var storedProperties: [StoredProperty] = []
        var nestedTypes: [SType] = []
        let decls = structDecl.members.members.map { $0.decl }
        for decl in decls {
            storedProperties += readStoredProperties(
                context: context,
                decl: decl
            )
            if let nestedType = Readers.readTypeDeclaration(
                context: context,
                declaration: decl
            ) {
                nestedTypes.append(nestedType)
            }
        }

        return StructType(
            module: module,
            file: file,
            location: location,
            name: name,
            genericParameters: genericParameter,
            inheritedTypes: inheritedTypes,
            storedProperties: storedProperties,
            types: nestedTypes
        )
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
