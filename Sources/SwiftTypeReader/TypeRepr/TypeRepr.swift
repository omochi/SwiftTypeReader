public protocol TypeRepr: Hashable & CustomStringConvertible {
}

extension TypeRepr {
    public func resolve(from context: any DeclContext) -> any SType {
        do {
            return try context.rootContext.evaluator(
                TypeResolveRequest(
                    context: context,
                    repr: self
                )
            )
        } catch {
            return ErrorType(
                repr: self,
                context: context,
                error: error
            )
        }
    }

    // MARK: - cast
    public var asError: ErrorTypeRepr? { self as? ErrorTypeRepr }
    public var asFunction: FunctionTypeRepr? { self as? FunctionTypeRepr }
    public var asIdent: IdentTypeRepr? { self as? IdentTypeRepr }
    public var asMetatype: MetatypeTypeRepr? { self as? MetatypeTypeRepr }
    public var asTuple: TupleTypeRepr? { self as? TupleTypeRepr }
}
