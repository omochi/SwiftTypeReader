public final class EnumDecl: NominalTypeDecl {
    public init(
        context: any DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.syntaxGenericParams = .init()
        self.inheritedTypeReprs = []
        self.members = []
    }

    public unowned var context: any DeclContext
    public var name: String
    public var parentContext: (any DeclContext)? { context }
    public var syntaxGenericParams: GenericParamList
    public var inheritedTypeReprs: [any TypeRepr]
    public var members: [any ValueDecl]

    public var caseElements: [EnumCaseElementDecl] {
        members.compactMap { $0.asEnumCaseElement }
    }

    public var typedDeclaredInterfaceType: EnumType {
        declaredInterfaceType as! EnumType
    }

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

    public func makeNominalDeclaredInterfaceType(
        parent: (any SType)?, genericArgs: [any SType]
    ) -> any NominalType {
        EnumType(decl: self, parent: parent, genericArgs: genericArgs)
    }
}
