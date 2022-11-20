struct GenericParamsRequest: Request {
    @AnyDeclContextStorage var context: any DeclContext

    func evaluate(on evaluator: RequestEvaluator) throws -> GenericParamList {
        let context = self.context as! any GenericContext

        switch context {
        case let `protocol` as ProtocolDecl:
            let paramDecl = GenericParamDecl(
                context: `protocol`, name: "Self"
            )

            paramDecl.inheritedTypeLocs = [
                TypeLoc(type: `protocol`.declaredInterfaceType)
            ]

            return GenericParamList([paramDecl])
        default: break
        }

        return context.syntaxGenericParams
    }
}
