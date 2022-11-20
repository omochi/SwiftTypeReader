public final class FuncDecl: ValueDecl & DeclContext {
    public init(
        context: any DeclContext,
        modifiers: [DeclModifier],
        name: String
    ) {
        self.context = context
        self.modifiers = modifiers
        self.name = name
        self.parameters = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var modifiers: [DeclModifier]
    public var name: String
    public var valueName: String? { name }

    public var parameters: [ParamDecl]
    @AnyTypeReprOptionalStorage public var resultTypeRepr: (any TypeRepr)?

    public var resultInterfaceType: any SType {
        guard let repr = resultTypeRepr else {
            return rootContext.voidType
        }
        return repr.resolve(from: self)
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.value {
            if let decl = parameters.first(where: { $0.name == name }) {
                return decl
            }
        }

        return nil
    }
}
