public final class ModuleDecl: ValueDecl & DeclContext {
    public init(
        context: Context,
        name: String
    ) {
        self._context = context
        self.name = name
        self.sources = []
    }

    public unowned var _context: Context
    public var name: String
    public var context: DeclContext? { nil }

    public var sources: [SourceFileDecl]

    public var interfaceType: any SType2 {
        ModuleType(decl: self)
    }
}
