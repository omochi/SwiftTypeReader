public struct AssociatedValue {
    public init(
        name: String?,
        typeSpecifier: TypeSpecifier
    ) {
        self.name = name
        self.unresolvedType = .unresolved(typeSpecifier)
    }

    public var name: String?
    
    public func type() -> SType {
        unresolvedType.resolved()
    }

    public var unresolvedType: SType
}
