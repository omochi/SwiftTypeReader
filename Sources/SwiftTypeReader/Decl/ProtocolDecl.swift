public final class ProtocolDecl: NominalTypeDecl {
    public init(
        context: any DeclContext,
        name: String
    ) {
        self.context = context
        self.comment = ""
        self.modifiers = []
        self.name = name
        self.inheritedTypeReprs = []
        self.members = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var comment: String
    public var modifiers: [DeclModifier]
    public var name: String
    public var syntaxGenericParams: GenericParamList { .init() }
    public var inheritedTypeReprs: [any TypeRepr]
    public var members: [any ValueDecl]

    public var associatedTypes: [AssociatedTypeDecl] {
        members.compactMap { $0.asAssociatedType }
    }

    public var typedDeclaredInterfaceType: ProtocolType {
        declaredInterfaceType.asProtocol!
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
        ProtocolType(decl: self)
    }

    public var protocolSelfType: GenericParamType {
        genericParams.items[0].typedDeclaredInterfaceType
    }
}
