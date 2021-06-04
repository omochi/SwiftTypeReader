public struct StoredProperty {
    public init(
        name: String,
        unresolvedType: UnresolvedType
    ) {
        self.name = name
        self.unresolvedType = .unresolved(unresolvedType)
    }

    public var name: String
    public var type: Type? {
        unresolvedType.resolved()
    }

    public var unresolvedType: Resolvable<UnresolvedType>
}
