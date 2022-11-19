struct DeclaredInterfaceTypeRequest: Request {
    @AnyDeclStorage var decl: any Decl

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType2 {
        let interfaceType = try evaluator(
            InterfaceTypeRequest(decl: decl)
        )

        switch interfaceType {
        case let metatype as MetatypeType:
            return metatype.instance
        default:
            return interfaceType
        }
    }
}
