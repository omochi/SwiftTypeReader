public protocol TypeDecl: ValueDecl {
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
