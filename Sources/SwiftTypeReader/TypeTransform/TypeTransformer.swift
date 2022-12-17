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

    private func walk(_ params: [FunctionType.Param]) -> [FunctionType.Param] {
        params.map { walk($0) }
    }

    private func walk(_ param: FunctionType.Param) -> FunctionType.Param {
        var param = param
        param.type = walk(param.type)
        return param
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

    // @codegen(visitImpl)
    private func visitImpl(dependentMember type: DependentMemberType) -> any SType {
        if let t = visit(dependentMember: type) { return t }
        var type = type
        type.base = walk(type.base)
        return type
    }

    private func visitImpl(enum type: EnumType) -> any SType {
        if let t = visit(enum: type) { return t }
        var type = type
        type.parent = walk(type.parent)
        type.genericArgs = walk(type.genericArgs)
        return type
    }

    private func visitImpl(error type: ErrorType) -> any SType {
        if let t = visit(error: type) { return t }
        return type
    }

    private func visitImpl(function type: FunctionType) -> any SType {
        if let t = visit(function: type) { return t }
        var type = type
        type.params = walk(type.params)
        type.result = walk(type.result)
        return type
    }

    private func visitImpl(genericParam type: GenericParamType) -> any SType {
        if let t = visit(genericParam: type) { return t }
        return type
    }

    private func visitImpl(metatype type: MetatypeType) -> any SType {
        if let t = visit(metatype: type) { return t }
        var type = type
        type.instance = walk(type.instance)
        return type
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
        var type = type
        type.parent = walk(type.parent)
        type.genericArgs = walk(type.genericArgs)
        return type
    }

    private func visitImpl(typeAlias type: TypeAliasType) -> any SType {
        if let t = visit(typeAlias: type) { return t }
        var type = type
        type.parent = walk(type.parent)
        type.genericArgs = walk(type.genericArgs)
        return type
    }
    // @end
}
