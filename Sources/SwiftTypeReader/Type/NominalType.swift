public protocol NominalType: SType {
    var nominalTypeDecl: any NominalTypeDecl { get }
    var parent: (any SType)? { get }
    var genericArgs: [any SType] { get }
}

extension NominalType {
    public var name: String {
        nominalTypeDecl.name
    }
}
