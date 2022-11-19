public struct EnumType2: NominalType {
    public init(
        decl: EnumDecl,
        parent: (any SType2)? = nil,
        genericArgs: [any SType2] = []
    ) {
        self.decl = decl
        self.parent = parent
        self.genericArgs = genericArgs
    }

    public var decl: EnumDecl
    public var nominalTypeDecl: any NominalTypeDecl { decl }
    @AnyTypeOptionalStorage public var parent: (any SType2)?
    @AnyTypeArrayStorage public var genericArgs: [any SType2]
}
