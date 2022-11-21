public struct DependentMemberType: SType {
    public init(
        base: any SType,
        decl: AssociatedTypeDecl
    ) {
        self.base = base
        self.decl = decl
    }

    @AnyTypeStorage public var base: any SType
    public var decl: AssociatedTypeDecl
}
