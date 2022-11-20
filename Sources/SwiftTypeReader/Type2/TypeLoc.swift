public struct TypeLoc {
    public init(
        type: (any SType2)? = nil,
        repr: (any TypeRepr)? = nil
    ) {
        precondition(type != nil || repr != nil)

        self.type = type
        self.repr = repr
    }

    public var type: (any SType2)?
    public var repr: (any TypeRepr)?

    public func resolve(from context: any DeclContext) -> any SType2 {
        if let type { return type }
        if let repr { return repr.resolve(from: context) }
        preconditionFailure()
    }
}
