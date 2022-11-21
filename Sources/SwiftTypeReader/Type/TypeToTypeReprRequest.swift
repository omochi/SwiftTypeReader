struct TypeToTypeReprImpl {
    var type: any SType
    var containsModule: Bool

    func convert() throws -> any TypeRepr {
        switch type {
        case let type as ErrorType:
            if let repr = type.repr {
                return repr
            }
            return ErrorTypeRepr(text: type.description)
        case let type as GenericParamType:
            return IdentTypeRepr(name: type.name)
        case let type as MetatypeType:
            return MetatypeTypeRepr(
                instance: type.instance.toTypeRepr(containsModule: containsModule)
            )
        case let type as ModuleType:
            return IdentTypeRepr(name: type.name)
        case let type as DependentMemberType:
            guard var repr = type.base.toTypeRepr(
                containsModule: containsModule
            ) as? IdentTypeRepr else {
                throw MessageError("invalid base repr")
            }
            let name = type.decl.name
            repr.elements.append(.init(name: name))
            return repr
        case let type as FunctionType:
            return convert(function: type)
        case let type as any NominalType:
            return convert(nominal: type)
        default:
            throw MessageError("unimplemented")
        }
    }

    private func convert(function: FunctionType) -> FunctionTypeRepr {
        return FunctionTypeRepr(
            params: convertParams(params: function.params),
            hasAsync: function.attributes.contains(.async),
            hasThrows: function.attributes.contains(.throws),
            result: function.result.toTypeRepr(containsModule: containsModule)
        )
    }

    private func convertParams(params: [FunctionType.Param]) -> TupleTypeRepr {
        return TupleTypeRepr(
            elements: params.map { (param) in
                convertParam(param: param)
            }
        )
    }

    private func convertParam(param: FunctionType.Param) -> any TypeRepr {
        return param.type.toTypeRepr(containsModule: containsModule)
    }

    private func convert(nominal: any NominalType) -> IdentTypeRepr {
        var reversedElements: [IdentTypeRepr.Element] = []

        reversedElements.append(
            makeElement(type: nominal)
        )

        var nextParent = nominal.parent
        while let parent = nextParent as? any NominalType {
            reversedElements.append(
                makeElement(type: parent)
            )
            nextParent = parent.parent
        }

        if containsModule {
            reversedElements.append(
                .init(name: nominal.nominalTypeDecl.moduleContext.name)
            )
        }

        return IdentTypeRepr(reversedElements.reversed())
    }

    private func makeElement(type: any NominalType) -> IdentTypeRepr.Element {
        return .init(
            name: type.name,
            genericArgs: type.genericArgs.map { (arg) in
                arg.toTypeRepr(containsModule: containsModule)
            }
        )
    }
}
