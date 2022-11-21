public final class ParamDecl: ValueDecl {
    public init(
        context: any DeclContext,
        interfaceName: String?,
        name: String?,
        typeRepr: any TypeRepr
    ) {
        self.context = context
        self.interfaceName = interfaceName
        self.name = name
        self.typeRepr = typeRepr
    }
    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }

    public var interfaceName: String?
    public var name: String?
    public var valueName: String? { name }

    public var argumentName: String? { interfaceName ?? name }

    public var typeRepr: any TypeRepr
}

extension [ParamDecl] {
    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.value {
            if let param = self.first(where: { $0.name == name }) {
                return param
            }
        }
        return nil
    }
}
