public protocol NominalType: SType2 {
    var nominalTypeDecl: any NominalTypeDecl { get }
    var genericArgs: [any SType2] { get set }
}

extension NominalType {
    public var name: String {
        nominalTypeDecl.name
    }
}
