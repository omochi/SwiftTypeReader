public final class ImportDecl: Decl {
    public init(
        source: SourceFile,
        moduleName: String,
        declName: String?
    ) {
        self.source = source
        self.moduleName = moduleName
        self.declName = declName
    }

    public unowned var source: SourceFile
    public var parentContext: (any DeclContext)? { source }
    public var moduleName: String
    public var declName: String?
}
