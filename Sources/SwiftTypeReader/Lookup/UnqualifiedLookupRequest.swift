struct UnqualifiedLookupRequest: Request {
    var context: AnyDeclContext
    var name: String
    var options: LookupOptions

    func evaluate(on evaluator: RequestEvaluator) throws -> (any Decl)? {
        fatalError()
    }
}
