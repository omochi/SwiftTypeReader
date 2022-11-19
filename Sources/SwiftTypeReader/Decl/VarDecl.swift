public final class VarDecl: StorageDecl {
    public init(
        context: any DeclContext,
        name: String,
        typeRepr: any TypeRepr
    ) {
        self.context = context
        self.name = name
        self.typeRepr = typeRepr
    }
    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }

    public var name: String
    public var valueName: String? { name }
    public var typeRepr: any TypeRepr
}
