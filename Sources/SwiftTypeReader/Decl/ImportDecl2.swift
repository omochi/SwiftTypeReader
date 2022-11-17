public final class ImportDecl2: Decl {
    public init(
        source: SourceFileDecl,
        name: String
    ) {
        self.source = source
        self.name = name
    }

    public unowned var source: SourceFileDecl
    public var name: String
    public var parentContext: (any DeclContext)? { source }
}
