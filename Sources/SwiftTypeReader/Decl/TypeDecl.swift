public protocol TypeDecl: ValueDecl {
    var declaredInterfaceType: any SType2 { get }
}

extension TypeDecl {
    public var declaredInterfaceType: any SType2 {
        do {
            return try rootContext.evaluator(
                DeclaredInterfaceTypeRequest(decl: self)
            )
        } catch {
            return ErrorType(error: error)
        }
    }
}
