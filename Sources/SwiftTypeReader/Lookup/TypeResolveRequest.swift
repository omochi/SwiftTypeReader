struct TypeResolveRequest: Request {
    @AnyDeclContextStorage var context: any DeclContext
    @AnyTypeReprStorage var repr: any TypeRepr

    func evaluate(on evaluator: RequestEvaluator) throws -> any SType {
        return try Impl(
            evaluator: evaluator,
            context: context
        ).resolve(repr: repr)
    }
}

private struct Impl {
    var evaluator: RequestEvaluator
    var context: any DeclContext

    func resolve(repr: any TypeRepr) throws -> any SType {
        switch repr {
        case let repr as IdentTypeRepr:
            return try resolve(ident: repr)
        case let repr as FunctionTypeRepr:
            return resolve(function: repr)
        default:
            throw MessageError("invalid repr: \(repr)")
        }
    }

    private func resolve(ident: IdentTypeRepr) throws -> any SType {
        var type = try resolveHeadType(element: ident.elements[0])

        var index = 1
        while index < ident.elements.count {
            type = try resolveNestedType(parent: type, element: ident.elements[index])
            index += 1
        }

        return type
    }

    private func resolveHeadType(element: IdentTypeRepr.Element) throws -> any SType {
        guard let decl = try evaluator(
            UnqualifiedLookupRequest(
                context: context,
                name: element.name,
                options: LookupOptions(value: false, type: true)
            )
        )?.asType else {
            throw MessageError("not found: \(element.name)")
        }

        let parent = parentType(from: decl)

        return try resolveTypeDecl(decl: decl, parent: parent, element: element)
    }

    private func resolveNestedType(parent: any SType, element: IdentTypeRepr.Element) throws -> any SType {
        let parentContext = try self.context(from: parent)
        guard let decl = parentContext.findType(name: element.name) else {
            throw MessageError("not found: \(element.name)")
        }
        return try resolveTypeDecl(decl: decl, parent: parent, element: element)
    }

    private func parentType(from decl: any TypeDecl) -> (any SType)? {
        guard let parentDecl = decl.parentContext as? any TypeDecl else { return nil }
        return parentDecl.declaredInterfaceType
    }

    private func context(from type: any SType) throws -> any DeclContext {
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
        parent: (any SType)?,
        element: IdentTypeRepr.Element
    ) throws -> any SType {
        var parent = parent
        if parent is ModuleType {
            parent = nil
        }

        let genericArgs = resolveGenericArgs(reprs: element.genericArgs)
        let type = decl.declaredInterfaceType

        switch type {
        case let declType as any NominalType:
            let decl = declType.nominalTypeDecl

            return decl.makeNominalDeclaredInterfaceType(
                parent: parent,
                genericArgs: genericArgs
            )
        case let declType as TypeAliasType:
            let decl = declType.decl

            return decl.makeDeclaredInterfaceType(
                parent: parent,
                genericArgs: genericArgs
            )
        default: break
        }

        return type
    }

    private func resolveGenericArgs(reprs: [any TypeRepr]) -> [any SType] {
        return reprs.map { (repr) in
            repr.resolve(from: self.context)
        }
    }

    private func resolve(function: FunctionTypeRepr) -> FunctionType {
        var attributes: [FunctionAttribute] = []
        if function.hasAsync {
            attributes.append(.async)
        }
        if function.hasThrows {
            attributes.append(.throws)
        }

        let params = function.params.elements.map { (element) -> FunctionType.Param in
            let param = element.resolve(from: context)
            return FunctionType.Param(
                attributes: [],
                type: param
            )
        }

        let result = function.result.resolve(from: context)

        return FunctionType(
            attributes: attributes,
            params: params,
            result: result
        )
    }
}
