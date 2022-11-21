public struct IdentTypeRepr: TypeRepr {
    public struct Element: Hashable {
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

    public init(_ elements: [Element]) {
        self.elements = elements
    }

    public init(_ elements: Element...) {
        self.init(elements)
    }

    public init(
        name: String,
        genericArgs: [any TypeRepr] = []
    ) {
        self.init([
            Element(name: name, genericArgs: genericArgs)
        ])
    }
    
    public var elements: [Element]

    public var description: String {
        elements.map { $0.description }.joined(separator: ".")
    }
}
