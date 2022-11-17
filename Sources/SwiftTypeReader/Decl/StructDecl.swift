public final class StructDecl: NominalTypeDecl & DeclContext {
    public init(
        context: some DeclContext,
        name: String
    ) {
        self._context = context
        self.name = name
        self.genericParams = .init()
    }

    public unowned var _context: any DeclContext
    public var name: String
    public var context: (any DeclContext)? { _context }
    public var genericParams: GenericParamList

    public var declaredInterfaceType: any SType2 {
        StructType2(decl: self)
    }

    public var interfaceType: any SType2 {
        MetatypeType(instance: declaredInterfaceType)
    }

    public func findOwn(name: String, options: LookupOptions) -> (any Decl)? {
        if let param = genericParams.findOwn(name: name, options: options) {
            return param
        }
        return nil
    }
}
