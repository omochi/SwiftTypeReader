public struct UnresolvedType: UnresolvedProtocol {
    public typealias ResolvedType = Type

    private unowned let module: Module
    public var specifier: TypeSpecifier

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

    public var name: String {
        specifier.name
    }

    public var genericArguments: [Type] {
        get {
            specifier.genericArguments.map { (arg) in
                module.resolveType(specifier: arg)
            }
        }
        set {
            specifier.genericArguments = newValue.map { $0.asSpecifier() }
        }
    }
}
