open class TypeTransformer {
    public func walk(_ type: any SType) -> any SType {
        return dispatch(type: type)
    }

    private func walk(_ type: (any SType)?) -> (any SType)? {
        guard let type else { return nil }
        return walk(type)
    }

    private func walk(_ types: [any SType]) -> [any SType] {
        return types.map { walk($0) }
    }

    // @codegen(dispatch)
    private func dispatch(type: any SType) -> any SType {
        switch type {
        case let t as DependentMemberType: return visitImpl(dependentMember: t)
        case let t as EnumType: return visitImpl(enum: t)
        case let t as ErrorType: return visitImpl(error: t)
        case let t as FunctionType: return visitImpl(function: t)
        case let t as GenericParamType: return visitImpl(genericParam: t)
        case let t as MetatypeType: return visitImpl(metatype: t)
        case let t as ModuleType: return visitImpl(module: t)
        case let t as ProtocolType: return visitImpl(protocol: t)
        case let t as StructType: return visitImpl(struct: t)
        case let t as TypeAliasType: return visitImpl(typeAlias: t)
        default: return type
        }
    }
    // @end

    // @codegen(visit)
    open func visit(dependentMember type: DependentMemberType) -> (any SType)? { nil }
    open func visit(enum type: EnumType) -> (any SType)? { nil }
    open func visit(error type: ErrorType) -> (any SType)? { nil }
    open func visit(function type: FunctionType) -> (any SType)? { nil }
    open func visit(genericParam type: GenericParamType) -> (any SType)? { nil }
    open func visit(metatype type: MetatypeType) -> (any SType)? { nil }
    open func visit(module type: ModuleType) -> (any SType)? { nil }
    open func visit(protocol type: ProtocolType) -> (any SType)? { nil }
    open func visit(struct type: StructType) -> (any SType)? { nil }
    open func visit(typeAlias type: TypeAliasType) -> (any SType)? { nil }
    // @end

    private func visitImpl(dependentMember type: DependentMemberType) -> any SType {
        if let t = visit(dependentMember: type) { return t }
        let base = walk(type.base)
        return DependentMemberType(base: base, decl: type.decl)
    }

    private func visitImpl(enum type: EnumType) -> any SType {
        if let t = visit(enum: type) { return t }
        let parent = walk(type.parent)
        let args = walk(type.genericArgs)
        return EnumType(decl: type.decl, parent: parent, genericArgs: args)
    }

    private func visitImpl(error type: ErrorType) -> any SType {
        if let t = visit(error: type) { return t }
        return type
    }

    private func visitImpl(function type: FunctionType) -> any SType {
        if let t = visit(function: type) { return t }
        let params = visitImpl(params: type.params)
        let result = walk(type.result)
        return FunctionType(attributes: type.attributes, params: params, result: result)
    }

    private func visitImpl(param: FunctionType.Param) -> FunctionType.Param {
        let type = walk(param.type)
        return FunctionType.Param(attributes: param.attributes, type: type)
    }

    private func visitImpl(params: [FunctionType.Param]) -> [FunctionType.Param] {
        return params.map { visitImpl(param: $0) }
    }

    private func visitImpl(genericParam type: GenericParamType) -> any SType {
        if let t = visit(genericParam: type) { return t }
        return type
    }

    private func visitImpl(metatype type: MetatypeType) -> any SType {
        if let t = visit(metatype: type) { return t }
        let instance = walk(type.instance)
        return MetatypeType(instance: instance)
    }

    private func visitImpl(module type: ModuleType) -> any SType {
        if let t = visit(module: type) { return t }
        return type
    }

    private func visitImpl(protocol type: ProtocolType) -> any SType {
        if let t = visit(protocol: type) { return t }
        return type
    }

    private func visitImpl(struct type: StructType) -> any SType {
        if let t = visit(struct: type) { return t }
        let parent = walk(type.parent)
        let args = walk(type.genericArgs)
        return StructType(decl: type.decl, parent: parent, genericArgs: args)
    }

    private func visitImpl(typeAlias type: TypeAliasType) -> any SType {
        if let t = visit(typeAlias: type) { return t }
        let parent = walk(type.parent)
        let args = walk(type.genericArgs)
        return TypeAliasType(decl: type.decl, parent: parent, genericArgs: args)
    }
}
