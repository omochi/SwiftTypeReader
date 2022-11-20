public struct DependentMemberType: SType2 {
    public init(
        base: any SType2,
        decl: AssociatedTypeDecl
    ) {
        self.base = base
        self.decl = decl
    }

    @AnyTypeStorage public var base: any SType2
    public var decl: AssociatedTypeDecl
}
