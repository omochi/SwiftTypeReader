struct InterfaceTypeRequest: Request {
    @AnyDeclStorage var decl: any Decl

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType2 {
        switch decl {
        case let decl as ModuleDecl:
            return ModuleType(decl: decl)
        case let decl as VarDecl:
            return decl.typeRepr.resolve(from: decl.context)
        case let decl as ParamDecl:
            return decl.typeRepr.resolve(from: decl.context)
        case is EnumCaseElementDecl:
            // it should be case constructor function type
            throw MessageError("unimplemented")
        case let decl as any TypeDecl:
            let instance = decl.declaredInterfaceType
            return MetatypeType(instance: instance)
        default: break
        }
        throw MessageError("invalid decl: \(decl)")
    }
}
