struct UnqualifiedLookup: Request {
    var context: AnyDeclContext
    var name: String
    var options: LookupOptions

    func evaluate(on evaluator: RequestEvaluator) throws -> any Decl {
        <#code#>
    }
}
