public final class EnumDecl: NominalTypeDecl & DeclContext {
    public init(
        context: some DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.genericParams = .init()
        self.caseElements = []
    }

    public unowned var context: any DeclContext
    public var name: String
    public var parentContext: (any DeclContext)? { context }
    public var genericParams: GenericParamList
    public var caseElements: [EnumCaseElementDecl]

    public var declaredInterfaceType: any SType2 {
        EnumType2(
            decl: self,
            genericArgs: genericParams.asDeclaredInterfaceTypeArgs()
        )
    }

    public var interfaceType: any SType2 {
        MetatypeType(instance: declaredInterfaceType)
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if let param = genericParams.find(name: name, options: options) {
            return param
        }
        if options.value {
            if let decl = caseElements.first(where: { $0.name == name }) {
                return decl
            }
        }
        return nil
    }
}
