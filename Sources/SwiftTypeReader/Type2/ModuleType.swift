public struct ModuleType: SType2 {
    public init(decl: ModuleDecl) {
        self.decl = decl
    }

    public var decl: ModuleDecl

    public var name: String { decl.name }
}
