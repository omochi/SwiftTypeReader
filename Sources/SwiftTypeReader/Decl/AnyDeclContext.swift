public struct AnyDeclContext: Hashable {
    public init(_ value: some DeclContext) {
        self.value = value
    }

    public var value: any DeclContext

    public static func ==(a: AnyDeclContext, b: AnyDeclContext) -> Bool {
        AnyKey(a.value) == AnyKey(b.value)
    }

    public func hash(into hasher: inout Hasher) {
        AnyKey(value).hash(into: &hasher)
    }
}
