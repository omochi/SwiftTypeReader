struct InterfaceTypeRequest: Request {
    @AnyDeclStorage var decl: any Decl

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType {
        switch decl {
        case is EnumCaseElementDecl,
            is AccessorDecl,
            is FuncDecl:
            // FIXME: unimplemented
            throw MessageError("unimplemented")
        case let decl as Module:
            return ModuleType(decl: decl)
        case let decl as VarDecl:
            return decl.typeRepr.resolve(from: decl.context)
        case let decl as ParamDecl:
            return decl.typeRepr.resolve(from: decl.context)
        case let decl as any TypeDecl:
            let instance = try declaredInterfaceType(decl: decl)
            return MetatypeType(instance: instance)
        default: break
        }
        throw MessageError("invalid decl: \(decl)")
    }

    private func declaredInterfaceType(decl: any TypeDecl) throws -> any SType {
        switch decl {
        case let decl as any NominalTypeDecl:
            var parent: (any SType)? = nil
            if let parentDecl = decl.parentContext as? any TypeDecl {
                parent = parentDecl.declaredInterfaceType
            }

            let genericArgs = decl.genericParams.asDeclaredInterfaceTypeArgs()
            return decl.makeNominalDeclaredInterfaceType(
                parent: parent,
                genericArgs: genericArgs
            )
        case let decl as GenericParamDecl:
            return GenericParamType(decl: decl)
        case let decl as AssociatedTypeDecl:
            guard let selfType = decl.protocol.selfInterfaceType else {
                throw MessageError("no self interface type")
            }
            return DependentMemberType(
                base: selfType,
                decl: decl
            )
        default:
            throw MessageError("invalid decl: \(decl)")
        }
    }
}
