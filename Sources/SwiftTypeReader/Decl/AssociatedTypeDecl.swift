public final class AssociatedTypeDecl: TypeDecl {
    public init(
        `protocol`: ProtocolDecl,
        name: String
    ) {
        self.protocol = `protocol`
        self.name = name
        self.inheritedTypeLocs = []
    }

    public unowned var `protocol`: ProtocolDecl
    public var parentContext: (any DeclContext)? { `protocol` }

    public var name: String
    public var valueName: String? { name }

    public var inheritedTypeLocs: [TypeLoc]
}
