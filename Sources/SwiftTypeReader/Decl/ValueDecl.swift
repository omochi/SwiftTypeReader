public protocol ValueDecl: Decl {
    var valueName: String? { get }

    var interfaceType: any SType2 { get }
}
