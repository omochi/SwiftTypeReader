public struct TupleTypeRepr: TypeRepr {
    public init(
        elements: [any TypeRepr]
    ) {
        self.elements = elements
    }

    @AnyTypeReprArrayStorage public var elements: [any TypeRepr]

    public var description: String {
        var s = "("
        s += elements.map { $0.description }.joined(separator: ", ")
        s += ")"
        return s
    }
}
