public protocol NominalType: SType2 {
    var nominalTypeDecl: any NominalTypeDecl { get }
    var parent: (any SType2)? { get }
    var genericArgs: [any SType2] { get }
}

extension NominalType {
    public var name: String {
        nominalTypeDecl.name
    }

    public var description: String {
        toTypeRepr(containsModule: false).description
    }
}
