public struct IdentTypeRepr: TypeRepr {
    public init(
        name: String,
        genericArgs: [any TypeRepr] = []
    ) {
        self.name = name
        self.genericArgs = genericArgs
    }

    public var name: String
    @AnyTypeReprArrayStorage public var genericArgs: [any TypeRepr]

    public var description: String {
        var s = name
        s += Printer.genericClause(
            genericArgs.map { $0.description }
        )
        return s
    }
}
