public struct GenericParamType: SType {
    public init(
        decl: GenericParamDecl
    ) {
        self.decl = decl
    }

    public var decl: GenericParamDecl

    public var name: String { decl.name }
}

public struct CanGenericParamType: SType {
    public init(depth: Int, index: Int) {
        self.depth = depth
        self.index = index
    }
    
    public var depth: Int
    public var index: Int

    public var description: String {
        return "τ_\(depth)_\(index)"
    }
}
