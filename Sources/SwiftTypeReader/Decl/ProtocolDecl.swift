public final class ProtocolDecl: NominalTypeDecl {
    public init(
        context: any DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.inheritedTypeLocs = []
        self.members = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var name: String
    public var syntaxGenericParams: GenericParamList { .init() }
    public var inheritedTypeLocs: [TypeLoc]
    public var members: [any ValueDecl]

    public var associatedTypes: [AssociatedTypeDecl] {
        members.compactMap { $0 as? AssociatedTypeDecl }
    }

    public var typedDeclaredInterfaceType: ProtocolType {
        declaredInterfaceType as! ProtocolType
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = findInNominalTypeDecl(name: name, options: options) {
            return decl
        }
        if options.type {
            if let decl = associatedTypes.first(where: { $0.name == name }) {
                return decl
            }
        }
        return nil
    }

    public func makeNominalDeclaredInterfaceType(
        parent: (any SType)?, genericArgs: [any SType]
    ) -> any NominalType {
        ProtocolType(decl: self)
    }

    public var protocolSelfType: GenericParamType {
        genericParams.items[0].typedDeclaredInterfaceType
    }
}
