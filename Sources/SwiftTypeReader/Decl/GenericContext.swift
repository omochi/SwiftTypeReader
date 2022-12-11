public protocol GenericContext: DeclContext {
    var syntaxGenericParams: GenericParamList { get }
}

extension GenericContext {
    public var genericParams: GenericParamList {
        do {
            return try rootContext.evaluator(
                GenericParamsRequest(context: self)
            )
        } catch {
            return GenericParamList()
        }
    }

    public var genericSignature: GenericSignature {
        do {
            return try rootContext.evaluator(
                GenericSignatureRequest(context: self)
            )
        } catch {
            return GenericSignature(params: [])
        }
    }

    public func findInGenericContext(name: String, options: LookupOptions) -> (any Decl)? {
        if let decl = genericParams.find(name: name, options: options) {
            return decl
        }

        return nil
    }
}
