struct TypeResolveRequest: Request {
    var context: AnyDeclContext
    var repr: AnyTypeRepr

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
    var context: AnyDeclContext
    var repr: AnyTypeRepr

    func callAsFunction() throws -> any SType2 {
        switch repr.value.switcher {
        case .ident(let repr):
            return try resolve(items: [repr])
        case .chained(let repr):
            return try resolve(items: repr.items)
        }
    }

    private func resolve(items: [IdentTypeRepr]) throws -> any SType2 {
        let name = items[0].name
        guard let decl = try evaluator(
            UnqualifiedLookupRequest(
                context: context,
                name: name,
                options: LookupOptions(value: false, type: true)
            )
        ) as? any ValueDecl else {
            throw MessageError("not found: \(name)")
        }
        var type = try decl.interfaceType
        if let decl = decl as? any TypeDecl {
            type = try decl.declaredInterfaceType
        }

        if items.count == 1 {
            return type
        }

        guard let base = decl as? any DeclContext else {
            throw MessageError("invalid base decl: \(decl)")
        }

        return try resolve(
            items: items,
            index: 1,
            base: base
        )
    }

    private func resolve(
        items: [IdentTypeRepr],
        index: Int,
        base: some DeclContext
    ) throws -> any SType2 {
        let name = items[index].name
        guard let decl = try evaluator(
            QualifiedLookupRequest(
                base: base.asAnyDeclContext(),
                name: name,
                options: LookupOptions(value: false, type: true)
            )
        ) as? any TypeDecl else {
            throw MessageError("not found: \(name)")
        }
        let type = try decl.declaredInterfaceType

        if index + 1 == items.count {
            return type
        }

        guard let base = decl as? any DeclContext else {
            throw MessageError("invalid base decl: \(decl)")
        }

        return try resolve(
            items: items,
            index: index + 1,
            base: base
        )
    }
}
