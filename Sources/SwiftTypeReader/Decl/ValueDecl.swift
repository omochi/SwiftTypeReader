public protocol ValueDecl: Decl {
    var valueName: String? { get }

    var interfaceType: any SType2 { get }
}

extension ValueDecl {
    public var interfaceType: any SType2 {
        do {
            return try rootContext.evaluator(
                InterfaceTypeRequest(decl: self)
            )
        } catch {
            return ErrorType(error: error)
        }
    }
}
