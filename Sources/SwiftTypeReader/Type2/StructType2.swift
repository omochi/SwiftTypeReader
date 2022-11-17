public struct StructType2: SType2 {
    public var decl: StructDecl

    public var description: String {
        // TODO: generic args
        return decl.name
    }
}
