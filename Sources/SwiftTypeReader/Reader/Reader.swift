import Foundation
import SwiftSyntax

public final class Reader {
    public init() {}

    public func read(file: URL) throws -> Module {
        try ReaderImpl().read(file: file)
    }

    public func read(source: String, file: URL? = nil) throws -> Module {
        try ReaderImpl().read(source: source, file: file)
    }
}

private final class ReaderImpl {
    private var module: Module = Module()

    func read(file: URL) throws -> Module {
        try walk(file: file) { (file) in
            let ext = file.pathExtension
            guard ext == "swift" else {
                return
            }

            let source = try String(contentsOf: file)
            _ = try read(source: source, file: file)
        }

        return module
    }

    func read(source: String, file: URL?) throws -> Module {
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

        return module
    }


    private func walk(file: URL, _ f: (URL) throws -> Void) throws {
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: file.path, isDirectory: &isDir), isDir.boolValue {
            let dir = file
            let items = try fm.contentsOfDirectory(atPath: dir.path)
            for item in items {
                let file = dir.appendingPathComponent(item)
                try walk(file: file, f)
            }
        } else {
            try f(file)
        }
    }
}
