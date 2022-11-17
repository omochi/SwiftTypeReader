public struct UnknownType: SType2 {
    public init(repr: some TypeRepr) {
        self.repr = repr
    }

    @AnyTypeReprStorage public var repr: any TypeRepr

    public var description: String {
        repr.description
    }
}
