public protocol GenericTypeDecl: TypeDecl & DeclContext {
    var genericParams: GenericParamList { get }
}
