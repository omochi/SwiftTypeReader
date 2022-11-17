public struct ChainedTypeRepr: TypeRepr {
    public init(_ items: [IdentTypeRepr]) {
        self.items = items
    }

    public var items: [IdentTypeRepr]

    public var description: String {
        items.map { $0.description }.joined(separator: ".")
    }
}
