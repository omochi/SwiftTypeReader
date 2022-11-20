public protocol ValueDecl: Decl {
    var valueName: String? { get }
}

extension ValueDecl {
    public var interfaceType: any SType {
        do {
            return try rootContext.evaluator(
                InterfaceTypeRequest(decl: self)
            )
        } catch {
            return ErrorType(error: error)
        }
    }
}
