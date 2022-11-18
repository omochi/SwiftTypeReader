struct UnqualifiedLookupRequest: Request {
    @AnyDeclContextStorage var context: any DeclContext
    var name: String
    var options: LookupOptions

    func evaluate(on evaluator: RequestEvaluator) throws -> (any Decl)? {
        var context: any DeclContext = context
        
        while true {
            switch context {
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
            
            if let decl = context.find(name: name, options: options) {
                return decl
            }
            
            guard let parent = context.parentContext else {
                return nil
            }
            
            context = parent
        }
    }
}
