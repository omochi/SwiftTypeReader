public final class Context {
    public init() {
        self.evaluator = RequestEvaluator()
        self.modules = []
        self.implicitImportModuleNames = ["Swift"]

        modules.append(
            .swiftStandardLibrary(context: self)
        )
    }

    public let evaluator: RequestEvaluator
    public var modules: [Module]
    public var implicitImportModuleNames: [String]

    public var swiftModule: Module {
        getModule(name: "Swift")!
    }

    public func getModule(name: String) -> Module? {
        modules.first { $0.name == name }
    }

    public func getOrCreateModule(name: String) -> Module {
        if let module = getModule(name: name) {
            return module
        }

        let module = Module(context: self, name: name)
        modules.append(module)
        return module
    }

    public var voidType: StructType {
        (swiftModule.findType(name: "Void") as! StructDecl).typedDeclaredInterfaceType
    }
}
