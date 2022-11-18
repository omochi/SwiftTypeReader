public protocol TypeDecl: ValueDecl {
    var declaredInterfaceType: any SType2 { get }
}
