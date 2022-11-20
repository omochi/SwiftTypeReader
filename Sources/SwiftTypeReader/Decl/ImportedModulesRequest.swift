struct ImportedModulesRequest: Request {
    var module: Module
    var source: SourceFile?

    func evaluate(on evaluator: RequestEvaluator) throws -> [ImportedModule] {
        let context = module.rootContext

        var modules: [ImportedModule] = [
            ImportedModule(module: module)
        ]

        if let source = self.source {
            for `import` in source.imports {
                if let module = context.getModule(name: `import`.moduleName) {
                    modules.append(
                        ImportedModule(module: module, declName: `import`.declName)
                    )
                }
            }
        }

        for moduleName in context.implicitImportModuleNames {
            if let module = context.getModule(name: moduleName) {
                modules.append(ImportedModule(module: module))
            }
        }

        return modules
    }
}
