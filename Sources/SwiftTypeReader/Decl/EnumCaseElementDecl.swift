public final class EnumCaseElementDecl: ValueDecl & DeclContext {
    public init(`enum`: EnumDecl, name: String) {
        self.enum = `enum`
        self.name = name
        self.associatedValues = []
    }

    public unowned var `enum`: EnumDecl
    public var parentContext: (any DeclContext)? { `enum` }

    public var name: String
    public var valueName: String? { name }
    public var associatedValues: [ParamDecl]

    public var interfaceType: any SType2 {
        `enum`.declaredInterfaceType
    }

    public func find(name: String, options: LookupOptions) -> (any Decl)? {
        if options.value {
            if let decl = associatedValues.first(where: { $0.name == name }) {
                return decl
            }
        }

        return nil
    }
}
