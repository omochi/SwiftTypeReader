struct TypeResolveRequest: Request {
    @AnyDeclContextStorage var context: any DeclContext
    @AnyTypeReprStorage var repr: any TypeRepr

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType2 {
        return try Evaluate(
            evaluator: evaluator,
            context: context,
            repr: repr
        )()
    }
}

private struct Evaluate {
    var evaluator: RequestEvaluator
    var context: any DeclContext
    var repr: any TypeRepr

    func callAsFunction() throws -> any SType2 {
        switch repr {
        case let repr as IdentTypeRepr:
            return try resolve(repr: repr)
        default:
            throw MessageError("invalid repr: \(repr)")
        }
    }

    private func resolve(repr: IdentTypeRepr) throws -> any SType2 {
        let element = repr.elements[0]
        guard let decl = try evaluator(
            UnqualifiedLookupRequest(
                context: context,
                name: element.name,
                options: LookupOptions(value: false, type: true)
            )
        ) as? any ValueDecl else {
            throw MessageError("not found: \(element.name)")
        }

        var type = decl.interfaceType
        if let decl = decl as? any TypeDecl {
            type = decl.declaredInterfaceType
        }
        let genericArgs = resolveGenericArgs(reprs: element.genericArgs)
        type = try applyGenericArgs(type: type, args: genericArgs)

        if repr.elements.count == 1 {
            return type
        }

        guard let base = decl as? any DeclContext else {
            throw MessageError("invalid base decl: \(decl)")
        }

        return try resolve(
            repr: repr,
            index: 1,
            base: base,
            parent: type
        )
    }

    private func resolve(
        repr: IdentTypeRepr,
        index: Int,
        base: any DeclContext,
        parent: any SType2
    ) throws -> any SType2 {
        let element = repr.elements[index]

        guard let decl = base.findType(
            name: element.name
        ) as? any TypeDecl else {
            throw MessageError("not found: \(element.name)")
        }

        let genericArgs = resolveGenericArgs(reprs: element.genericArgs)

        var type = decl.declaredInterfaceType
        type = setParent(type: type, parent: parent)
        type = try applyGenericArgs(type: type, args: genericArgs)

        if index + 1 == repr.elements.count {
            return type
        }

        guard let base = decl as? any DeclContext else {
            throw MessageError("invalid base decl: \(decl)")
        }

        return try resolve(
            repr: repr,
            index: index + 1,
            base: base,
            parent: type
        )
    }

    private func resolveGenericArgs(reprs: [any TypeRepr]) -> [any SType2] {
        reprs.map { $0.resolve(from: context) }
    }

    private func setParent(type: any SType2, parent: any SType2) -> any SType2 {
        switch type {
        case var type as any NominalType:
            type.parent = parent
            return type
        default: return type
        }
    }

    private func applyGenericArgs(type: any SType2, args: [any SType2]) throws -> any SType2 {
        switch type {
        case var type as any NominalType:
            guard type.nominalTypeDecl.genericParams.items.count == args.count else {
                throw MessageError("mismatch generic arguments")
            }
            type.genericArgs = args
            return type
        default: return type
        }
    }
}
