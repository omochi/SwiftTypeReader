public struct GenericParamType2: SType2 {
    public var decl: GenericParamDecl

    public var description: String {
        return decl.name
    }
}

public struct CanGenericParamType: SType2 {
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
