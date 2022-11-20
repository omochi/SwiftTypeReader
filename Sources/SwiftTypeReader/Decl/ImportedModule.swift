public struct ImportedModule {
    public init(
        module: Module,
        declName: String? = nil
    ) {
        self.module = module
        self.declName = declName
    }

    public var module: Module
    public var declName: String?
}
