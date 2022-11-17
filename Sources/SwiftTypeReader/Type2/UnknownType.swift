public struct UnknownType: SType2 {
    public init(repr: some TypeRepr) {
        self.repr = repr.asAnyTypeRepr()
    }

    public var repr: AnyTypeRepr

    public var description: String {
        repr.description
    }
}
