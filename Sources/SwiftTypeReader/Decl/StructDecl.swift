public final class StructDecl: NominalTypeDecl {
    public init(
        context: any DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.genericParams = .init()
        self.inheritedTypeReprs = []
        self.types = []
        self.properties = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var name: String
    public var genericParams: GenericParamList
    public var inheritedTypeReprs: [any TypeRepr]
    public var types: [any GenericTypeDecl]
    public var properties: [VarDecl]

    public var storedProperties: [VarDecl] {
        properties.filter { $0.propertyKind == .stored }
    }
    public var computedProperties: [VarDecl] {
        properties.filter { $0.propertyKind == .computed }
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = findInNominalTypeDecl(name: name, options: options) {
            return decl
        }
        if options.value {
            if let decl = properties.first(where: { $0.name == name }) {
                return decl
            }
        }
        return nil
    }

    public func makeNominalDeclaredInterfaceType(
        parent: (any SType2)?, genericArgs: [any SType2]
    ) -> any NominalType {
        StructType2(decl: self, parent: parent, genericArgs: genericArgs)
    }
}
