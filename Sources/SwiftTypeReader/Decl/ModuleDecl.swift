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
    public var valueName: String? { name }
    public var parentContext: (any DeclContext)? { nil }

    public var sources: [SourceFileDecl]

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

    static func swiftStandardLibrary(context: Context) -> ModuleDecl {
        var builder = StandardLibraryBuilder(context: context)
        return builder.build()
    }
}
