import Foundation
import SwiftSyntax

public final class Reader {
    public init() {}

    public func read(file: URL) throws -> Module {
        let reader = Impl()
        try reader.read(file: file)
        return reader.module
    }

    public func read(source: String, file: URL? = nil) throws -> Module {
        let reader = Impl()
        try reader.read(source: source, file: file)
        return reader.module
    }
}

private final class Impl {
    var module: Module = Module()

    func read(file: URL) throws {
        for file in fm.directoryOrFileEnumerator(at: file) {
            let ext = file.pathExtension
            guard ext == "swift" else {
                continue
            }

            let source = try String(contentsOf: file)
            try read(source: source, file: file)
        }
    }

    func read(source: String, file: URL?) throws {
        let sourceFile: SourceFileSyntax = try SyntaxParser.parse(source: source)

        let statements = sourceFile.statements.map { $0.item }

        for statement in statements {
            if let decl = statement.as(StructDeclSyntax.self) {
                if let st = StructReader(module: module, file: file)
                    .read(structDecl: decl)
                {
                    module.types.append(.struct(st))
                }
            } else if let decl = statement.as(EnumDeclSyntax.self) {
                if let et = EnumReader(module: module, file: file)
                    .read(enumDecl: decl)
                {
                    module.types.append(.enum(et))
                }
            }
        }
    }
}
