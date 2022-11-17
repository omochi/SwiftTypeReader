public struct AnyType: Hashable {
    public init(_ value: some SType2) {
        self.value = value
    }

    public var value: any SType2

    public static func ==(a: AnyType, b: AnyType) -> Bool {
        AnyKey(a.value) == AnyKey(b.value)
    }

    public func hash(into hasher: inout Hasher) {
        AnyKey(value).hash(into: &hasher)
    }

    public var description: String {
        value.description
    }
}
