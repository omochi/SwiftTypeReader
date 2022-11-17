public final class ModuleDecl: ValueDecl & DeclContext {
    public init(
        context: Context,
        name: String
    ) {
        self.context = context
        self.name = name
        self.sources = []
    }

    public unowned var context: Context
    public var name: String
    public var parentContext: (any DeclContext)? { nil }

    public var sources: [SourceFileDecl]

    public var types: [any NominalTypeDecl] {
        sources.flatMap { $0.types }
    }

    public var interfaceType: any SType2 {
        ModuleType(decl: self)
    }

    public func findOwn(name: String, options: LookupOptions) -> (any Decl)? {
        return nil
    }

    public var otherModules: [ModuleDecl] {
        return []
    }

    public func findInSources(name: String, options: LookupOptions) -> (any Decl)? {
        for source in sources {
            if let decl = source.findOwn(name: name, options: options) {
                return decl
            }
        }
        return nil
    }
}
