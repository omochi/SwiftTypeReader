public final class Module: TypeDecl & DeclContext {
    public init(
        context: Context,
        name: String
    ) {
        self.context = context
        self.name = name
        self.sources = []
    }

    public unowned var context: Context
    public var parentContext: (any DeclContext)? { nil }
    public var name: String
    public var valueName: String? { name }
    public var inheritedTypeReprs: [any TypeRepr] { [] }

    public var sources: [SourceFile]

    public var types: [any NominalTypeDecl] {
        sources.flatMap { $0.types }
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        for source in sources {
            if let decl = source.find(name: name, options: options) {
                return decl
            }
        }
        return nil
    }

    public var importedModules: [ImportedModule] {
        do {
            return try rootContext.evaluator(
                ImportedModulesRequest(module: self)
            )
        } catch {
            return []
        }
    }

    static func swiftStandardLibrary(context: Context) -> Module {
        var builder = StandardLibraryBuilder(context: context)
        return builder.build()
    }
}
