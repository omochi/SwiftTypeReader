public final class ProtocolDecl: NominalTypeDecl {
    public init(
        context: any DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.inheritedTypeLocs = []
        self.associatedTypes = []
        self.propertyRequirements = []
        self.functionRequirements = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var name: String
    public var syntaxGenericParams: GenericParamList { .init() }
    public var inheritedTypeLocs: [TypeLoc]
    public var associatedTypes: [AssociatedTypeDecl]
    public var types: [any GenericTypeDecl] { [] }
    public var propertyRequirements: [VarDecl]
    public var functionRequirements: [FuncDecl]

    public var typedDeclaredInterfaceType: ProtocolType2 {
        declaredInterfaceType as! ProtocolType2
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = genericParams.find(name: name, options: options) {
            return decl
        }
        if options.type {
            if let decl = associatedTypes.first(where: { $0.name == name }) {
                return decl
            }
        }
        if options.value {
            if let decl = propertyRequirements.first(where: { $0.name == name }) {
                return decl
            }
            if let decl = functionRequirements.first(where: { $0.name == name }) {
                return decl
            }
        }
        return nil
    }

    public func makeNominalDeclaredInterfaceType(
        parent: (any SType2)?, genericArgs: [any SType2]
    ) -> any NominalType {
        ProtocolType2(decl: self)
    }

    public var protocolSelfType: GenericParamType2 {
        genericParams.items[0].typedDeclaredInterfaceType
    }
}
