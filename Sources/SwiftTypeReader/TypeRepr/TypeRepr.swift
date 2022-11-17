public protocol TypeRepr: Hashable & CustomStringConvertible {
    var switcher: TypeReprSwitcher { get }
}

extension TypeRepr {
    public func asAnyTypeRepr() -> AnyTypeRepr {
        AnyTypeRepr(self)
    }

    public func resolve(from context: some DeclContext) -> any SType2 {
        do {
            return try context.rootContext.evaluator(
                TypeResolveRequest(
                    context: context.asAnyDeclContext(),
                    repr: self.asAnyTypeRepr()
                )
            )
        } catch {
            return UnknownType(repr: self)
        }
    }
}
