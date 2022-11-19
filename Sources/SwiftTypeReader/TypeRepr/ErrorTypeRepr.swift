public struct ErrorTypeRepr: TypeRepr {
    public init(text: String) {
        self.text = text
    }

    public var text: String

    public var description: String {
        text
    }
}
