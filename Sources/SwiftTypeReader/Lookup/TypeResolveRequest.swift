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
        switch repr.switcher {
        case .ident(let repr):
            return try resolve(items: [repr])
        case .chained(let repr):
            return try resolve(items: repr.items)
        }
    }

    private func resolve(items: [IdentTypeRepr]) throws -> any SType2 {
        let repr = items[0]
        guard let decl = try evaluator(
            UnqualifiedLookupRequest(
                context: context,
                name: repr.name,
                options: LookupOptions(value: false, type: true)
            )
        ) as? any ValueDecl else {
            throw MessageError("not found: \(repr.name)")
        }

        var type = decl.interfaceType
        if let decl = decl as? any TypeDecl {
            type = decl.declaredInterfaceType
        }

        let genericArgs = resolveGenericArgs(reprs: repr.genericArgs)
        type = applyGenericArgs(type: type, args: genericArgs)

        if items.count == 1 {
            return type
        }

        guard let base = decl as? any DeclContext else {
            throw MessageError("invalid base decl: \(decl)")
        }

        return try resolve(
            items: items,
            index: 1,
            base: base,
            genericArgs: genericArgs
        )
    }

    private func resolve(
        items: [IdentTypeRepr],
        index: Int,
        base: some DeclContext,
        genericArgs: [any SType2]
    ) throws -> any SType2 {
        let repr = items[index]

        guard let decl = base.findType(
            name: repr.name
        ) as? any TypeDecl else {
            throw MessageError("not found: \(repr.name)")
        }
        
        var type = decl.declaredInterfaceType
        let genericArgs = genericArgs + resolveGenericArgs(reprs: repr.genericArgs)
        type = applyGenericArgs(type: type, args: genericArgs)

        if index + 1 == items.count {
            return type
        }

        guard let base = decl as? any DeclContext else {
            throw MessageError("invalid base decl: \(decl)")
        }

        return try resolve(
            items: items,
            index: index + 1,
            base: base,
            genericArgs: genericArgs
        )
    }

    private func resolveGenericArgs(reprs: [any TypeRepr]) -> [any SType2] {
        reprs.map { $0.resolve(from: context) }
    }

    private func applyGenericArgs(type: any SType2, args: [any SType2]) -> any SType2 {
        switch type {
        case var type as any NominalType:
            type.genericArgs = args
            return type
        default: return type
        }
    }
}
