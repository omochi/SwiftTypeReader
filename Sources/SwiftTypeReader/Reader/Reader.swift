import Foundation
import SwiftSyntax

public final class Reader {
    func read(directory: URL) throws -> Module {
        try ReaderImpl().read(directory: directory)
    }

    func read(source: String) throws -> Module {
        try ReaderImpl().read(source: source)
    }
}

private final class ReaderImpl {
    private var module: Module = Module()

    func read(directory: URL) throws -> Module {
        try walk(directory: directory) { (file) in
            let ext = file.pathExtension
            guard ext == "swift" else {
                return
            }


            let source = try String(contentsOf: file)
            _ = try read(source: source)
        }

        return module
    }

    func read(source: String) throws -> Module {
        let sourceFile: SourceFileSyntax = try SyntaxParser.parse(source: source)

        let statements = sourceFile.statements.map { $0.item }

        for statement in statements {
            if let structDecl = statement.as(StructDeclSyntax.self) {
                var storedProperties: [StoredProperty] = []

                let decls = structDecl.members.members.map { $0.decl }
                for decl in decls {
                    storedProperties += readStoredProperties(decl: decl)
                }

                let st = StructType(
                    name: structDecl.identifier.text,
                    storedProperties: storedProperties
                )

                module.types.append(.struct(st))
            }
        }

        return module
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
        if let _ = binding.accessor {
            return nil
        }

        guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        let name = unescapeIdentifier(ident.identifier.text)

        guard let typeAnno = binding.typeAnnotation,
              let typeSpec = readTypeSpecifier(typeAnno.type) else
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

    private func readTypeSpecifier(_ typeSyntax: TypeSyntax) -> TypeSpecifier? {
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

    private func unescapeIdentifier(_ str: String) -> String {
        return str.trimmingCharacters(in: ["`"])
    }

    private func walk(directory: URL, _ f: (URL) throws -> Void) throws {
        let items = try fm.contentsOfDirectory(atPath: directory.path)

        for item in items {
            let file = directory.appendingPathComponent(item)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: file.path, isDirectory: &isDir), isDir.boolValue {
                try walk(directory: file, f)
            } else {
                try f(file)
            }
        }
    }
}
