public final class EnumDecl: NominalTypeDecl {
    public init(
        context: some DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.genericParams = .init()
        self.inheritedTypeReprs = []
        self.types = []
        self.caseElements = []
    }

    public unowned var context: any DeclContext
    public var name: String
    public var parentContext: (any DeclContext)? { context }
    public var genericParams: GenericParamList
    public var inheritedTypeReprs: [any TypeRepr]
    public var types: [any GenericTypeDecl]
    public var caseElements: [EnumCaseElementDecl]

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = findInNominalTypeDecl(name: name, options: options) {
            return decl
        }
        if options.value {
            if let decl = caseElements.first(where: { $0.name == name }) {
                return decl
            }
        }
        return nil
    }
}
