public final class ParamDecl: ValueDecl {
    public init(
        context: any DeclContext,
        outerName: String?,
        name: String?,
        typeRepr: any TypeRepr
    ) {
        self.context = context
        self.outerName = outerName
        self.name = name
        self.typeRepr = typeRepr
    }
    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }

    public var outerName: String?
    public var name: String?
    public var valueName: String? { name }

    public var interfaceName: String? {
        let interfaceName = outerName ?? name
        if interfaceName == "_" {
            return nil
        }
        return interfaceName
    }

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
