public struct AssociatedValue {
    public init(
        name: String?,
        typeSpecifier: TypeSpecifier
    ) {
        self.name = name
        self.unresolvedType = .unresolved(typeSpecifier)
    }

    public var name: String?
    
    public func type() throws -> SType {
        try unresolvedType.resolved()
    }

    public var unresolvedType: SType
}
