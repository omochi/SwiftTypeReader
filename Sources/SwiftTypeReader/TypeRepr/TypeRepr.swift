public protocol TypeRepr: Hashable & CustomStringConvertible {
}

extension TypeRepr {
    public func resolve(from context: any DeclContext) -> any SType {
        do {
            return try context.rootContext.evaluator(
                TypeResolveRequest(
                    context: context,
                    repr: self
                )
            )
        } catch {
            return ErrorType(repr: self)
        }
    }
}
