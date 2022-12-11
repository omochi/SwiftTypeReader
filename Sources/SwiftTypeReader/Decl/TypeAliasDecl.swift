public final class TypeAliasDecl: GenericTypeDecl {
    public init(
        context: any DeclContext,
        name: String,
        underlyingTypeRepr: any TypeRepr
    ) {
        self.context = context
        self.name = name
        self.syntaxGenericParams = .init()
        self.underlyingTypeRepr = underlyingTypeRepr
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var name: String
    public var valueName: String? { name }
    public var syntaxGenericParams: GenericParamList
    public var inheritedTypeReprs: [any TypeRepr] { [] }
    public var underlyingTypeRepr: any TypeRepr

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = findInGenericContext(name: name, options: options) {
            return decl
        }
        return nil
    }
}
