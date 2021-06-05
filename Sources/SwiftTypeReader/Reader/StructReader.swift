import SwiftSyntax

final class StructReader {
    private let module: Module

    init(module: Module) {
        self.module = module
    }

    func read(structDecl: StructDeclSyntax) -> StructType? {
        var storedProperties: [StoredProperty] = []

        let decls = structDecl.members.members.map { $0.decl }
        for decl in decls {
            storedProperties += readStoredProperties(decl: decl)
        }

        return StructType(
            name: structDecl.identifier.text,
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
              let typeSpec = Readers.readTypeSpecifier(typeAnno.type) else
        {
            return nil
        }

        let type = UnresolvedType(
            module: module,
            specifier: typeSpec
        )

        return StoredProperty(
            name: name,
            unresolvedType: type
        )
    }


}
