public struct MetatypeTypeRepr: TypeRepr {
    public init(instance: any TypeRepr) {
        self.instance = instance
    }

    @AnyTypeReprStorage public var instance: any TypeRepr

    public var description: String {
        var s = instance.description
        s += ".Type"
        return s
    }
}
