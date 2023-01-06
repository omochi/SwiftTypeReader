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
        case let decl as InitDecl:
            return try initilizerType(init: decl)
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
        return FunctionType(
            attributes: funcDecl.modifiers.asFunctionAttributes,
            params: funcDecl.parameters.asFunctionTypeParams,
            result: funcDecl.resultInterfaceType
        )
    }

    private func initilizerType(init initDecl: InitDecl) throws -> FunctionType {
        guard let selfType = initDecl.parentContext?.selfInterfaceType else {
            throw MessageError("Self type not found")
        }

        return FunctionType(
            attributes: initDecl.modifiers.asFunctionAttributes,
            params: initDecl.parameters.asFunctionTypeParams,
            result: selfType
        )
    }

    private func declaredInterfaceType(type: any TypeDecl) throws -> any SType {
        switch type {
        case let decl as any GenericTypeDecl:
            var parent: (any SType)? = nil
            if let parentDecl = decl.parentContext as? any TypeDecl {
                parent = parentDecl.declaredInterfaceType
            }

            let genericArgs = decl.genericParams.genericParamTypes

            switch decl {
            case let decl as any NominalTypeDecl:
                return decl.makeNominalDeclaredInterfaceType(
                    parent: parent,
                    genericArgs: genericArgs
                )
            case let decl as TypeAliasDecl:
                return decl.makeDeclaredInterfaceType(
                    parent: parent,
                    genericArgs: genericArgs
                )
            default: break
            }
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
        default: break
        }
        throw MessageError("unsupported decl: \(type)")
    }
}

extension [DeclModifier] {
    fileprivate var asFunctionAttributes: [FunctionAttribute] {
        var attributes: [FunctionAttribute] = []
        if contains(.async) {
            attributes.append(.async)
        }
        if contains(.throws) {
            attributes.append(.throws)
        }
        return attributes
    }
}

extension [ParamDecl] {
    fileprivate var asFunctionTypeParams: [FunctionType.Param] {
        map { (param) in
            let type = param.interfaceType
            return FunctionType.Param(attributes: [], type: type)
        }
    }
}
