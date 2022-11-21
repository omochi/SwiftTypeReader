public struct ProtocolType: NominalType {
    public init(decl: ProtocolDecl) {
        self.decl = decl
    }

    public var decl: ProtocolDecl
    public var nominalTypeDecl: any NominalTypeDecl { decl }
    public var parent: (any SType)? { nil }
    public var genericArgs: [any SType] { [] }
}
