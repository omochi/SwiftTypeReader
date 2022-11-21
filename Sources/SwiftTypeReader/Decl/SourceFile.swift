import Foundation

public final class SourceFile: Decl & DeclContext {
    public init(
        module: Module,
        file: URL
    ) {
        self.module = module
        self.file = file
        self.imports = []
        self.types = []
    }

    public unowned var module: Module
    public var file: URL
    public var parentContext: (any DeclContext)? { module }

    public var imports: [ImportDecl]
    public var types: [any NominalTypeDecl]

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.type {
            if let type = types.first(where: { $0.name == name }) {
                return type
            }
        }
        return nil
    }

    public var importedModules: [ImportedModule] {
        do {
            return try rootContext.evaluator(
                ImportedModulesRequest(module: module, source: self)
            )
        } catch {
            return []
        }
    }
}
