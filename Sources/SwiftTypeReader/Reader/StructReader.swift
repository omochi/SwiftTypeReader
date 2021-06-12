import Foundation
import SwiftSyntax

final class StructReader {
    private let module: Module
    private let file: URL?

    init(
        module: Module,
        file: URL?
    ) {
        self.module = module
        self.file = file
    }

    func read(structDecl: StructDeclSyntax) -> StructType? {
        let inheritedTypes: [TypeSpecifier]
        if let clause = structDecl.inheritanceClause {
            inheritedTypes = Readers.readInheritedTypes(
                module: module,
                file: file,
                clause: clause
            )
        } else {
            inheritedTypes = []
        }

        var storedProperties: [StoredProperty] = []
        let decls = structDecl.members.members.map { $0.decl }
        for decl in decls {
            storedProperties += readStoredProperties(decl: decl)
        }

        return StructType(
            module: module,
            file: file,
            name: structDecl.identifier.text,
            inheritedTypes: inheritedTypes,
            storedProperties: storedProperties
        )
    }

    private func readStoredProperties(decl: DeclSyntax) -> [StoredProperty] {
        if let varDecl = decl.as(VariableDeclSyntax.self) {
            return varDecl.bindings.compactMap {
                readStoredProperty($0)
            }
        } else {
            return []
        }
    }

    private func readStoredProperty(_ binding: PatternBindingSyntax) -> StoredProperty? {
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
                module: module,
                file: file,
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
