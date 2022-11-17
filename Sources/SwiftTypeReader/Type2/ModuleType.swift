public struct ModuleType: SType2 {
    public var decl: ModuleDecl

    public init(decl: ModuleDecl) {
        self.decl = decl
    }

    public var description: String {
        decl.name
    }
}
