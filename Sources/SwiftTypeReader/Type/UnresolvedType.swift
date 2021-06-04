public struct UnresolvedType: UnresolvedProtocol {
    public typealias ResolvedType = Type

    private unowned let module: Module
    private let specifier: TypeSpecifier

    public init(
        module: Module,
        specifier: TypeSpecifier
    ) {
        self.module = module
        self.specifier = specifier
    }

    public func resolved() -> Type? {
        module.resolveType(specifier: specifier)
    }
}
