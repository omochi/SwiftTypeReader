public struct EnumType2: NominalType {
    public var decl: EnumDecl
    @AnyTypeArrayStorage public var genericArgs: [any SType2]

    public var nominalTypeDecl: any NominalTypeDecl { decl }

    public var description: String {
        var s = decl.name
        s += Printer.genericClause(
            genericArgs.map { $0.description }
        )
        return s
    }
}
