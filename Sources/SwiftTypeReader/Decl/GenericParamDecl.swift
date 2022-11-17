public final class GenericParamDecl: TypeDecl {
    public init(
        context: some DeclContext,
        name: String
    ) {
        self._context = context
        self.name = name
    }

    public unowned var _context: any DeclContext
    public var name: String
    public var context: (any DeclContext)? { _context }

    public var interfaceType: any SType2 {
        GenericParamType2(decl: self)
    }
}
