public final class InitDecl: ValueDecl & DeclContext {
    public init(
        context: any DeclContext,
        modifiers: [DeclModifier]
    ) {
        self.context = context
        self.modifiers = modifiers
        self.parameters = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var modifiers: [DeclModifier]
    public var valueName: String? { nil }

    public var parameters: [FuncParamDecl]

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.value {
            if let decl = parameters.first(where: { $0.name == name }) {
                return decl
            }
        }

        return nil
    }
}
