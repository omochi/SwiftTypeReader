public protocol TypeRepr: Hashable & CustomStringConvertible {
    func resolve(from context: any DeclContext) -> any SType2
}

extension TypeRepr {
    public func asAnyTypeRepr() -> AnyTypeRepr {
        AnyTypeRepr(self)
    }
}
