struct GenericSignatureRequest: Request {
    @AnyDeclContextStorage var context: any DeclContext

    func evaluate(on evaluator: RequestEvaluator) throws -> GenericSignature {
        let context = self.context as! any GenericContext
        let paramList = context.genericParams
        let parent = context.parentContext?.contextGenericSignature ?? GenericSignature()
        return build(paramList: paramList, parent: parent)
    }

    private func build(paramList: GenericParamList, parent: GenericSignature) -> GenericSignature {
        var params: [GenericParamType] = parent.params

        for paramDecl in paramList.items {
            let param = paramDecl.typedDeclaredInterfaceType
            params.append(param)
        }

        return GenericSignature(params: params)
    }
}
