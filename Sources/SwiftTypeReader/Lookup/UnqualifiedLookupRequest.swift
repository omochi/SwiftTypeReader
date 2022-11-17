struct UnqualifiedLookupRequest: Request {
    var context: AnyDeclContext
    var name: String
    var options: LookupOptions

    func evaluate(on evaluator: RequestEvaluator) throws -> (any Decl)? {
        var context = context
        
        while true {
            switch context.value {
            case let module as ModuleDecl:
                return try evaluator(
                    TopLevelLookupRequest(
                        module: module,
                        name: name,
                        options: options
                    )
                )
            case let source as SourceFileDecl:
                return try evaluator(
                    TopLevelLookupRequest(
                        source: source,
                        name: name,
                        options: options
                    )
                )
            default: break
            }
            
            if let decl = context.value.findOwn(name: name, options: options) {
                return decl
            }
            
            guard let parent = context.value.context else {
                return nil
            }
            
            context = parent.asAnyDeclContext()
        }
    }
}
