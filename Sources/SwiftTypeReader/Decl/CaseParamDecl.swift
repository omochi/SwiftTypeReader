public final class CaseParamDecl: ValueDecl {
    public init(
        context: any DeclContext,
        syntaxOuterName: String?,
        syntaxName: String?,
        typeRepr: any TypeRepr
    ) {
        self.context = context
        self.syntaxOuterName = syntaxOuterName
        self.syntaxName = syntaxName
        self.typeRepr = typeRepr
    }
    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }

    public var syntaxOuterName: String?
    public var syntaxName: String?
    public var valueName: String? { name }

    public var outerName: String? {
        if syntaxOuterName == "_" {
            return nil
        }
        return syntaxOuterName
    }

    public var name: String? {
        if syntaxName == "_" {
            return nil
        }
        return syntaxName
    }

    public var interfaceName: String? {
        let interfaceName = syntaxOuterName ?? syntaxName
        if interfaceName == "_" {
            return nil
        }
        return interfaceName
    }

    public var typeRepr: any TypeRepr
}

extension [CaseParamDecl] {
    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.value {
            if let param = self.first(where: { $0.name == name }) {
                return param
            }
        }
        return nil
    }
}
