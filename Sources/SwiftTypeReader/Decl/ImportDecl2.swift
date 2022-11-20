public final class ImportDecl2: Decl {
    public init(
        source: SourceFile,
        name: String
    ) {
        self.source = source
        self.name = name
    }

    public unowned var source: SourceFile
    public var name: String
    public var parentContext: (any DeclContext)? { source }
}
