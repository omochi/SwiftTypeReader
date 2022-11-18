public final class StructDecl: NominalTypeDecl & DeclContext {
    public init(
        context: some DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.genericParams = .init()
        self.storedProperties = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var name: String
    public var genericParams: GenericParamList
    public var storedProperties: [VarDecl]

    public var declaredInterfaceType: any SType2 {
        StructType2(
            decl: self,
            genericArgs: genericParams.asDeclaredInterfaceTypeArgs()
        )
    }

    public var interfaceType: any SType2 {
        MetatypeType(instance: declaredInterfaceType)
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if let param = genericParams.find(name: name, options: options) {
            return param
        }
        if options.value {
            if let prop = storedProperties.first(where: { $0.name == name }) {
                return prop
            }
        }
        return nil
    }
}
