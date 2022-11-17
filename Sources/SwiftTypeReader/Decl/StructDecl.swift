public final class StructDecl: NominalTypeDecl & DeclContext {
    public init(
        context: DeclContext,
        name: String
    ) {
        self._context = context
        self.name = name
        self.genericParams = .init()
    }

    public unowned var _context: DeclContext
    public var name: String
    public var context: (any DeclContext)? { _context }
    public var genericParams: GenericParamList

    public var interfaceType: any SType2 {
        return StructType2(decl: self)
    }
}
