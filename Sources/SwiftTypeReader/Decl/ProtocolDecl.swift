public final class ProtocolDecl: NominalTypeDecl {
    public init(
        context: some DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.inheritedTypeReprs = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var name: String
    public var genericParams: GenericParamList { GenericParamList() }
    public var inheritedTypeReprs: [any TypeRepr]
    public var types: [any GenericTypeDecl] { [] }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        return nil
    }
}
