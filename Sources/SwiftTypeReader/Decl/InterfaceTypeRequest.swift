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
            let instance = try declaredInterfaceType(decl: decl)
            return MetatypeType(instance: instance)
        default: break
        }
        throw MessageError("invalid decl: \(decl)")
    }

    private func declaredInterfaceType(decl: any TypeDecl) throws -> any SType2 {
        switch decl {
        case let decl as any NominalTypeDecl:
            var parent: (any SType2)? = nil
            if let parentDecl = decl.parentContext as? any TypeDecl {
                parent = parentDecl.declaredInterfaceType
            }

            let genericArgs = decl.genericParams.asDeclaredInterfaceTypeArgs()
            return decl.makeNominalDeclaredInterfaceType(
                parent: parent,
                genericArgs: genericArgs
            )
        case let decl as GenericParamDecl:
            return GenericParamType2(decl: decl)
        default:
            throw MessageError("invalid decl: \(decl)")
        }
    }
}
