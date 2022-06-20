import Foundation
import SwiftSyntax
import SwiftSyntaxParser

public final class Reader {
    public struct Result {
        public var modules: Modules
        public var module: Module
    }

    public init(modules: Modules? = nil, moduleName: String = "main") {
        self.modules = modules ?? Modules()
        self.moduleName = moduleName
    }

    public var modules: Modules
    public var moduleName: String

    public func read(file: URL, module: Module? = nil) throws -> Result {
        let module = initModule(module)
        let reader = try Impl(module: module)
        try reader.read(file: file)
        return reader.result()
    }

    public func read(source: String, file: URL? = nil, module: Module? = nil) throws -> Result {
        let module = initModule(module)
        let reader = try Impl(module: module)
        try reader.read(source: source, file: file)
        return reader.result()
    }

    private func initModule(_ module: Module?) -> Module {
        if let module = module {
            return module
        }

        let module = Module(
            modules: modules,
            name: moduleName
        )
        modules.modules.append(module)
        return module
    }
}

private final class Impl {
    init(module: Module) throws {
        guard let modules = module.modules else {
            throw MessageError("no Modules")
        }

        self.modules = modules
        self.module = module
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
                let reader = StructReader(
                    module: module,
                    file: file,
                    location: module.asLocation()
                )
                if let st = reader.read(structDecl: decl) {
                    module.types.append(.struct(st))
                }
            } else if let decl = statement.as(EnumDeclSyntax.self) {
                let reader = EnumReader(
                    module: module,
                    file: file,
                    location: module.asLocation()
                )
                if let et = reader.read(enumDecl: decl) {
                    module.types.append(.enum(et))
                }
            } else if let decl = statement.as(ProtocolDeclSyntax.self) {
                let reader = ProtocolReader(
                    module: module, file: file, location: module.asLocation()
                )
                if let pt = reader.read(protocolDecl: decl) {
                    module.types.append(.protocol(pt))
                }
            }
        }
    }
}
