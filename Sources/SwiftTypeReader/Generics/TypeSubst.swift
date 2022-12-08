extension SType {
    public func subst(map: SubstitutionMap) -> any SType {
        let impl = TypeSubst(map: map)
        return impl.walk(self)
    }
}

private final class TypeSubst: TypeTransformer {
    init(
        map: SubstitutionMap
    ) {
        self.map = map
    }

    var map: SubstitutionMap

    override func visit(genericParam type: GenericParamType) -> (any SType)? {
        guard let rep = map.replacementType(for: type) else {
            return ErrorType(
                repr: type.toTypeRepr(containsModule: false),
                context: type.decl.parentContext
            )
        }
        return rep
    }
}
