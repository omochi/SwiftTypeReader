public struct TypeAliasType: SType {
    public init(
        decl: TypeAliasDecl,
        parent: (any SType)? = nil,
        genericArgs: [any SType] = []
    ) {
        self.decl = decl
        self.parent = parent
        self.genericArgs = genericArgs
    }

    public var decl: TypeAliasDecl
    @AnyTypeOptionalStorage public var parent: (any SType)?
    @AnyTypeArrayStorage public var genericArgs: [any SType]

    public var name: String {
        decl.name
    }
}
