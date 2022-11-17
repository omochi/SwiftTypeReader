public struct IdentTypeRepr: TypeRepr {
    public init(
        name: String,
        genericArgs: [AnyTypeRepr]
    ) {
        self.name = name
        self.genericArgs = genericArgs
    }

    public var name: String
    public var genericArgs: [AnyTypeRepr]

    public var description: String {
        var s = name
        if !genericArgs.isEmpty {
            s += "<"
            s += genericArgs.map { $0.description }.joined(separator: ", ")
            s += ">"
        }
        return s
    }

    public func resolve(from context: any DeclContext) -> any SType2 {
        do {
            return try context.rootContext.evaluator(
                ResolveRequest(
                    context: context.asAnyDeclContext(),
                    repr: self
                )
            )
        } catch {
            return UnknownType(repr: self)
        }
    }

    struct ResolveRequest: Request {
        var context: AnyDeclContext
        var repr: IdentTypeRepr

        func evaluate(on evaluator: RequestEvaluator) throws -> any SType2 {
            guard let decl = try evaluator(UnqualifiedLookup(
                context: context,
                name: name,
                options: LookupOptions(value: false, type: true)
            )) as? any ValueDecl else {
                throw MessageError("not found: \(name)")
            }
            return try decl.interfaceType
        }
    }
}
