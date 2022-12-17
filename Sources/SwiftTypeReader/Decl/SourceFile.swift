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
    public var types: [any GenericTypeDecl]

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.type {
            if let type = types.first(where: { (type) in
                switch type {
                case let type as any NominalTypeDecl:
                    return type.name == name
                case let type as TypeAliasDecl:
                    return type.name == name
                default:
                    return false
                }
            }) {
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
