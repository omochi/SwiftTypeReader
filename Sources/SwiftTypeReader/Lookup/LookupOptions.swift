public struct LookupOptions: Hashable {
    public init(
        value: Bool,
        type: Bool
    ) {
        self.value = value
        self.type = type
    }

    public var value: Bool
    public var type: Bool
}
