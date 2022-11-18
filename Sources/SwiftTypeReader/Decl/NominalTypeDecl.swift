public protocol NominalTypeDecl: GenericTypeDecl {
    var name: String { get }
}

extension NominalTypeDecl {
    public var valueName: String? { name }
}
