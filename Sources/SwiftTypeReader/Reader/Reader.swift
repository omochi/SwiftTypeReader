import Foundation
import SwiftSyntax
import SwiftSyntaxParser

public struct Reader {
    public var context: Context
    public var module: ModuleDecl

    public init(
        context: Context,
        module: ModuleDecl? = nil
    ) {
        self.context = context
        self.module = module ?? context.getOrCreateModule(name: "main")
    }

    public func read(file: URL) throws -> [SourceFileDecl] {
        var sources: [SourceFileDecl] = []

        for file in fm.directoryOrFileEnumerator(at: file) {
            let ext = file.pathExtension
            guard ext == "swift" else {
                continue
            }

            let string = try String(contentsOf: file)
            sources.append(
                try readImpl(source: string, file: file)
            )
        }

        return sources
    }

    public func read(source: String, file: URL) throws -> SourceFileDecl {
        return try readImpl(source: source, file: file)
    }

    private func readImpl(source sourceString: String, file: URL) throws -> SourceFileDecl {
        let sourceSyntax: SourceFileSyntax = try SyntaxParser.parse(source: sourceString)

        let statements = sourceSyntax.statements.map { $0.item }

        var source = SourceFileDecl(module: module, file: file)

        for decl in statements.compactMap({ $0.as(DeclSyntax.self) }) {
            if let type = readNominalTypeDecl(decl: decl, on: source) {
                source.types.append(type)
            }

//            if let type = Readers.readTypeDeclaration(context: context, declaration: decl) {
//                source.types.append(type)
//            } else if let `import` = Readers.readImportDeclaration(context: context, declaration: decl) {
//                source.imports.append(`import`)
//            }
        }

        module.sources.append(source)

        return source
    }

    private func readNominalTypeDecl(decl: DeclSyntax, on context: any DeclContext) -> (any NominalTypeDecl)? {
        if let `struct` = decl.as(StructDeclSyntax.self) {
            let reader = StructReader(reader: self)
            return reader.read(struct: `struct`, on: context)
        } else {
            return nil
        }
    }
}

