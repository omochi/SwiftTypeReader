public final class Context {
    public init() {
        self.evaluator = RequestEvaluator()
        self.modules = []
        self.implicitImportModuleNames = ["Swift"]

        modules.append(
            .swiftStandardLibrary(context: self)
        )
    }

    let evaluator: RequestEvaluator
    public var modules: [ModuleDecl]
    public var implicitImportModuleNames: [String]

    public var swiftModule: ModuleDecl {
        getModule(name: "Swift")!
    }

    public func getModule(name: String) -> ModuleDecl? {
        modules.first { $0.name == name }
    }

    public func getOrCreateModule(name: String) -> ModuleDecl {
        if let module = getModule(name: name) {
            return module
        }

        let module = ModuleDecl(context: self, name: name)
        modules.append(module)
        return module
    }

    public func resolve(location: Location) -> Element? {
        return LocationResolver(context: self)
            .resolve(module: nil, location: location)
    }

    public var voidType: StructType2 {
        (swiftModule.findType(name: "Void") as! StructDecl).typedDeclaredInterfaceType
    }
}
