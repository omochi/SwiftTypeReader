public final class VarDecl: StorageDecl {
    public init(
        context: any DeclContext,
        name: String,
        typeRepr: any TypeRepr
    ) {
        self._context = context
        self.name = name
        self.typeRepr = typeRepr
    }
    public unowned var _context: any DeclContext
    public var context: (any DeclContext)? { _context }

    public var name: String
    public var typeRepr: any TypeRepr

    public var interfaceType: any SType2 {
        get throws {
            try _context.rootContext.evaluator(
                TypeResolveRequest(
                    context: _context.asAnyDeclContext(),
                    repr: typeRepr.asAnyTypeRepr()
                )
            )
        }
    }
}
