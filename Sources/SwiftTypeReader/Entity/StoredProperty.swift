public struct StoredProperty {
    public init(
        name: String,
        unresolvedType: UnresolvedType
    ) {
        self.name = name
        self.unresolvedType = .init(unresolved: unresolvedType)
    }

    public var name: String
    public var type: SType {
        unresolvedType.resolved()
    }

    public var unresolvedType: Resolvable<UnresolvedType>
}
