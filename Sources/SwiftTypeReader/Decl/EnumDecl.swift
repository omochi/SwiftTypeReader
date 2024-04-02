public final class EnumDecl: NominalTypeDecl {
    public init(
        context: any DeclContext,
        name: String
    ) {
        self.context = context
        self.comment = ""
        self.modifiers = []
        self.name = name
        self.syntaxGenericParams = .init()
        self.inheritedTypeReprs = []
        self.members = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var comment: String
    public var modifiers: [DeclModifier]
    public var name: String
    public var syntaxGenericParams: GenericParamList
    public var inheritedTypeReprs: [any TypeRepr]
    public var members: [any ValueDecl]

    public var caseElements: [EnumCaseElementDecl] {
        members.compactMap { $0.asEnumCaseElement }
    }

    public var computedProperties: [VarDecl] {
        properties.filter { $0.propertyKind == .computed }
    }

    public var typedDeclaredInterfaceType: EnumType {
        declaredInterfaceType as! EnumType
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = findInNominalTypeDecl(name: name, options: options) {
            return decl
        }
        return nil
    }

    public func makeNominalDeclaredInterfaceType(
        parent: (any SType)?, genericArgs: [any SType]
    ) -> any NominalType {
        EnumType(decl: self, parent: parent, genericArgs: genericArgs)
    }
}
