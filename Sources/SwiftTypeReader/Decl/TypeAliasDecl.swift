public final class TypeAliasDecl: GenericTypeDecl {
    public init(
        context: any DeclContext,
        name: String,
        underlyingTypeRepr: any TypeRepr
    ) {
        self.context = context
        self.attributes = []
        self.modifiers = []
        self.name = name
        self.syntaxGenericParams = .init()
        self.underlyingTypeRepr = underlyingTypeRepr
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var attributes: [Attribute]
    public var modifiers: [DeclModifier]
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

    public func makeDeclaredInterfaceType(
        parent: (any SType)?, genericArgs: [any SType]
    ) -> TypeAliasType {
        TypeAliasType(decl: self, parent: parent, genericArgs: genericArgs)
    }

    public var underlyingType: any SType {
        return try! rootContext.evaluator(
            TypeAliasDeclUnderlyingTypeRequest(decl: self)
        )
    }
}


struct TypeAliasDeclUnderlyingTypeRequest: Request {
    var decl: TypeAliasDecl

    func evaluate(on evaluator: RequestEvaluator) -> any SType {
        return decl.underlyingTypeRepr.resolve(from: decl)
    }
}
