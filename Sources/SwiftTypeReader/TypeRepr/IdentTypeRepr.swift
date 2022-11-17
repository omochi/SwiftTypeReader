public struct IdentTypeRepr: TypeRepr {
    public init(
        name: String,
        genericArgs: [AnyTypeRepr]
    ) {
        self.name = name
        self.genericArgs = genericArgs
    }

    public var name: String
    public var genericArgs: [AnyTypeRepr]

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
