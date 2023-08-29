public struct CompositionTypeRepr: TypeRepr {
    public init(
        elements: [any TypeRepr]
    ) {
        self.elements = elements
    }

    @AnyTypeReprArrayStorage public var elements: [any TypeRepr]

    public var description: String {
        return elements.map { $0.description }.joined(separator: " & ")
    }
}
