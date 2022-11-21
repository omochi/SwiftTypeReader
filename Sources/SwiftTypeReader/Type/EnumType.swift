public struct EnumType: NominalType {
    public init(
        decl: EnumDecl,
        parent: (any SType)? = nil,
        genericArgs: [any SType] = []
    ) {
        self.decl = decl
        self.parent = parent
        self.genericArgs = genericArgs
    }

    public var decl: EnumDecl
    public var nominalTypeDecl: any NominalTypeDecl { decl }
    @AnyTypeOptionalStorage public var parent: (any SType)?
    @AnyTypeArrayStorage public var genericArgs: [any SType]
}
