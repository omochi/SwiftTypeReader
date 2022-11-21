public struct LookupOptions: Hashable {
    public init(
        value: Bool = true,
        type: Bool = true
    ) {
        self.value = value
        self.type = type
    }

    public var value: Bool
    public var type: Bool
}
