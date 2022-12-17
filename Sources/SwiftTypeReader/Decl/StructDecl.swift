public final class StructDecl: NominalTypeDecl {
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
    public var parentContext: (any DeclContext)? { context }
    public var name: String
    public var syntaxGenericParams: GenericParamList
    public var inheritedTypeReprs: [any TypeRepr]
    public var members: [any ValueDecl]

    public var storedProperties: [VarDecl] {
        properties.filter { $0.propertyKind == .stored }
    }

    public var computedProperties: [VarDecl] {
        properties.filter { $0.propertyKind == .computed }
    }

    public var typedDeclaredInterfaceType: StructType {
        declaredInterfaceType as! StructType
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
        StructType(decl: self, parent: parent, genericArgs: genericArgs)
    }
}
