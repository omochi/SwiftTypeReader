public final class EnumDecl: NominalTypeDecl {
    public init(
        context: any DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.syntaxGenericParams = .init()
        self.inheritedTypeLocs = []
        self.types = []
        self.caseElements = []
    }

    public unowned var context: any DeclContext
    public var name: String
    public var parentContext: (any DeclContext)? { context }
    public var syntaxGenericParams: GenericParamList
    public var inheritedTypeLocs: [TypeLoc]
    public var types: [any GenericTypeDecl]
    public var caseElements: [EnumCaseElementDecl]

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
