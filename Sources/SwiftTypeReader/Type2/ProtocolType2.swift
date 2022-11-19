public struct ProtocolType2: NominalType {
    public init(decl: ProtocolDecl) {
        self.decl = decl
    }

    public var decl: ProtocolDecl
    public var nominalTypeDecl: any NominalTypeDecl { decl }
    public var parent: (any SType2)? { nil }
    @AnyTypeArrayStorage public var genericArgs: [any SType2] = []
}
