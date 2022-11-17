public struct AnyTypeRepr: Hashable {
    public init(_ value: some TypeRepr) {
        self.value = value
    }

    public var value: any TypeRepr

    public static func ==(a: AnyTypeRepr, b: AnyTypeRepr) -> Bool {
        AnyKey(a.value) == AnyKey(b.value)
    }

    public func hash(into hasher: inout Hasher) {
        AnyKey(value).hash(into: &hasher)
    }

    public var description: String {
        value.description
    }
}
