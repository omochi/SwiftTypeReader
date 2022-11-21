struct InterfaceTypeRequest: Request {
    @AnyDeclStorage var decl: any Decl

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType {
        switch decl {
        case is EnumCaseElementDecl,
            is AccessorDecl:
            // FIXME: unimplemented
            throw MessageError("unimplemented")
        case let decl as Module:
            return ModuleType(decl: decl)
        case let decl as VarDecl:
            return decl.typeRepr.resolve(from: decl.context)
        case let decl as ParamDecl:
            return decl.typeRepr.resolve(from: decl.context)
        case let decl as FuncDecl:
            return functionType(func: decl)
        case let decl as any TypeDecl:
            let instance = try declaredInterfaceType(type: decl)
            return MetatypeType(instance: instance)
        default: break
        }
        throw MessageError("invalid decl: \(decl)")
    }

    private func functionType(func funcDecl: FuncDecl) -> FunctionType {
        var function = functionBodyType(func: funcDecl)

        if let selfType = funcDecl.parentContext?.selfInterfaceType {
            let selfParam = FunctionType.Param(attributes: [], type: selfType)
            function = FunctionType(
                attributes: [],
                params: [selfParam],
                result: function
            )
        }

        return function
    }

    private func functionBodyType(func funcDecl: FuncDecl) -> FunctionType {
        let params: [FunctionType.Param] = funcDecl.parameters.map { (param) in
            let type = param.interfaceType
            return FunctionType.Param(attributes: [], type: type)
        }
        let result = funcDecl.resultInterfaceType

        var attributes: [FunctionAttribute] = []
        if funcDecl.modifiers.contains(.async) {
            attributes.append(.async)
        }
        if funcDecl.modifiers.contains(.throws) {
            attributes.append(.throws)
        }

        return FunctionType(
            attributes: attributes,
            params: params,
            result: result
        )
    }

    private func declaredInterfaceType(type: any TypeDecl) throws -> any SType {
        switch type {
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
            throw MessageError("invalid decl: \(type)")
        }
    }
}
