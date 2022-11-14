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

    public func read(file: URL) throws -> Module {
        for file in fm.directoryOrFileEnumerator(at: file) {
            let ext = file.pathExtension
            guard ext == "swift" else {
                continue
            }

            let source = try String(contentsOf: file)
            try readImpl(source: source, file: file)
        }
        return module
    }

    public func read(source: String, file: URL? = nil) throws -> Module {
        try readImpl(source: source, file: file)
        return module
    }

    private func readImpl(source: String, file: URL?) throws {
        let sourceFile: SourceFileSyntax = try SyntaxParser.parse(source: source)

        let statements = sourceFile.statements.map { $0.item }
        let context = Readers.Context(
            module: module,
            file: file,
            location: module.asLocation()
        )

        for decl in statements.compactMap({ $0.as(DeclSyntax.self) }) {
            if let type = Readers.readTypeDeclaration(context: context, declaration: decl) {
                module.types.append(type)
            } else if let `import` = Readers.readImportDeclaration(context: context, declaration: decl) {
                module.imports.append(`import`)
            }
        }
    }
}

