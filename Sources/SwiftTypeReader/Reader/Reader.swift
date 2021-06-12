import Foundation
import SwiftSyntax

public final class Reader {
    public struct Result {
        public var modules: Modules
        public var module: Module
    }

    public init(modules: Modules?) {
        self.modules = modules ?? Modules()
    }

    public var modules: Modules

    public func read(file: URL, module: Module? = nil) throws -> Result {
        let reader = Impl(modules: modules, module: module)
        try reader.read(file: file)
        return reader.result()
    }

    public func read(source: String, file: URL? = nil, module: Module? = nil) throws -> Result {
        let reader = Impl(modules: modules, module: module)
        try reader.read(source: source, file: file)
        return reader.result()
    }
}

private final class Impl {
    init(modules: Modules, module: Module?) {
        let targetModule: Module
        if let module = module {
            targetModule = module
        } else {
            targetModule = Module(
                modules: modules,
                name: nil
            )
            // before Swift module
            modules.modules.insert(targetModule, at: 0)
        }

        self.modules = modules
        self.module = targetModule
    }

    let modules: Modules
    let module: Module

    func result() -> Reader.Result {
        .init(
            modules: modules,
            module: module
        )
    }

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
