public struct ModuleType: SType {
    public init(decl: Module) {
        self.decl = decl
    }

    public var decl: Module

    public var name: String { decl.name }
}
