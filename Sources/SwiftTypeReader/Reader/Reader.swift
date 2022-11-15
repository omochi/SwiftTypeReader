import Foundation
import SwiftSyntax
import SwiftSyntaxParser

public struct Reader {
    public var context: Context
    public var module: Module

    public init(
        context: Context,
        module: Module? = nil
    ) {
        self.context = context
        self.module = module ?? context.getOrCreateModule(name: "main")
    }

    public func read(file: URL) throws -> [SourceFile] {
        var sources: [SourceFile] = []

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

    public func read(source: String, file: URL) throws -> SourceFile {
        return try readImpl(source: source, file: file)
    }

    private func readImpl(source sourceString: String, file: URL) throws -> SourceFile {
        let sourceSyntax: SourceFileSyntax = try SyntaxParser.parse(source: sourceString)

        let statements = sourceSyntax.statements.map { $0.item }
        let context = Readers.Context(
            module: module,
            file: file,
            location: module.asLocation()
        )

        var source = SourceFile(file: file)

        for decl in statements.compactMap({ $0.as(DeclSyntax.self) }) {
            if let type = Readers.readTypeDeclaration(context: context, declaration: decl) {
                source.types.append(type)
            } else if let `import` = Readers.readImportDeclaration(context: context, declaration: decl) {
                source.imports.append(`import`)
            }
        }

        module.sources.append(source)

        return source
    }
}

