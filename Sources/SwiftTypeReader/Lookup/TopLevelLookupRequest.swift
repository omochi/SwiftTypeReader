struct TopLevelLookupRequest: Request {
    var source: SourceFileDecl
    var name: String
    var options: LookupOptions

    func evaluate(on evaluator: RequestEvaluator) throws -> (any Decl)? {
        var visibleModules: [ModuleDecl] = []

        visibleModules.append(source.module)
        if let decl = source.module.findInSources(name: name, options: options) {
            return decl
        }

        let root = source.rootContext

        for imp in source.imports {
            if let module = root.getModule(name: imp.name) {
                visibleModules.append(module)
                if let decl = module.findInSources(name: name, options: options) {
                    return decl
                }
            }
        }

        for moduleName in source.rootContext.implicitImportModuleNames {
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
