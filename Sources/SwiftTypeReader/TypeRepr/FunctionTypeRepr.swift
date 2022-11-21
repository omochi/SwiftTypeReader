public struct FunctionTypeRepr: TypeRepr {
    public init(
        params: TupleTypeRepr,
        hasAsync: Bool,
        hasThrows: Bool,
        result: any TypeRepr
    ) {
        self.params = params
        self.hasAsync = hasAsync
        self.hasThrows = hasThrows
        self.result = result
    }

    public var params: TupleTypeRepr
    public var hasAsync: Bool
    public var hasThrows: Bool
    @AnyTypeReprStorage public var result: any TypeRepr

    public var description: String {
        var s = params.description
        if hasAsync {
            s += " async"
        }
        if hasThrows {
            s += " throws"
        }
        s += " -> "
        s += result.description
        return s
    }
}
