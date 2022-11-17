public final class Context {
    public init() {
        self.evaluator = RequestEvaluator()
        self.modules = []

        // TODO
//        modules.append(
//            .swiftStandardLibrary(context: self)
//        )

        self.implicitImportModuleNames = ["Swift"]
    }

    let evaluator: RequestEvaluator
    public var modules: [ModuleDecl]
    public var implicitImportModuleNames: [String]

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

}
