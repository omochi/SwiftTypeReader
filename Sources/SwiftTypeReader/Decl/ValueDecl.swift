public protocol ValueDecl: Decl {
    var name: String { get }

    var interfaceType: any SType2 { get }
}
