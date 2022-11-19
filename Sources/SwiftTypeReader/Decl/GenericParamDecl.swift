public final class GenericParamDecl: TypeDecl {
    public init(
        context: some DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
    }

    public unowned var context: any DeclContext
    public var name: String
    public var valueName: String? { name }
    public var parentContext: (any DeclContext)? { context }

    public var typedDeclaredInterfaceType: GenericParamType2 {
        GenericParamType2(decl: self)
    }
}
