struct TopLevelLookupRequest: Request {
    var source: SourceFile?
    var module: Module
    var name: String
    var options: LookupOptions

    init(source: SourceFile, name: String, options: LookupOptions) {
        self.source = source
        self.module = source.module
        self.name = name
        self.options = options
    }

    init(module: Module, name: String, options: LookupOptions) {
        self.source = nil
        self.module = module
        self.name = name
        self.options = options
    }

    func evaluate(on evaluator: RequestEvaluator) throws -> (any Decl)? {
        let modules = importedModules()

        for module in modules {
            if let decl = find(in: module) {
                return decl
            }
        }

        if let module = modules.first(where: { $0.module.name == name }) {
            return module.module
        }

        return nil
    }

    private func find(in module: ImportedModule) -> (any Decl)? {
        if let declName = module.declName {
            guard declName == name else { return nil }
        }
        return module.module.find(name: name, options: options)
    }

    private func importedModules() -> [ImportedModule] {
        if let source = self.source {
            return source.importedModules
        }
        return module.importedModules
    }

}
