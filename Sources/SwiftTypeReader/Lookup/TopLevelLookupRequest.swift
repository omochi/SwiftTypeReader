struct TopLevelLookupRequest: Request {
    var source: SourceFileDecl?
    var module: ModuleDecl
    var name: String
    var options: LookupOptions

    init(source: SourceFileDecl, name: String, options: LookupOptions) {
        self.source = source
        self.module = source.module
        self.name = name
        self.options = options
    }

    init(module: ModuleDecl, name: String, options: LookupOptions) {
        self.source = nil
        self.module = module
        self.name = name
        self.options = options
    }

    func evaluate(on evaluator: RequestEvaluator) throws -> (any Decl)? {
        var visibleModules: [ModuleDecl] = []

        visibleModules.append(module)
        if let decl = module.findInSources(name: name, options: options) {
            return decl
        }

        let root = module.rootContext

        if let source = self.source {
            for imp in source.imports {
                if let module = root.getModule(name: imp.name) {
                    visibleModules.append(module)
                    if let decl = module.findInSources(name: name, options: options) {
                        return decl
                    }
                }
            }
        }

        for moduleName in root.implicitImportModuleNames {
            if let module = root.getModule(name: moduleName) {
                visibleModules.append(module)
                if let decl = module.findInSources(name: moduleName, options: options) {
                    return decl
                }
            }
        }

        if let module = visibleModules.first(where: { $0.name == name }) {
            return module
        }

        return nil
    }
}