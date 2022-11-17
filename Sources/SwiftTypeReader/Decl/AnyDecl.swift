public struct AnyDecl: Hashable {
    public init(_ value: some Decl) {
        self.value = value
    }

    public var value: any Decl

    public static func ==(a: AnyDecl, b: AnyDecl) -> Bool {
        AnyKey(a.value) == AnyKey(b.value)
    }

    public func hash(into hasher: inout Hasher) {
        AnyKey(value).hash(into: &hasher)
    }
}
