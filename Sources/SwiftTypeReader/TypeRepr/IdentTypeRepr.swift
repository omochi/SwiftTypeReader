public struct IdentTypeRepr: TypeRepr {
    public init(
        name: String,
        genericArgs: [any TypeRepr]
    ) {
        self.name = name
        self.genericArgs = genericArgs
    }

    public var name: String
    @AnyTypeReprArrayStorage public var genericArgs: [any TypeRepr]

    public var description: String {
        var s = name
        if !genericArgs.isEmpty {
            s += "<"
            s += genericArgs.map { $0.description }.joined(separator: ", ")
            s += ">"
        }
        return s
    }

    public var switcher: TypeReprSwitcher { .ident(self) }
}
