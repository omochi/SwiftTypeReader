struct GenericParamsRequest: Request {
    @AnyDeclContextStorage var context: any DeclContext

    func evaluate(on evaluator: RequestEvaluator) throws -> GenericParamList {
        let context = self.context as! any GenericContext

        switch context {
        case let `protocol` as ProtocolDecl:
            let paramDecl = GenericParamDecl(
                context: `protocol`, name: "Self"
            )

            paramDecl.inheritedTypeReprs = [
                IdentTypeRepr(name: `protocol`.name)
            ]

            return GenericParamList([paramDecl])
        default: break
        }

        return context.syntaxGenericParams
    }
}
