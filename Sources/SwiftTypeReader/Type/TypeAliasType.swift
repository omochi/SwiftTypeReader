public struct TypeAliasType: SType {
    public init(
        decl: TypeAliasDecl,
        parent: (any SType)? = nil,
        genericArgs: [any SType] = []
    ) {
        self.decl = decl
        self.parent = parent
        self.genericArgs = genericArgs
    }

    public var decl: TypeAliasDecl
    @AnyTypeOptionalStorage public var parent: (any SType)?
    @AnyTypeArrayStorage public var genericArgs: [any SType]

    public var name: String {
        decl.name
    }

    public var underlyingType: any SType {
        do {
            return try decl.rootContext.evaluator(
                TypeAliasTypeUnderlyingTypeRequest(type: self)
            )
        } catch {
            return ErrorType(error: error)
        }
    }
}

struct TypeAliasTypeUnderlyingTypeRequest: Request {
    var type: TypeAliasType

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType {
        let map = type.contextSubstitutionMap()
        var under = type.decl.underlyingType
        under = under.subst(map: map)
        return under
    }
}
