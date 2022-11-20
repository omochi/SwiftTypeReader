struct TypeResolveRequest: Request {
    @AnyDeclContextStorage var context: any DeclContext
    @AnyTypeReprStorage var repr: any TypeRepr

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType2 {
        return try Impl(
            evaluator: evaluator,
            context: context
        ).resolve(repr: repr)
    }
}

private struct Impl {
    var evaluator: RequestEvaluator
    var context: any DeclContext

    func resolve(repr: any TypeRepr) throws -> any SType2 {
        switch repr {
        case let repr as IdentTypeRepr:
            return try resolve(repr: repr)
        default:
            throw MessageError("invalid repr: \(repr)")
        }
    }

    private func resolve(repr: IdentTypeRepr) throws -> any SType2 {
        var type = try resolveHeadType(element: repr.elements[0])

        var index = 1
        while index < repr.elements.count {
            type = try resolveNestedType(parent: type, element: repr.elements[index])
            index += 1
        }

        return type
    }

    private func resolveHeadType(element: IdentTypeRepr.Element) throws -> any SType2 {
        guard let decl = try evaluator(
            UnqualifiedLookupRequest(
                context: context,
                name: element.name,
                options: LookupOptions(value: false, type: true)
            )
        ) as? any TypeDecl else {
            throw MessageError("not found: \(element.name)")
        }

        let parent = parentType(from: decl)

        return try resolveTypeDecl(decl: decl, parent: parent, element: element)
    }

    private func resolveNestedType(parent: any SType2, element: IdentTypeRepr.Element) throws -> any SType2 {
        let parentContext = try self.context(from: parent)
        guard let decl = parentContext.findType(name: element.name) else {
            throw MessageError("not found: \(element.name)")
        }
        return try resolveTypeDecl(decl: decl, parent: parent, element: element)
    }

    private func parentType(from decl: any TypeDecl) -> (any SType2)? {
        guard let parentDecl = decl.parentContext as? any TypeDecl else { return nil }
        return parentDecl.declaredInterfaceType
    }

    private func context(from type: any SType2) throws -> any DeclContext {
        switch type {
        case let type as ModuleType:
            return type.decl
        case let type as any NominalType:
            return type.nominalTypeDecl
        default:
            throw MessageError("invalid type: \(type)")
        }
    }

    private func resolveTypeDecl(
        decl: any TypeDecl,
        parent: (any SType2)?,
        element: IdentTypeRepr.Element
    ) throws -> any SType2 {
        var parent = parent
        if parent is ModuleType {
            parent = nil
        }

        let declType = decl.declaredInterfaceType

        switch declType {
        case let declType as any NominalType:
            let decl = declType.nominalTypeDecl
            let genericArgs = resolveGenericArgs(reprs: element.genericArgs)
            return decl.makeNominalDeclaredInterfaceType(
                parent: parent,
                genericArgs: genericArgs
            )
        default: return declType
        }
    }

    private func resolveGenericArgs(reprs: [any TypeRepr]) -> [any SType2] {
        return reprs.map { (repr) in
            repr.resolve(from: self.context)
        }
    }
}
