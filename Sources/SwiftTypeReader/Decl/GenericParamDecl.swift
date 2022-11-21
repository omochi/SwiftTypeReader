public final class GenericParamDecl: TypeDecl {
    public init(
        context: any DeclContext,
        name: String
    ) {
        self.context = context
        self.name = name
        self.inheritedTypeLocs = []
    }

    public unowned var context: any DeclContext
    public var parentContext: (any DeclContext)? { context }
    public var name: String
    public var valueName: String? { name }
    public var inheritedTypeLocs: [TypeLoc]

    public var typedDeclaredInterfaceType: GenericParamType {
        declaredInterfaceType as! GenericParamType
    }
}
