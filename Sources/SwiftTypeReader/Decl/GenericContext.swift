public protocol GenericContext: DeclContext {
    var syntaxGenericParams: GenericParamList { get }
}

extension GenericContext {
    public var genericParams: GenericParamList {
        do {
            return try rootContext.evaluator(
                GenericParamsRequest(context: self)
            )
        } catch {
            return GenericParamList()
        }
    }
}
