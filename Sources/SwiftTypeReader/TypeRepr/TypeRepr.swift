public protocol TypeRepr: Hashable & CustomStringConvertible {
    var switcher: TypeReprSwitcher { get }
}

extension TypeRepr {
    public func resolve(from context: some DeclContext) -> any SType2 {
        do {
            return try context.rootContext.evaluator(
                TypeResolveRequest(
                    context: context,
                    repr: self
                )
            )
        } catch {
            return UnknownType(repr: self)
        }
    }
}
